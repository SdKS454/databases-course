package ru.sdks454.taxservice.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record TaxPayment(
        long id,
        BigDecimal expenseAmount,
        LocalDateTime createdAt
) {
}
