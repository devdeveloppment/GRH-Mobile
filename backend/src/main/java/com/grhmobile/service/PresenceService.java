package com.grhmobile.service;

import java.util.List;
import java.util.Map;

import com.grhmobile.dto.presence.PresenceResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Presence;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PresenceService {

    private final PresenceRepository presenceRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;

    public PresenceService(
        PresenceRepository presenceRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService
    ) {
        this.presenceRepository = presenceRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
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
}
