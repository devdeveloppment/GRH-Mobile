package com.grhmobile.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Permission;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.DocumentRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PermissionRepository;
import com.grhmobile.repository.PresenceRepository;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

/** Règles d'accès aux données RH (sans base de données). */
class AccessControlServiceTest {

    private EmployeRepository employeRepository;
    private CongeRepository congeRepository;
    private FichePaieRepository fichePaieRepository;
    private PermissionRepository permissionRepository;
    private AccessControlService acl;

    private Utilisateur employeeUser;
    private Utilisateur managerUser;
    private Utilisateur rhUser;
    private Employe employe;
    private Employe collegue;
    private Employe manager;

    @BeforeEach
    void setUp() {
        employeRepository = mock(EmployeRepository.class);
        congeRepository = mock(CongeRepository.class);
        fichePaieRepository = mock(FichePaieRepository.class);
        permissionRepository = mock(PermissionRepository.class);
        acl = new AccessControlService(employeRepository, congeRepository, fichePaieRepository,
            mock(PresenceRepository.class), mock(DocumentRepository.class), permissionRepository);

        employeeUser = user(1L, Role.EMPLOYEE);
        managerUser = user(2L, Role.MANAGER);
        rhUser = user(3L, Role.RH_MANAGER);

        manager = employe(20L, "MGR-1", managerUser, null);
        employe = employe(10L, "EMP-1", employeeUser, manager);
        collegue = employe(11L, "EMP-2", null, null);

        when(employeRepository.findByMatricule("EMP-1")).thenReturn(Optional.of(employe));
        when(employeRepository.findByMatricule("EMP-2")).thenReturn(Optional.of(collegue));
        when(employeRepository.findByUtilisateurId(1L)).thenReturn(Optional.of(employe));
        when(employeRepository.findByUtilisateurId(2L)).thenReturn(Optional.of(manager));
    }

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void unEmployeVoitSonDossierMaisPasCeluiDUnCollegue() {
        login(employeeUser);
        assertThat(acl.canViewEmployee("EMP-1")).isTrue();
        assertThat(acl.canViewEmployee("EMP-2")).isFalse();
        assertThat(acl.canViewPayroll("EMP-2")).isFalse();
    }

    @Test
    void unManagerVoitSonEquipeSansAccesALaPaie() {
        login(managerUser);
        assertThat(acl.canViewEmployee("EMP-1")).isTrue();
        assertThat(acl.canViewEmployee("EMP-2")).isFalse();
        assertThat(acl.canViewPayroll("EMP-1")).isFalse();
        assertThat(acl.canSeeSalaryOf(employe)).isFalse();
    }

    @Test
    void lesRhVoientToutLeMonde() {
        login(rhUser);
        assertThat(acl.canViewEmployee("EMP-2")).isTrue();
        assertThat(acl.canViewPayroll("EMP-2")).isTrue();
    }

    @Test
    void unBulletinNEstVisibleQueParSonTitulaire() {
        FichePaie fiche = new FichePaie();
        fiche.setEmploye(collegue);
        when(fichePaieRepository.findById(5L)).thenReturn(Optional.of(fiche));
        login(employeeUser);
        assertThat(acl.canViewFichePaie(5L)).isFalse();

        fiche.setEmploye(employe);
        assertThat(acl.canViewFichePaie(5L)).isTrue();
    }

    @Test
    void personneNApprouveSaPropreDemandeDeConge() {
        Conge conge = new Conge();
        conge.setEmploye(employe);
        when(congeRepository.findById(7L)).thenReturn(Optional.of(conge));

        login(employeeUser);
        assertThat(acl.canDecideConge(7L)).isFalse();

        login(managerUser);
        assertThat(acl.canDecideConge(7L)).isTrue();
    }

    @Test
    void lesRhDecidentSelonLaPermissionManageLeaves() {
        Conge conge = new Conge();
        conge.setEmploye(collegue);
        when(congeRepository.findById(8L)).thenReturn(Optional.of(conge));
        Permission permission = new Permission();
        permission.setCode("MANAGE_LEAVES");
        permission.setRoles(new java.util.ArrayList<>(List.of("RH_MANAGER")));
        when(permissionRepository.findByCode("MANAGE_LEAVES")).thenReturn(Optional.of(permission));

        login(rhUser);
        assertThat(acl.canDecideConge(8L)).isTrue();

        permission.setRoles(new java.util.ArrayList<>());
        assertThat(acl.canDecideConge(8L)).isFalse();
    }

    @Test
    void lAdministrateurDisposeDeToutesLesPermissions() {
        login(user(9L, Role.ADMIN));
        assertThat(acl.can("MANAGE_PAIE")).isTrue();
    }

    // ── utilitaires ──────────────────────────────────────────────────────────

    private static Utilisateur user(Long id, Role role) {
        Utilisateur u = new Utilisateur();
        ReflectionTestUtils.setField(u, "id", id);
        u.setRole(role);
        u.setEmail(role.name().toLowerCase() + "@test.local");
        return u;
    }

    private static Employe employe(Long id, String matricule, Utilisateur user, Employe manager) {
        Employe e = new Employe();
        ReflectionTestUtils.setField(e, "id", id);
        e.setMatricule(matricule);
        e.setUtilisateur(user);
        e.setManager(manager);
        return e;
    }

    private static void login(Utilisateur user) {
        UserPrincipal principal = new UserPrincipal(user);
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }
}
