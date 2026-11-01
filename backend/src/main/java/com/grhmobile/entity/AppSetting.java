package com.grhmobile.entity;

import org.hibernate.annotations.TenantId;

import jakarta.persistence.*;

@Entity
@Table(name = "app_settings")
public class AppSetting {

    /** Entreprise propriétaire (multi-entreprise) : renseignée et filtrée automatiquement par Hibernate. */
    @TenantId
    @Column(name = "entreprise_id", nullable = false, updatable = false)
    private Long entrepriseId;

    public Long getEntrepriseId() {
        return entrepriseId;
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String key;

    @Column(nullable = false, length = 500)
    private String value;

    public Long getId() { return id; }

    public String getKey() { return key; }
    public void setKey(String key) { this.key = key; }

    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }

    public boolean isEnabled() { return "true".equalsIgnoreCase(value); }
}
