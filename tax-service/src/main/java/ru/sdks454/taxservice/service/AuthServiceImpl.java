package ru.sdks454.taxservice.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Optional;
import java.util.regex.Pattern;

import ru.sdks454.taxservice.model.User;
import ru.sdks454.taxservice.repository.UserRepository;

public class AuthServiceImpl implements AuthService {

    private static final Pattern CYRILLIC_NAME = Pattern.compile("[А-Яа-яЁё]+");
    private static final Pattern LOGIN = Pattern.compile("[A-Za-z0-9_.-]{3,40}");

    private final UserRepository userRepository;

    public AuthServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public User register(String login, String firstName, String lastName,
                         String patronymic, String password) {
        validate(login, firstName, lastName, patronymic, password);
        if (userRepository.findByLogin(login.trim()).isPresent()) {
            throw new IllegalArgumentException("Пользователь с таким логином уже существует.");
        }
        return userRepository.save(login.trim(), firstName.trim(), lastName.trim(),
                patronymic.trim(), hashPassword(password));
    }

    @Override
    public Optional<User> authenticate(String login, String password) {
        if (login == null || password == null || login.isBlank() || password.isBlank()) {
            return Optional.empty();
        }
        return userRepository.findByLogin(login.trim())
                .filter(user -> hashPassword(password).equals(findPasswordHash(user.login())));
    }

    private String findPasswordHash(String login) {
        return userRepository.findPasswordHash(login);
    }

    private void validate(String login, String firstName, String lastName,
                          String patronymic, String password) {
        if (login == null || !LOGIN.matcher(login.trim()).matches()) {
            throw new IllegalArgumentException("Логин: 3–40 латинских букв, цифр, ., _ или -.");
        }
        if (!validName(firstName) || !validName(lastName) || !validName(patronymic)) {
            throw new IllegalArgumentException("ФИО должны содержать только русские буквы.");
        }
        if (password == null || password.length() < 4) {
            throw new IllegalArgumentException("Пароль должен содержать минимум 4 символа.");
        }
    }

    private boolean validName(String value) {
        return value != null && CYRILLIC_NAME.matcher(value.trim()).matches();
    }

    private String hashPassword(String password) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256")
                            .digest(password.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
