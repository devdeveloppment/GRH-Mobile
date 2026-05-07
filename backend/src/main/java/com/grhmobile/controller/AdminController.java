package com.grhmobile.controller;

import com.grhmobile.dto.admin.UserDto;
import com.grhmobile.entity.AppSetting;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.AppSettingRepository;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.repository.UtilisateurRepository;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final UtilisateurRepository utilisateurRepository;
    private final EmployeRepository employeRepository;
    private final CongeRepository congeRepository;
    private final PresenceRepository presenceRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppSettingRepository appSettingRepository;

    public AdminController(
        UtilisateurRepository utilisateurRepository,
        EmployeRepository employeRepository,
        CongeRepository congeRepository,
        PresenceRepository presenceRepository,
        PasswordEncoder passwordEncoder,
        AppSettingRepository appSettingRepository
    ) {
        this.utilisateurRepository = utilisateurRepository;
        this.employeRepository = employeRepository;
        this.congeRepository = congeRepository;
        this.presenceRepository = presenceRepository;
        this.passwordEncoder = passwordEncoder;
        this.appSettingRepository = appSettingRepository;
    }

    // ── Utilisateurs ───────────────────────────────────────────────────────────

    @GetMapping("/users")
    public Map<String, Object> listUsers(@RequestParam(required = false) String query) {
        List<Utilisateur> users = utilisateurRepository.findAll();
        List<UserDto> items = users.stream()
                .filter(u -> query == null || query.isBlank() ||
                        (u.getNom() + " " + u.getPrenom()).toLowerCase().contains(query.toLowerCase()) ||
                        u.getEmail().toLowerCase().contains(query.toLowerCase()))
                .map(UserDto::fromEntity)
                .toList();
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping("/users")
    @ResponseStatus(HttpStatus.CREATED)
    public UserDto createUser(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "").trim();
        String fullName = body.getOrDefault("fullName", "").trim();
        String roleStr = body.getOrDefault("role", "EMPLOYEE").trim().toUpperCase();
        String password = body.getOrDefault("password", "ChangeMe@123").trim();

        if (email.isBlank()) {
            throw new IllegalArgumentException("L'email est obligatoire.");
        }
        if (utilisateurRepository.findByEmailIgnoreCase(email).isPresent()) {
            throw new IllegalArgumentException("Un utilisateur avec cet email existe déjà.");
        }

        String[] parts = fullName.split(" ", 2);
        String prenom = parts.length > 0 ? parts[0].trim() : "";
        String nom = parts.length > 1 ? parts[1].trim() : prenom;

        Utilisateur user = new Utilisateur();
        user.setPrenom(prenom);
        user.setNom(nom);
        user.setEmail(email);
        user.setRole(Role.valueOf(roleStr));
        user.setMotDePasse(passwordEncoder.encode(password.isBlank() ? "ChangeMe@123" : password));
        user.setActif(true);
        return UserDto.fromEntity(utilisateurRepository.save(user));
    }

    @PutMapping("/users/{id}")
    public UserDto updateUser(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));

        if (body.containsKey("fullName")) {
            String fullName = body.get("fullName").trim();
            String[] parts = fullName.split(" ", 2);
            user.setPrenom(parts[0].trim());
            user.setNom(parts.length > 1 ? parts[1].trim() : parts[0].trim());
        }
        if (body.containsKey("email")) {
            user.setEmail(body.get("email").trim());
        }
        if (body.containsKey("role")) {
            user.setRole(Role.valueOf(body.get("role").trim().toUpperCase()));
        }
        return UserDto.fromEntity(utilisateurRepository.save(user));
    }

    @GetMapping("/roles/stats")
    public Map<String, Long> roleStats() {
        List<Utilisateur> all = utilisateurRepository.findAll();
        Map<String, Long> stats = new java.util.LinkedHashMap<>();
        for (Role role : Role.values()) {
            stats.put(role.name(), all.stream().filter(u -> u.getRole() == role && u.isActif()).count());
        }
        return stats;
    }

    @PutMapping("/users/{id}/role")
    public UserDto changeRole(@PathVariable Long id, @RequestBody Map<String, @NotBlank String> body) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        user.setRole(Role.valueOf(body.get("role").toUpperCase()));
        return UserDto.fromEntity(utilisateurRepository.save(user));
    }

    @PutMapping("/users/{id}/toggle")
    public UserDto toggleUser(@PathVariable Long id) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        user.setActif(!user.isActif());
        return UserDto.fromEntity(utilisateurRepository.save(user));
    }

    @DeleteMapping("/users/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long id) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        user.setActif(false);
        utilisateurRepository.save(user);
    }

    // ── Statistiques système ──────────────────────────────────────────────────

    @GetMapping("/stats")
    public Map<String, Object> systemStats() {
        long activeUsers = utilisateurRepository.findAll().stream()
                .filter(Utilisateur::isActif).count();
        long totalEmployees = employeRepository.findAll().stream()
                .filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut())).count();
        long pendingLeaves = congeRepository.countByStatut(StatutConge.EN_ATTENTE);
        long presentToday = presenceRepository.countByDate(LocalDate.now());
        long totalActive = employeRepository.findAll().stream()
                .filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut())).count();
        long attendanceRate = totalActive > 0 ? (presentToday * 100 / totalActive) : 0;

        return Map.of(
            "activeUsers", activeUsers,
            "totalEmployees", totalEmployees,
            "pendingLeaves", pendingLeaves,
            "attendanceRate", attendanceRate
        );
    }

    // ── Paramètres système ─────────────────────────────────────────────────────

    @GetMapping("/settings")
    public Map<String, Object> getSettings() {
        Map<String, Boolean> result = new java.util.HashMap<>();
        appSettingRepository.findAll().forEach(s -> result.put(s.getKey(), s.isEnabled()));
        return Map.of("settings", result);
    }

    @PutMapping("/settings")
    public Map<String, Object> updateSettings(@RequestBody Map<String, Object> body) {
        body.forEach((key, val) -> {
            String strVal = String.valueOf(val);
            AppSetting setting = appSettingRepository.findByKey(key)
                    .orElseGet(() -> { AppSetting s = new AppSetting(); s.setKey(key); return s; });
            setting.setValue(strVal);
            appSettingRepository.save(setting);
        });
        return Map.of("success", true);
    }
}
