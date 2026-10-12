package ru.sdks454.taxservice.model;

public record User(
        long id,
        String login,
        String firstName,
        String lastName,
        String patronymic
) {
}
