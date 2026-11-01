package com.grhmobile.service;

import java.util.Map;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.dto.employee.EmployeeRequest;
import com.grhmobile.dto.employee.EmployeeResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.ServiceEntity;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Genre;
import com.grhmobile.enums.Role;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.enums.TypeContrat;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.repository.ServiceRepository;
import com.grhmobile.repository.UtilisateurRepository;

import com.grhmobile.audit.Auditable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.grhmobile.repository.DepartementRepository;
import com.grhmobile.repository.PosteRepository;
import com.grhmobile.security.AccessControlService;
import com.grhmobile.util.PasswordGenerator;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmployeeService {

    private final EmployeRepository employeRepository;
    private final ServiceRepository serviceRepository;
    private final PresenceRepository presenceRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;
    private final PosteRepository posteRepository;
    private final DepartementRepository departementRepository;
    private final AccessControlService acl;

    public EmployeeService(
            EmployeRepository employeRepository,
            ServiceRepository serviceRepository,
            PresenceRepository presenceRepository,
            UtilisateurRepository utilisateurRepository,
            PasswordEncoder passwordEncoder,
            PosteRepository posteRepository,
            DepartementRepository departementRepository,
            AccessControlService acl) {
        this.posteRepository = posteRepository;
        this.departementRepository = departementRepository;
        this.acl = acl;
        this.employeRepository = employeRepository;
        this.serviceRepository = serviceRepository;
        this.presenceRepository = presenceRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public PagedResponse<EmployeeResponse> search(String query, String statut, String service, int page, int limit) {
        Page<Employe> result = employeRepository.search(
                toLikePattern(query),
                normalize(statut),
                normalize(service),
                PageRequest.of(Math.max(page - 1, 0), limit,
                        Sort.by("nom").ascending().and(Sort.by("prenom").ascending())));

        List<EmployeeResponse> items = result.getContent()
                .stream()
                .map(this::toResponse)
                .toList();

        return new PagedResponse<>(items, result.getTotalElements(), page, limit);
    }

    @Transactional(readOnly = true)
    public EmployeeResponse getByMatricule(String matricule) {
        return toResponse(findByMatricule(matricule));
    }

    @Transactional(readOnly = true)
    public EmployeeResponse getByUserId(Long userId) {
        return toResponse(findByUserId(userId));
    }

    @Auditable(action = "CREATE_EMPLOYEE", entite = "Employe")
    @Transactional
    public EmployeeResponse create(EmployeeRequest request) {
        if (utilisateurRepository.findByEmailIgnoreCase(request.email()).isPresent()) {
            throw new BusinessException("Un utilisateur avec cet email existe déjà.");
        }

        ServiceEntity service = findOrCreateService(request.service());

        Employe employe = new Employe();
        applyRequest(employe, request, service);
        employe.setMatricule(generateMatricule(request.prenom(), request.nom()));

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(request.nom());
        utilisateur.setPrenom(request.prenom());
        utilisateur.setEmail(request.email());
        String temporaryPassword = PasswordGenerator.temporaryPassword();
        utilisateur.setMotDePasse(passwordEncoder.encode(temporaryPassword));
        utilisateur.setDoitChangerMotDePasse(true);
        utilisateur.setRole(Role.EMPLOYEE);
        utilisateur.setActif(true);
        utilisateurRepository.save(utilisateur);

        employe.setUtilisateur(utilisateur);
        employeRepository.save(employe);
        return EmployeeResponse.fromEntity(employe, false, true, temporaryPassword);
    }

    @Auditable(action = "UPDATE_EMPLOYEE", entite = "Employe")
    @Transactional
    public EmployeeResponse update(String matricule, EmployeeRequest request) {
        Employe employe = findByMatricule(matricule);
        utilisateurRepository.findByEmailIgnoreCase(request.email().trim())
                .filter(other -> employe.getUtilisateur() == null || !other.getId().equals(employe.getUtilisateur().getId()))
                .ifPresent(other -> { throw new BusinessException("Un utilisateur avec cet email existe déjà."); });
        ServiceEntity service = findOrCreateService(request.service());
        applyRequest(employe, request, service);
        employeRepository.save(employe);

        Utilisateur utilisateur = employe.getUtilisateur();
        if (utilisateur != null) {
            utilisateur.setNom(request.nom());
            utilisateur.setPrenom(request.prenom());
            utilisateur.setEmail(request.email());
            utilisateurRepository.save(utilisateur);
        }
        return toResponse(employe);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> annuaire() {
        return employeRepository.findAllByStatutIgnoreCase("ACTIF").stream()
                .sorted(java.util.Comparator.comparing(Employe::getNom, String.CASE_INSENSITIVE_ORDER))
                .map(e -> {
                    Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("matricule", e.getMatricule());
                    m.put("nom", e.getNom());
                    m.put("prenom", e.getPrenom());
                    m.put("poste", e.getPoste());
                    m.put("service", e.getService() != null ? e.getService().getNom() : null);
                    m.put("email", e.getEmail());
                    m.put("telephone", e.getTelephone());
                    m.put("photoUrl", e.getPhotoUrl());
                    m.put("statut", e.getStatut());
                    return m;
                })
                .toList();
    }

    /** Équipe du manager connecté. */
    @Transactional(readOnly = true)
    public List<EmployeeResponse> listMyTeam() {
        Employe me = acl.currentEmploye()
                .orElseThrow(() -> new ResourceNotFoundException("Employé associé introuvable."));
        return employeRepository.findTeam(me.getId()).stream().map(this::toResponse).toList();
    }

    @Auditable(action = "ARCHIVE_EMPLOYEE", entite = "Employe")
    @Transactional
    public void archive(String matricule) {
        Employe employe = findByMatricule(matricule);
        employe.setStatut("ARCHIVE");
        if (employe.getUtilisateur() != null) {
            employe.getUtilisateur().setActif(false);
        }
        employeRepository.save(employe);
    }

    @Transactional(readOnly = true)
    public Employe findById(Long id) {
        return employeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employé introuvable."));
    }

    @Transactional(readOnly = true)
    public Employe findByMatricule(String matricule) {
        return employeRepository.findByMatricule(matricule)
                .orElseThrow(() -> new ResourceNotFoundException("Employé introuvable."));
    }

    @Transactional(readOnly = true)
    public Employe findByUserId(Long userId) {
        return employeRepository.findByUtilisateurId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Employé associé introuvable."));
    }

    private void applyRequest(Employe employe, EmployeeRequest request, ServiceEntity service) {
        employe.setNom(request.nom().trim());
        employe.setPrenom(request.prenom().trim());
        employe.setDateNaissance(request.dateNaissance());
        employe.setGenre(request.genre() != null && !request.genre().isBlank()
                ? Genre.valueOf(request.genre().trim().toUpperCase())
                : null);
        employe.setNationalite(request.nationalite());
        employe.setEmail(request.email().trim());
        employe.setTelephone(request.telephone());
        employe.setStatut(request.statut() == null || request.statut().isBlank() ? "ACTIF"
                : request.statut().trim().toUpperCase());
        employe.setDateEmbauche(request.dateEmbauche() != null ? request.dateEmbauche() : LocalDate.now());
        employe.setPoste(request.poste().trim());
        employe.setService(service);
        employe.setTypeContrat(TypeContrat.valueOf(request.typeContrat().trim().toUpperCase()));
        employe.setAdresse(request.adresse());
        employe.setDateFinContrat(request.dateFin());
        employe.setPhotoUrl(request.photoUrl());
        employe.setSalaireBrutBase(request.salaire());

        // Rattachement au référentiel organisationnel (facultatif)
        if (request.posteId() != null) {
            var poste = posteRepository.findById(request.posteId())
                    .orElseThrow(() -> new ResourceNotFoundException("Poste introuvable."));
            employe.setPosteRef(poste);
            employe.setPoste(poste.getIntitule());
        } else {
            employe.setPosteRef(null);
        }
        if (request.departementId() != null) {
            employe.setDepartement(departementRepository.findById(request.departementId())
                    .orElseThrow(() -> new ResourceNotFoundException("Département introuvable.")));
        } else {
            employe.setDepartement(null);
        }
        if (request.managerMatricule() != null && !request.managerMatricule().isBlank()) {
            Employe manager = findByMatricule(request.managerMatricule().trim());
            if (manager.getId() != null && manager.getId().equals(employe.getId())) {
                throw new BusinessException("Un employé ne peut pas être son propre manager.");
            }
            employe.setManager(manager);
        } else {
            employe.setManager(null);
        }
    }

    private EmployeeResponse toResponse(Employe employe) {
        boolean present = presenceRepository.existsByEmployeIdAndDateAndStatut(
                employe.getId(),
                LocalDate.now(),
                StatutPresence.PRESENT);
        return EmployeeResponse.fromEntity(employe, present, acl.canSeeSalaryOf(employe), null);
    }

    private ServiceEntity findOrCreateService(String serviceName) {
        return serviceRepository.findByNomIgnoreCase(serviceName)
                .orElseGet(() -> {
                    ServiceEntity service = new ServiceEntity();
                    service.setNom(serviceName.trim());
                    service.setDescription("Service " + serviceName.trim());
                    service.setResponsable("À affecter");
                    return serviceRepository.save(service);
                });
    }

    private String generateMatricule(String prenom, String nom) {
        String prefix = (prenom.substring(0, Math.min(prenom.length(), 1))
                + nom.substring(0, Math.min(nom.length(), 2)))
                .toUpperCase();
        String date = DateTimeFormatter.ofPattern("yyMMdd").format(LocalDate.now());
        long sequence = employeRepository.nextMatriculeSequence();
        return "GRH-%s-%s-%03d".formatted(prefix, date, sequence);
    }

    private String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private String toLikePattern(String query) {
        if (query == null || query.isBlank()) {
            return null;
        }
        return "%" + query.trim().toLowerCase() + "%";
    }
}
