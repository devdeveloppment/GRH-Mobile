package com.grhmobile.service;

import com.grhmobile.dto.poste.PosteRequest;
import com.grhmobile.dto.poste.PosteResponse;
import com.grhmobile.entity.Poste;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.PosteRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PosteService {

    private final PosteRepository posteRepository;
    private final DepartementService departementService;

    public PosteService(PosteRepository posteRepository, DepartementService departementService) {
        this.posteRepository = posteRepository;
        this.departementService = departementService;
    }

    @Transactional(readOnly = true)
    public List<PosteResponse> listAll() {
        return posteRepository.findByActifTrue()
            .stream()
            .map(PosteResponse::fromEntity)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<PosteResponse> listByDepartement(Long departementId) {
        return posteRepository.findByDepartementIdAndActifTrue(departementId)
            .stream()
            .map(PosteResponse::fromEntity)
            .toList();
    }

    @Transactional(readOnly = true)
    public PosteResponse getById(Long id) {
        return PosteResponse.fromEntity(findById(id));
    }

    @Transactional
    public PosteResponse create(PosteRequest request) {
        if (posteRepository.existsByCodeIgnoreCase(request.code())) {
            throw new BusinessException("Un poste avec ce code existe déjà.");
        }
        Poste poste = new Poste();
        applyRequest(poste, request);
        return PosteResponse.fromEntity(posteRepository.save(poste));
    }

    @Transactional
    public PosteResponse update(Long id, PosteRequest request) {
        Poste poste = findById(id);
        if (!poste.getCode().equalsIgnoreCase(request.code())
                && posteRepository.existsByCodeIgnoreCase(request.code())) {
            throw new BusinessException("Un poste avec ce code existe déjà.");
        }
        applyRequest(poste, request);
        return PosteResponse.fromEntity(posteRepository.save(poste));
    }

    @Transactional
    public void desactiver(Long id) {
        Poste poste = findById(id);
        poste.setActif(false);
        posteRepository.save(poste);
    }

    private void applyRequest(Poste poste, PosteRequest request) {
        poste.setCode(request.code().trim().toUpperCase());
        poste.setIntitule(request.intitule().trim());
        poste.setNiveau(request.niveau());
        poste.setSalaireMin(request.salaireMin());
        poste.setSalaireMax(request.salaireMax());
        poste.setDescription(request.description());
        Long deptId = request.departementId();
        poste.setDepartement(deptId != null ? departementService.findById(deptId) : null);
    }

    public Poste findById(Long id) {
        return posteRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Poste introuvable."));
    }
}
