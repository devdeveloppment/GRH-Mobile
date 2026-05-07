package com.grhmobile.service;

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
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.repository.ServiceRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmployeeService {

    private final EmployeRepository employeRepository;
    private final ServiceRepository serviceRepository;
    private final PresenceRepository presenceRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;

    public EmployeeService(
        EmployeRepository employeRepository,
        ServiceRepository serviceRepository,
        PresenceRepository presenceRepository,
        UtilisateurRepository utilisateurRepository,
        PasswordEncoder passwordEncoder
    ) {
        this.employeRepository = employeRepository;
        this.serviceRepository = serviceRepository;
        this.presenceRepository = presenceRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public PagedResponse<EmployeeResponse> search(String query, String statut, String service, int page, int limit) {
        Page<Employe> result = employeRepository.search(
            normalize(query),
            normalize(statut),
            normalize(service),
            PageRequest.of(Math.max(page - 1, 0), limit, Sort.by("nom").ascending().and(Sort.by("prenom").ascending()))
        );

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

    @Transactional
    public EmployeeResponse create(EmployeeRequest request) {
        ServiceEntity service = findOrCreateService(request.service());

        Employe employe = new Employe();
        applyRequest(employe, request, service);
        employe.setMatricule(generateMatricule(request.prenom(), request.nom()));

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setNom(request.nom());
        utilisateur.setPrenom(request.prenom());
        utilisateur.setEmail(request.email());
        utilisateur.setMotDePasse(passwordEncoder.encode("ChangeMe@123"));
        utilisateur.setRole(Role.EMPLOYEE);
        utilisateurRepository.save(utilisateur);

        employe.setUtilisateur(utilisateur);
        employeRepository.save(employe);
        return toResponse(employe);
    }

    @Transactional
    public EmployeeResponse update(String matricule, EmployeeRequest request) {
        Employe employe = findByMatricule(matricule);
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
        employe.setGenre(request.genre() != null && !request.genre().isBlank() ? Genre.valueOf(request.genre().trim().toUpperCase()) : null);
        employe.setNationalite(request.nationalite());
        employe.setEmail(request.email().trim());
        employe.setTelephone(request.telephone());
        employe.setStatut(request.statut() == null || request.statut().isBlank() ? "ACTIF" : request.statut().trim().toUpperCase());
        employe.setDateEmbauche(request.dateEmbauche() != null ? request.dateEmbauche() : LocalDate.now());
        employe.setPoste(request.poste().trim());
        employe.setService(service);
        employe.setTypeContrat(TypeContrat.valueOf(request.typeContrat().trim().toUpperCase()));
        employe.setAdresse(request.adresse());
        employe.setDateFinContrat(request.dateFin());
        employe.setPhotoUrl(request.photoUrl());
        employe.setSalaireBrutBase(request.salaire());
    }

    private EmployeeResponse toResponse(Employe employe) {
        boolean present = presenceRepository.existsByEmployeIdAndDateAndStatut(
            employe.getId(),
            LocalDate.now(),
            StatutPresence.PRESENT
        );
        return EmployeeResponse.fromEntity(employe, present);
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
        String prefix = (prenom.substring(0, Math.min(prenom.length(), 1)) + nom.substring(0, Math.min(nom.length(), 2)))
            .toUpperCase();
        String date = DateTimeFormatter.ofPattern("yyMMdd").format(LocalDate.now());
        long count = employeRepository.count() + 1;
        return "GRH-%s-%s-%03d".formatted(prefix, date, count);
    }

    private String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
