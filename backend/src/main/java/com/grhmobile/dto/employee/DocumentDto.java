package com.grhmobile.dto.employee;

import com.grhmobile.entity.Document;
import java.time.OffsetDateTime;

public record DocumentDto(
    Long id,
    String nom,
    String type,
    int tailleKo,
    String url,
    OffsetDateTime date
) {
    public static DocumentDto fromEntity(Document d) {
        // L'URL renvoyée est celle du téléchargement sécurisé, jamais le chemin de stockage
        return new DocumentDto(d.getId(), d.getNom(), d.getType(), d.getTailleKo(),
            "/documents/" + d.getId() + "/download", d.getCreatedAt());
    }
}
