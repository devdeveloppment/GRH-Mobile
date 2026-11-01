package com.grhmobile.service;

import com.grhmobile.security.QrTokenSigner;
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
    private final QrTokenSigner qrTokenSigner;

    public QrCodeService(
        EmployeQrCodeRepository qrCodeRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService,
        QrTokenSigner qrTokenSigner
    ) {
        this.qrTokenSigner = qrTokenSigner;
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

        return toResponse(qrCode);
    }

    private QrCodeResponse toResponse(EmployeQrCode qrCode) {
        String signed = qrTokenSigner.sign(qrCode.getToken());
        return QrCodeResponse.fromEntity(qrCode, signed, qrTokenSigner.expiresAt(signed));
    }

    @Transactional
    public QrCodeResponse regenerateMyQrCode() {
        var currentUser = authenticatedUserService.currentUser();
        Employe employe = employeeService.findByUserId(currentUser.getId());

        EmployeQrCode qrCode = qrCodeRepository.findByEmployeId(employe.getId())
            .orElseGet(() -> createQrCode(employe));

        qrCode.setToken(UUID.randomUUID().toString());
        qrCode = qrCodeRepository.save(qrCode);

        return toResponse(qrCode);
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
