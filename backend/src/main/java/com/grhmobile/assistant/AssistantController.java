package com.grhmobile.assistant;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/** Assistant RH (lecture seule). Tout utilisateur connecté ; les droits sont vérifiés par outil. */
@RestController
@RequestMapping("/api/assistant")
public class AssistantController {

    private final AssistantService service;

    public AssistantController(AssistantService service) {
        this.service = service;
    }

    @GetMapping("/statut")
    public Map<String, Object> statut() {
        return service.statut();
    }

    @PostMapping("/questions")
    public Map<String, Object> demander(@RequestBody Map<String, String> body) {
        return service.demander(body.get("question"));
    }

    @PostMapping("/outils/{nom}")
    public Map<String, Object> outil(@PathVariable String nom, @RequestBody(required = false) Map<String, Object> body) {
        return service.outil(nom, body);
    }

    @ExceptionHandler(AssistantIndisponibleException.class)
    public ResponseEntity<Map<String, Object>> indisponible(AssistantIndisponibleException e) {
        return ResponseEntity.status(503).body(Map.of("message", e.getMessage()));
    }
}
