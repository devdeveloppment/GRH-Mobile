package com.grhmobile.security;

import com.grhmobile.repository.PermissionRepository;
import com.grhmobile.repository.DocumentRepository;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;

import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PresenceRepository;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Règles d'accès aux ressources RH, utilisables dans les {@code @PreAuthorize}
 * sous le nom {@code @acl}.
 *
 * <ul>
 *   <li>RH (SUPER_ADMIN, ADMIN, HR_ADMIN, RH_MANAGER) : tous les dossiers ;</li>
 *   <li>PAYROLL_OFFICER : données de paie de tous ;</li>
 *   <li>MANAGER : dossiers de son équipe (sans données salariales) ;</li>
 *   <li>tout employé : son propre dossier.</li>
 * </ul>
 */
@Component("acl")
public class AccessControlService {

    public static final Set<Role> RH_ROLES = EnumSet.of(Role.SUPER_ADMIN, Role.ADMIN, Role.HR_ADMIN, Role.RH_MANAGER);
    public static final Set<Role> PAYROLL_ROLES = EnumSet.of(Role.SUPER_ADMIN, Role.ADMIN, Role.HR_ADMIN, Role.RH_MANAGER, Role.PAYROLL_OFFICER);

    private final EmployeRepository employeRepository;
    private final CongeRepository congeRepository;
    private final FichePaieRepository fichePaieRepository;
    private final PresenceRepository presenceRepository;
    private final DocumentRepository documentRepository;
    private final PermissionRepository permissionRepository;

    public AccessControlService(
        EmployeRepository employeRepository,
        CongeRepository congeRepository,
        FichePaieRepository fichePaieRepository,
        PresenceRepository presenceRepository,
        DocumentRepository documentRepository,
        PermissionRepository permissionRepository
    ) {
        this.permissionRepository = permissionRepository;
        this.documentRepository = documentRepository;
        this.employeRepository = employeRepository;
        this.congeRepository = congeRepository;
        this.fichePaieRepository = fichePaieRepository;
        this.presenceRepository = presenceRepository;
    }

    // ── Utilisateur courant ─────────────────────────────────────────────────────

    public Optional<Utilisateur> currentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal) {
            return Optional.of(principal.getUtilisateur());
        }
        return Optional.empty();
    }

    /**
     * Permission fonctionnelle configurable depuis l'écran « Rôles & permissions ».
     * ADMIN et SUPER_ADMIN disposent toujours de toutes les permissions.
     */
    @Transactional(readOnly = true)
    public boolean can(String code) {
        Utilisateur user = currentUser().orElse(null);
        if (user == null) {
            return false;
        }
        if (user.getRole() == Role.ADMIN || user.getRole() == Role.SUPER_ADMIN) {
            return true;
        }
        return permissionRepository.findByCode(code)
            .map(p -> p.getRoles().contains(user.getRole().name()))
            .orElse(false);
    }

    /** Permissions effectives de l'utilisateur courant. */
    @Transactional(readOnly = true)
    public java.util.List<String> currentPermissions() {
        Utilisateur user = currentUser().orElse(null);
        if (user == null) {
            return java.util.List.of();
        }
        return permissionsOf(user);
    }

    @Transactional(readOnly = true)
    public java.util.List<String> permissionsOf(Utilisateur user) {
        boolean admin = user.getRole() == Role.ADMIN || user.getRole() == Role.SUPER_ADMIN;
        return permissionRepository.findAll().stream()
            .filter(p -> admin || p.getRoles().contains(user.getRole().name()))
            .map(p -> p.getCode())
            .sorted()
            .toList();
    }

    public boolean isRh() {
        return currentUser().map(u -> RH_ROLES.contains(u.getRole())).orElse(false);
    }

    public boolean canSeeSalaries() {
        return currentUser().map(u -> PAYROLL_ROLES.contains(u.getRole())).orElse(false);
    }

    public boolean isManager() {
        return currentUser().map(u -> u.getRole() == Role.MANAGER).orElse(false);
    }

    @Transactional(readOnly = true)
    public Optional<Employe> currentEmploye() {
        return currentUser().flatMap(u -> employeRepository.findByUtilisateurId(u.getId()));
    }

    // ── Règles sur un employé ───────────────────────────────────────────────────

    public boolean isSelf(Employe employe) {
        Utilisateur user = currentUser().orElse(null);
        return user != null && employe.getUtilisateur() != null
            && employe.getUtilisateur().getId().equals(user.getId());
    }

    /** Le manager courant encadre-t-il cet employé (directement ou via son département) ? */
    @Transactional(readOnly = true)
    public boolean isManagerOf(Employe employe) {
        if (!isManager()) {
            return false;
        }
        Employe me = currentEmploye().orElse(null);
        if (me == null || me.getId().equals(employe.getId())) {
            return false;
        }
        if (employe.getManager() != null && employe.getManager().getId().equals(me.getId())) {
            return true;
        }
        return employe.getDepartement() != null
            && employe.getDepartement().getManager() != null
            && employe.getDepartement().getManager().getId().equals(me.getId());
    }

    /** Lecture du dossier (identité, présences, congés, documents, compétences, contrats). */
    @Transactional(readOnly = true)
    public boolean canViewEmployee(String matricule) {
        if (isRh() || canSeeSalaries()) {
            return true;
        }
        return employeRepository.findByMatricule(matricule)
            .map(e -> isSelf(e) || isManagerOf(e))
            .orElse(true); // laisser le contrôleur renvoyer 404
    }

    /** Lecture des données de paie d'un employé. */
    @Transactional(readOnly = true)
    public boolean canViewPayroll(String matricule) {
        if (canSeeSalaries()) {
            return true;
        }
        return employeRepository.findByMatricule(matricule).map(this::isSelf).orElse(true);
    }

    /** Peut-on voir le salaire de cet employé dans sa fiche ? */
    public boolean canSeeSalaryOf(Employe employe) {
        return canSeeSalaries() || isSelf(employe);
    }

    // ── Règles sur les ressources ───────────────────────────────────────────────

    @Transactional(readOnly = true)
    public boolean canViewFichePaie(Long id) {
        if (canSeeSalaries()) {
            return true;
        }
        return fichePaieRepository.findById(id).map(f -> isSelf(f.getEmploye())).orElse(true);
    }

    /** Décision sur un congé : RH ou manager de l'employé, jamais sur sa propre demande. */
    @Transactional(readOnly = true)
    public boolean canDecideConge(Long id) {
        return congeRepository.findById(id)
            .map(c -> !isSelf(c.getEmploye()) && (can("MANAGE_LEAVES") || isManagerOf(c.getEmploye())))
            .orElse(true);
    }

    /** Dépôt de document : RH ou l'employé lui-même. */
    @Transactional(readOnly = true)
    public boolean canUploadDocument(String matricule) {
        if (isRh()) {
            return true;
        }
        return employeRepository.findByMatricule(matricule).map(this::isSelf).orElse(true);
    }

    @Transactional(readOnly = true)
    public boolean canViewDocument(Long id) {
        return documentRepository.findById(id)
            .map(d -> canViewEmployee(d.getEmploye().getMatricule()))
            .orElse(true);
    }

    /** Justification d'absence : uniquement par l'employé concerné ou les RH. */
    @Transactional(readOnly = true)
    public boolean canJustifyPresence(Long id) {
        if (isRh()) {
            return true;
        }
        return presenceRepository.findById(id).map(p -> isSelf(p.getEmploye())).orElse(true);
    }
}
