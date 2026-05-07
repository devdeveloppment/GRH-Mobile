package com.grhmobile.controller;

import java.util.List;
import java.util.Map;

import com.grhmobile.dto.permission.PermissionDto;
import com.grhmobile.dto.permission.UpdateRolesRequest;
import com.grhmobile.entity.Permission;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.PermissionRepository;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/permissions")
public class PermissionController {

    private final PermissionRepository permissionRepository;

    public PermissionController(PermissionRepository permissionRepository) {
        this.permissionRepository = permissionRepository;
    }

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping
    public Map<String, Object> list() {
        List<PermissionDto> items = permissionRepository.findAll()
            .stream()
            .map(PermissionDto::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{code}/roles")
    @Transactional
    public PermissionDto updateRoles(
            @PathVariable String code,
            @RequestBody UpdateRolesRequest request) {
        Permission permission = permissionRepository.findByCode(code)
            .orElseThrow(() -> new ResourceNotFoundException("Permission introuvable : " + code));
        permission.getRoles().clear();
        if (request.roles() != null) {
            permission.getRoles().addAll(request.roles());
        }
        permissionRepository.save(permission);
        return PermissionDto.fromEntity(permission);
    }
}
