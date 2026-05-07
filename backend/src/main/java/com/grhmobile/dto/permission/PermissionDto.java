package com.grhmobile.dto.permission;

import java.util.List;

import com.grhmobile.entity.Permission;

public record PermissionDto(
    Long id,
    String code,
    String description,
    List<String> roles
) {
    public static PermissionDto fromEntity(Permission p) {
        return new PermissionDto(p.getId(), p.getCode(), p.getDescription(), p.getRoles());
    }
}
