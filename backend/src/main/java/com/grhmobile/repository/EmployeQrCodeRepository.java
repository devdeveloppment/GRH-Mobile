package com.grhmobile.repository;

import com.grhmobile.entity.EmployeQrCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface EmployeQrCodeRepository extends JpaRepository<EmployeQrCode, Long> {

    Optional<EmployeQrCode> findByEmployeId(Long employeId);

    Optional<EmployeQrCode> findByToken(String token);
}
