package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.service.PresenceService;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/presences")
public class PresenceController {

    private final PresenceService presenceService;

    public PresenceController(PresenceService presenceService) {
        this.presenceService = presenceService;
    }

    @GetMapping
    public Map<String, Object> list() {
        return presenceService.listAll();
    }

    @GetMapping("/me")
    public Map<String, Object> listMine() {
        return presenceService.listMine();
    }
}
