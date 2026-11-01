package com.grhmobile.tenant;

import org.hibernate.context.spi.CurrentTenantIdentifierResolver;

/** Fournit à Hibernate l'entreprise courante (filtre automatique des entités @TenantId). */
public class TenantIdentifierResolver implements CurrentTenantIdentifierResolver<Long> {

    @Override
    public Long resolveCurrentTenantIdentifier() {
        Long id = TenantContext.get();
        return id != null ? id : TenantContext.AUCUNE;
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return true;
    }

    @Override
    public boolean isRoot(Long tenantId) {
        return tenantId != null && tenantId == TenantContext.ROOT;
    }
}
