package com.grhmobile.service;

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

    private final PresenceRepository presenceRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;
    private final EmployeQrCodeRepository qrCodeRepository;
    private final NotificationService notificationService;

    public PresenceService(
        PresenceRepository presenceRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService,
        EmployeQrCodeRepository qrCodeRepository,
        NotificationService notificationService
    ) {
        this.presenceRepository = presenceRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
        this.qrCodeRepository = qrCodeRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listAll() {
        List<PresenceResponse> items = presenceRepository.findTop50ByOrderByDateDesc()
            .stream()
            .map(PresenceResponse::fromEntity)
            .toList();
        return Map.of("items", items);
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
            presence.setHeureArrivee(now);
        } else if ("SORTIE".equalsIgnoreCase(request.type())) {
            presence.setHeureDepart(now);
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
        // Valider le token QR
        EmployeQrCode qrCode = qrCodeRepository.findByToken(request.token())
            .orElseThrow(() -> new IllegalArgumentException("QR Code invalide ou expiré."));

        Employe employe = qrCode.getEmploye();
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
            .orElseThrow(() -> new IllegalArgumentException("Absence non trouvée"));

        // Vérifier que c'est bien une absence en attente
        if (presence.getStatut() != StatutPresence.ABSENT_EN_ATTENTE) {
            throw new IllegalArgumentException("Cette absence ne peut pas être justifiée");
        }

        // Mettre à jour la justification
        presence.setJustification(request.justification());
        presence.setStatut(StatutPresence.ABSENT_JUSTIFIEE);

        // Sauvegarder la pièce jointe si présente
        if (request.pieceJointe() != null && !request.pieceJointe().isBlank()) {
            try {
                presence.setPieceJointe(Base64.getDecoder().decode(request.pieceJointe()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Pièce jointe invalide (base64 invalide)");
            }
        }

        // Sauvegarder
        presence = presenceRepository.save(presence);

        return JustifyAbsenceResponse.fromEntity(presence);
    }
}
