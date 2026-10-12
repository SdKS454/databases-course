package ru.sdks454.taxservice.config;

import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

public class DatabaseConfig {

    private DatabaseConfig() {
    }

    public static JdbcTemplate getJdbcTemplate() {
        return Holder.JDBC_TEMPLATE;
    }

    private static JdbcTemplate createJdbcTemplate() {
        return new JdbcTemplate(createDataSource());
    }

    private static DataSource createDataSource() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setUrl(requiredConfiguration("DB_URL"));
        dataSource.setUsername(requiredConfiguration("DB_USER"));
        dataSource.setPassword(requiredConfiguration("DB_PASSWORD"));
        return dataSource;
    }

    private static String requiredConfiguration(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            value = System.getProperty(name);
        }
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                    "Configuration is required: " + name
                            + " (set environment variable or JVM system property)");
        }
        return value;
    }

    private static class Holder {
        private static final JdbcTemplate JDBC_TEMPLATE = createJdbcTemplate();
    }
}
