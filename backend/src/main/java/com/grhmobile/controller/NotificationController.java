package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.security.AuthenticatedUserService;
import com.grhmobile.service.NotificationService;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final AuthenticatedUserService authenticatedUserService;

    public NotificationController(
            NotificationService notificationService,
            AuthenticatedUserService authenticatedUserService) {
        this.notificationService = notificationService;
        this.authenticatedUserService = authenticatedUserService;
    }

    @GetMapping
    public Map<String, Object> list() {
        Long userId = authenticatedUserService.currentUser().getId();
        return notificationService.getForUser(userId);
    }

    @PutMapping("/{id}/read")
    public Map<String, Object> markRead(@PathVariable Long id) {
        Long userId = authenticatedUserService.currentUser().getId();
        notificationService.markRead(id, userId);
        return Map.of("id", id, "lu", true);
    }

    @PutMapping("/read-all")
    public Map<String, Object> markAllRead() {
        Long userId = authenticatedUserService.currentUser().getId();
        notificationService.markAllRead(userId);
        return Map.of("success", true);
    }
}
