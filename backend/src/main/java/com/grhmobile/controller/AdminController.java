package com.grhmobile.controller;

import com.grhmobile.dto.admin.UserDto;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.UtilisateurRepository;

import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final UtilisateurRepository utilisateurRepository;

    public AdminController(UtilisateurRepository utilisateurRepository) {
        this.utilisateurRepository = utilisateurRepository;
    }

    @GetMapping("/users")
    public Map<String, Object> listUsers(
            @RequestParam(required = false) String query) {
        List<Utilisateur> users = utilisateurRepository.findAll();
        List<UserDto> items = users.stream()
                .filter(u -> query == null || query.isBlank() ||
                        (u.getNom() + " " + u.getPrenom()).toLowerCase().contains(query.toLowerCase()) ||
                        u.getEmail().toLowerCase().contains(query.toLowerCase()))
                .map(UserDto::fromEntity)
                .toList();
        return Map.of("items", items, "total", items.size());
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
        String roleStr = body.get("role");
        user.setRole(Role.valueOf(roleStr.toUpperCase()));
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
}
