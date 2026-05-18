package com.grhmobile.service;

import com.grhmobile.dto.qrcode.QrCodeResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.EmployeQrCode;
import com.grhmobile.repository.EmployeQrCodeRepository;
import com.grhmobile.security.AuthenticatedUserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class QrCodeService {

    private final EmployeQrCodeRepository qrCodeRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;

    public QrCodeService(
        EmployeQrCodeRepository qrCodeRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService
    ) {
        this.qrCodeRepository = qrCodeRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
    }

    @Transactional
    public QrCodeResponse getOrCreateMyQrCode() {
        var currentUser = authenticatedUserService.currentUser();
        Employe employe = employeeService.findByUserId(currentUser.getId());

        EmployeQrCode qrCode = qrCodeRepository.findByEmployeId(employe.getId())
            .orElseGet(() -> createQrCode(employe));

        return QrCodeResponse.fromEntity(qrCode);
    }

    @Transactional
    public QrCodeResponse regenerateMyQrCode() {
        var currentUser = authenticatedUserService.currentUser();
        Employe employe = employeeService.findByUserId(currentUser.getId());

        EmployeQrCode qrCode = qrCodeRepository.findByEmployeId(employe.getId())
            .orElseGet(() -> createQrCode(employe));

        qrCode.setToken(UUID.randomUUID().toString());
        qrCode = qrCodeRepository.save(qrCode);

        return QrCodeResponse.fromEntity(qrCode);
    }

    // Appelé à la création d'un employé ou au premier accès
    @Transactional
    public EmployeQrCode getOrCreateForEmploye(Employe employe) {
        return qrCodeRepository.findByEmployeId(employe.getId())
            .orElseGet(() -> createQrCode(employe));
    }

    private EmployeQrCode createQrCode(Employe employe) {
        EmployeQrCode qr = new EmployeQrCode();
        qr.setEmploye(employe);
        qr.setToken(UUID.randomUUID().toString());
        return qrCodeRepository.save(qr);
    }
}
