package com.grhmobile.tenant;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.hibernate.engine.jdbc.connections.spi.MultiTenantConnectionProvider;

/**
 * Positionne la variable de session PostgreSQL {@code app.entreprise_id} sur chaque connexion
 * remise à Hibernate. Les politiques RLS (migration V32) s'appuient sur cette variable :
 * c'est la seconde barrière d'isolation, indépendante des filtres JPA.
 * La variable est remise à zéro (aucune entreprise) au retour de la connexion dans le pool.
 */
public class TenantConnectionProvider implements MultiTenantConnectionProvider<Long> {

    private final transient DataSource dataSource;

    public TenantConnectionProvider(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Connection getAnyConnection() throws SQLException {
        Connection c = dataSource.getConnection();
        appliquer(c, TenantContext.AUCUNE);
        return c;
    }

    @Override
    public void releaseAnyConnection(Connection connection) throws SQLException {
        reinitialiser(connection);
    }

    @Override
    public Connection getConnection(Long tenantIdentifier) throws SQLException {
        Connection c = dataSource.getConnection();
        appliquer(c, tenantIdentifier != null ? tenantIdentifier : TenantContext.AUCUNE);
        return c;
    }

    @Override
    public void releaseConnection(Long tenantIdentifier, Connection connection) throws SQLException {
        reinitialiser(connection);
    }

    @Override
    public boolean supportsAggressiveRelease() {
        return false;
    }

    @Override
    public boolean isUnwrappableAs(Class<?> unwrapType) {
        return false;
    }

    @Override
    public <T> T unwrap(Class<T> unwrapType) {
        throw new UnsupportedOperationException("Non supporté.");
    }

    private static void appliquer(Connection c, long tenant) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT set_config('app.entreprise_id', ?, false)")) {
            ps.setString(1, Long.toString(tenant));
            ps.execute();
        }
    }

    private static void reinitialiser(Connection c) throws SQLException {
        try {
            appliquer(c, TenantContext.AUCUNE);
        } finally {
            c.close();
        }
    }
}
