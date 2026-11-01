package com.grhmobile.assistant;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** L'assistant n'est pas configuré (aucune clé de fournisseur d'IA). */
@ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
public class AssistantIndisponibleException extends RuntimeException {
    public AssistantIndisponibleException() {
        super("Assistant non configuré : aucune clé de fournisseur d'IA n'est définie.");
    }
}
