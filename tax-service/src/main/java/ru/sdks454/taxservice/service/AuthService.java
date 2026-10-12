package ru.sdks454.taxservice.service;

import java.util.Optional;

import ru.sdks454.taxservice.model.User;

public interface AuthService {

    User register(String login, String firstName, String lastName,
                  String patronymic, String password);

    Optional<User> authenticate(String login, String password);
}
