package com.grhmobile.repository;

import java.util.Optional;

import com.grhmobile.entity.ServiceEntity;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ServiceRepository extends JpaRepository<ServiceEntity, Long> {

    Optional<ServiceEntity> findByNomIgnoreCase(String nom);
}
