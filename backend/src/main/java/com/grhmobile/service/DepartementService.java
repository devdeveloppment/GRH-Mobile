package com.grhmobile.service;

import com.grhmobile.dto.departement.DepartementRequest;
import com.grhmobile.dto.departement.DepartementResponse;
import com.grhmobile.entity.Departement;
import com.grhmobile.entity.Employe;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.DepartementRepository;
import com.grhmobile.repository.EmployeRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DepartementService {

    private final DepartementRepository departementRepository;
    private final EmployeRepository employeRepository;

    public DepartementService(DepartementRepository departementRepository,
                              EmployeRepository employeRepository) {
        this.departementRepository = departementRepository;
        this.employeRepository = employeRepository;
    }

    @Transactional(readOnly = true)
    public List<DepartementResponse> listAll() {
        return departementRepository.findByActifTrue()
            .stream()
            .map(DepartementResponse::fromEntity)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<DepartementResponse> organigramme() {
        return departementRepository.findRootsWithChildren()
            .stream()
            .map(d -> DepartementResponse.fromEntity(d, true))
            .toList();
    }

    @Transactional(readOnly = true)
    public DepartementResponse getById(Long id) {
        return DepartementResponse.fromEntity(findById(id));
    }

    @Transactional
    public DepartementResponse create(DepartementRequest request) {
        if (departementRepository.existsByCodeIgnoreCase(request.code())) {
            throw new BusinessException("Un département avec ce code existe déjà.");
        }
        Departement dept = new Departement();
        applyRequest(dept, request);
        return DepartementResponse.fromEntity(departementRepository.save(dept));
    }

    @Transactional
    public DepartementResponse update(Long id, DepartementRequest request) {
        Departement dept = findById(id);
        if (!dept.getCode().equalsIgnoreCase(request.code())
                && departementRepository.existsByCodeIgnoreCase(request.code())) {
            throw new BusinessException("Un département avec ce code existe déjà.");
        }
        applyRequest(dept, request);
        return DepartementResponse.fromEntity(departementRepository.save(dept));
    }

    @Transactional
    public void desactiver(Long id) {
        Departement dept = findById(id);
        dept.setActif(false);
        departementRepository.save(dept);
    }

    private void applyRequest(Departement dept, DepartementRequest request) {
        dept.setCode(request.code().trim().toUpperCase());
        dept.setNom(request.nom().trim());
        dept.setDescription(request.description());

        dept.setParent(request.parentId() != null
            ? departementRepository.findById(request.parentId())
                .orElseThrow(() -> new ResourceNotFoundException("Département parent introuvable."))
            : null);

        if (request.managerId() != null) {
            Employe manager = employeRepository.findById(request.managerId())
                .orElseThrow(() -> new ResourceNotFoundException("Manager introuvable."));
            dept.setManager(manager);
        } else {
            dept.setManager(null);
        }
    }

    public Departement findById(Long id) {
        return departementRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Département introuvable."));
    }
}
