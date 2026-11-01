package com.grhmobile.tenant;

import javax.sql.DataSource;

import org.hibernate.cfg.AvailableSettings;
import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Branche le multi-entreprise (discriminant @TenantId + variable RLS) dans Hibernate. */
@Configuration
public class TenantHibernateConfig {

    @Bean
    HibernatePropertiesCustomizer tenantHibernateCustomizer(DataSource dataSource) {
        return props -> {
            props.put(AvailableSettings.MULTI_TENANT_CONNECTION_PROVIDER, new TenantConnectionProvider(dataSource));
            props.put(AvailableSettings.MULTI_TENANT_IDENTIFIER_RESOLVER, new TenantIdentifierResolver());
        };
    }
}
