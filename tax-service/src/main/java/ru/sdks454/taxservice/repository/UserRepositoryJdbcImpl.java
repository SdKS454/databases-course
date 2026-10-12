package ru.sdks454.taxservice.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;

import ru.sdks454.taxservice.model.User;

public class UserRepositoryJdbcImpl implements UserRepository {

    private static final String FIND_BY_LOGIN_SQL = """
            SELECT id, login, first_name, last_name, patronymic
            FROM app_user
            WHERE login = ?
            """;

    private static final String INSERT_SQL = """
            INSERT INTO app_user (login, first_name, last_name, patronymic, password_hash)
            VALUES (?, ?, ?, ?, ?)
            RETURNING id, login, first_name, last_name, patronymic
            """;

    private final JdbcTemplate jdbcTemplate;

    public UserRepositoryJdbcImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<User> findByLogin(String login) {
        List<User> users = jdbcTemplate.query(FIND_BY_LOGIN_SQL, (rs, rowNum) ->
                new User(rs.getLong("id"), rs.getString("login"),
                        rs.getString("first_name"), rs.getString("last_name"),
                        rs.getString("patronymic")), login);
        return users.stream().findFirst();
    }

    @Override
    public String findPasswordHash(String login) {
        List<String> hashes = jdbcTemplate.query(
                "SELECT password_hash FROM app_user WHERE login = ?",
                (rs, rowNum) -> rs.getString("password_hash"), login);
        return hashes.stream().findFirst().orElse("");
    }

    @Override
    public User save(String login, String firstName, String lastName,
                     String patronymic, String passwordHash) {
        return jdbcTemplate.queryForObject(INSERT_SQL, (rs, rowNum) ->
                new User(rs.getLong("id"), rs.getString("login"),
                        rs.getString("first_name"), rs.getString("last_name"),
                        rs.getString("patronymic")),
                login, firstName, lastName, patronymic, passwordHash);
    }
}
