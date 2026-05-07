package com.grhmobile.repository;

import java.util.Optional;

import com.grhmobile.entity.Permission;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PermissionRepository extends JpaRepository<Permission, Long> {

    Optional<Permission> findByCode(String code);
}
