package com.grhmobile.controller;

import com.grhmobile.dto.service.ServiceDto;
import com.grhmobile.dto.service.ServiceRequest;
import com.grhmobile.entity.ServiceEntity;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.ServiceRepository;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/services")
public class ServiceController {

    private final ServiceRepository serviceRepository;
    private final EmployeRepository employeRepository;

    public ServiceController(ServiceRepository serviceRepository, EmployeRepository employeRepository) {
        this.serviceRepository = serviceRepository;
        this.employeRepository = employeRepository;
    }

    @GetMapping
    public Map<String, Object> list() {
        List<ServiceDto> items = serviceRepository.findAll().stream()
                .filter(ServiceEntity::isActif)
                .map(s -> ServiceDto.fromEntity(s, countEmployes(s)))
                .toList();
        return Map.of("items", items);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN', 'RH_MANAGER')")
    public ServiceDto create(@Valid @RequestBody ServiceRequest request) {
        ServiceEntity service = new ServiceEntity();
        service.setNom(request.nom().trim());
        service.setDescription(request.description().trim());
        service.setResponsable(request.responsable().trim());
        ServiceEntity saved = serviceRepository.save(service);
        return ServiceDto.fromEntity(saved, 0L);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'RH_MANAGER')")
    public ServiceDto update(@PathVariable Long id, @Valid @RequestBody ServiceRequest request) {
        ServiceEntity service = find(id);
        service.setNom(request.nom().trim());
        service.setDescription(request.description().trim());
        service.setResponsable(request.responsable().trim());
        ServiceEntity saved = serviceRepository.save(service);
        return ServiceDto.fromEntity(saved, countEmployes(saved));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasRole('ADMIN')")
    public void delete(@PathVariable Long id) {
        ServiceEntity service = find(id);
        service.setActif(false);
        serviceRepository.save(service);
    }

    private ServiceEntity find(Long id) {
        return serviceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Service introuvable."));
    }

    private long countEmployes(ServiceEntity service) {
        return employeRepository.findAll().stream()
                .filter(e -> service.equals(e.getService()) && "ACTIF".equalsIgnoreCase(e.getStatut()))
                .count();
    }
}
