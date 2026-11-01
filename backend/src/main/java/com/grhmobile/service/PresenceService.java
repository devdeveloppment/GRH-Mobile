package com.grhmobile.service;

import com.grhmobile.security.QrTokenSigner;
import com.grhmobile.security.AccessControlService;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.exception.BusinessException;
import java.util.stream.Collectors;
import java.util.Set;
import java.util.Comparator;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Map;

import com.grhmobile.dto.presence.JustifyAbsenceRequest;
import com.grhmobile.dto.presence.JustifyAbsenceResponse;
import com.grhmobile.dto.presence.PointageRequest;
import com.grhmobile.dto.presence.PointageResponse;
import com.grhmobile.dto.presence.PresenceResponse;
import com.grhmobile.dto.presence.ReportAbsenceRequest;
import com.grhmobile.dto.presence.ReportAbsenceResponse;
import com.grhmobile.dto.qrcode.QrScanRequest;
import com.grhmobile.dto.qrcode.QrScanResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.EmployeQrCode;
import com.grhmobile.entity.Presence;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.repository.EmployeQrCodeRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PresenceService {

    private static final int MAX_ATTACHMENT_BYTES = 5 * 1024 * 1024;

    private final PresenceRepository presenceRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;
    private final EmployeQrCodeRepository qrCodeRepository;
    private final NotificationService notificationService;
    private final QrTokenSigner qrTokenSigner;
    private final AccessControlService acl;
    private final EmployeRepository employeRepository;

    public PresenceService(
        PresenceRepository presenceRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService,
        EmployeQrCodeRepository qrCodeRepository,
        NotificationService notificationService,
        QrTokenSigner qrTokenSigner,
        AccessControlService acl,
        EmployeRepository employeRepository
    ) {
        this.qrTokenSigner = qrTokenSigner;
        this.acl = acl;
        this.employeRepository = employeRepository;
        this.presenceRepository = presenceRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
        this.qrCodeRepository = qrCodeRepository;
        this.notificationService = notificationService;
    }

    /**
     * Présences sur une période (30 derniers jours par défaut), filtrables par statut.
     * Un manager ne voit que son équipe.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> listAll(LocalDate debut, LocalDate fin, String statut) {
        LocalDate to = fin != null ? fin : LocalDate.now();
        LocalDate from = debut != null ? debut : to.minusDays(30);
        if (from.isAfter(to)) {
            throw new BusinessException("La date de début doit précéder la date de fin.");
        }
        StatutPresence filtre = null;
        if (statut != null && !statut.isBlank()) {
            try {
                filtre = StatutPresence.valueOf(statut.trim().toUpperCase());
            } catch (IllegalArgumentException exception) {
                throw new BusinessException("Statut de présence inconnu : " + statut);
            }
        }
        List<Presence> source = presenceRepository.findByDateBetweenOrderByDateAsc(from, to);
        if (acl.isManager()) {
            Employe me = acl.currentEmploye()
                .orElseThrow(() -> new BusinessException("Employé associé introuvable."));
            Set<Long> team = employeRepository.findTeam(me.getId()).stream()
                .map(Employe::getId)
                .collect(Collectors.toSet());
            source = source.stream().filter(p -> team.contains(p.getEmploye().getId())).toList();
        }
        final StatutPresence statutFiltre = filtre;
        List<PresenceResponse> items = source.stream()
            .filter(p -> statutFiltre == null || p.getStatut() == statutFiltre)
            .sorted(Comparator.comparing(Presence::getDate).reversed())
            .map(PresenceResponse::fromEntity)
            .toList();
        return Map.of("items", items, "debut", from.toString(), "fin", to.toString());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listMine() {
        Employe employe = employeeService.findByUserId(authenticatedUserService.currentUser().getId());
        List<PresenceResponse> items = presenceRepository.findByEmployeIdOrderByDateDesc(employe.getId())
            .stream()
            .map(PresenceResponse::fromEntity)
            .toList();
        return Map.of("items", items);
    }

    @Transactional(readOnly = true)
    public List<PresenceResponse> listByMatricule(String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return presenceRepository.findByEmployeIdOrderByDateDesc(employe.getId())
            .stream()
            .map(PresenceResponse::fromEntity)
            .toList();
    }

    @Transactional
    public PointageResponse pointage(PointageRequest request) {
        // Récupérer l'utilisateur connecté
        var currentUser = authenticatedUserService.currentUser();
        
        // Récupérer l'employé associé
        Employe employe = employeeService.findByUserId(currentUser.getId());
        
        // Chercher ou créer un enregistrement Presence pour aujourd'hui
        LocalDate today = LocalDate.now();
        Presence presence = presenceRepository
            .findByEmployeIdAndDate(employe.getId(), today)
            .orElseGet(() -> {
                Presence newPresence = new Presence();
                newPresence.setEmploye(employe);
                newPresence.setDate(today);
                newPresence.setStatut(StatutPresence.PRESENT);
                return newPresence;
            });

        // Mettre à jour en fonction du type de pointage
        LocalDateTime now = LocalDateTime.now();
        if ("ENTREE".equalsIgnoreCase(request.type())) {
            if (presence.getHeureArrivee() != null) {
                throw new BusinessException("Votre arrivée a déjà été enregistrée aujourd'hui.");
            }
            presence.setHeureArrivee(now);
            presence.setStatut(StatutPresence.PRESENT);
        } else if ("SORTIE".equalsIgnoreCase(request.type())) {
            if (presence.getHeureArrivee() == null) {
                throw new BusinessException("Enregistrez d'abord votre arrivée.");
            }
            if (presence.getHeureDepart() != null) {
                throw new BusinessException("Votre départ a déjà été enregistré aujourd'hui.");
            }
            presence.setHeureDepart(now);
        } else {
            throw new BusinessException("Type de pointage inconnu : utilisez ENTREE ou SORTIE.");
        }

        // Sauvegarder la localisation
        presence.setLatitude(request.latitude());
        presence.setLongitude(request.longitude());

        // Sauvegarder
        presence = presenceRepository.save(presence);

        return PointageResponse.success(presence.getId(), request.type(), now);
    }

    @Transactional
    public ReportAbsenceResponse reportAbsence(ReportAbsenceRequest request) {
        // Récupérer l'utilisateur connecté
        var currentUser = authenticatedUserService.currentUser();
        
        // Récupérer l'employé associé
        Employe employe = employeeService.findByUserId(currentUser.getId());

        // Chercher ou créer un enregistrement Presence pour cette date
        Presence presence = presenceRepository
            .findByEmployeIdAndDate(employe.getId(), request.date())
            .orElseGet(() -> {
                Presence newPresence = new Presence();
                newPresence.setEmploye(employe);
                newPresence.setDate(request.date());
                return newPresence;
            });

        // Mettre à jour le statut et le motif
        presence.setStatut(StatutPresence.ABSENT_EN_ATTENTE);
        presence.setMotifAbsence(request.motif());

        // Sauvegarder
        presence = presenceRepository.save(presence);

        return ReportAbsenceResponse.fromEntity(presence);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listAbsencesEnAttente() {
        // Récupérer l'utilisateur connecté
        var currentUser = authenticatedUserService.currentUser();
        
        // Récupérer l'employé associé
        Employe employe = employeeService.findByUserId(currentUser.getId());

        // Récupérer les absences en attente
        List<PresenceResponse> items = presenceRepository
            .findByEmployeIdAndStatutOrderByDateDesc(employe.getId(), StatutPresence.ABSENT_EN_ATTENTE)
            .stream()
            .map(PresenceResponse::fromEntity)
            .toList();

        return Map.of("items", items);
    }

    @Transactional
    public QrScanResponse scanPointage(QrScanRequest request) {
        // Valider le jeton QR dynamique (signature + fraîcheur)
        String baseToken = qrTokenSigner.verify(request.token())
            .orElseThrow(() -> new BusinessException("QR Code invalide ou expiré. Demandez à l'employé d'actualiser son QR code."));
        EmployeQrCode qrCode = qrCodeRepository.findByToken(baseToken)
            .orElseThrow(() -> new BusinessException("QR Code invalide ou expiré."));

        Employe employe = qrCode.getEmploye();
        if (acl.isSelf(employe)) {
            throw new BusinessException("Vous ne pouvez pas scanner votre propre QR code.");
        }
        LocalDate today = LocalDate.now();

        Presence presence = presenceRepository
            .findByEmployeIdAndDate(employe.getId(), today)
            .orElseGet(() -> {
                Presence p = new Presence();
                p.setEmploye(employe);
                p.setDate(today);
                p.setStatut(StatutPresence.PRESENT);
                return p;
            });

        // Anti-double scan : 60 secondes minimum entre deux scans
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime lastScan = presence.getHeureDepart() != null
            ? presence.getHeureDepart()
            : presence.getHeureArrivee();
        if (lastScan != null && Duration.between(lastScan, now).getSeconds() < 60) {
            throw new IllegalArgumentException("Scan trop rapide. Veuillez patienter quelques secondes.");
        }

        String type;
        if (presence.getHeureArrivee() == null) {
            presence.setHeureArrivee(now);
            type = "ENTREE";
        } else if (presence.getHeureDepart() == null) {
            presence.setHeureDepart(now);
            type = "SORTIE";
        } else {
            throw new IllegalArgumentException("La présence est déjà complète pour aujourd'hui.");
        }

        presenceRepository.save(presence);

        // Notifier l'employé de son pointage
        if (employe.getUtilisateur() != null) {
            String heureFormatee = now.toLocalTime().withSecond(0).withNano(0).toString();
            String msgType = "ENTREE".equals(type) ? "entrée" : "sortie";
            notificationService.create(
                employe.getUtilisateur().getId(),
                "Pointage enregistré",
                "Votre pointage " + msgType + " a été enregistré à " + heureFormatee + ".",
                "PRESENCE",
                "/employee/home"
            );
        }

        String nomComplet = employe.getPrenom() + " " + employe.getNom();
        return QrScanResponse.ok(nomComplet, employe.getMatricule(), type, now);
    }

    @Transactional
    public JustifyAbsenceResponse justifyAbsence(Long presenceId, JustifyAbsenceRequest request) {
        // Récupérer l'enregistrement Presence
        Presence presence = presenceRepository.findById(presenceId)
            .orElseThrow(() -> new ResourceNotFoundException("Absence non trouvée"));

        // Vérifier que c'est bien une absence en attente
        if (presence.getStatut() != StatutPresence.ABSENT_EN_ATTENTE) {
            throw new IllegalArgumentException("Cette absence ne peut pas être justifiée");
        }

        // Mettre à jour la justification
        presence.setJustification(request.justification());
        presence.setStatut(StatutPresence.ABSENT_JUSTIFIEE);

        // Sauvegarder la pièce jointe si présente
        if (request.pieceJointe() != null && !request.pieceJointe().isBlank()) {
            byte[] content;
            try {
                content = Base64.getDecoder().decode(request.pieceJointe());
            } catch (IllegalArgumentException e) {
                throw new BusinessException("Pièce jointe invalide (base64 invalide)");
            }
            if (content.length > MAX_ATTACHMENT_BYTES) {
                throw new BusinessException("La pièce jointe ne doit pas dépasser 5 Mo.");
            }
            presence.setPieceJointe(content);
        }

        // Sauvegarder
        presence = presenceRepository.save(presence);

        return JustifyAbsenceResponse.fromEntity(presence);
    }
}
