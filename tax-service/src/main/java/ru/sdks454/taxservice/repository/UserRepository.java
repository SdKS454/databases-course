package ru.sdks454.taxservice.repository;

import java.util.Optional;

import ru.sdks454.taxservice.model.User;

public interface UserRepository {

    Optional<User> findByLogin(String login);

    String findPasswordHash(String login);

    User save(String login, String firstName, String lastName, String patronymic, String passwordHash);
}
