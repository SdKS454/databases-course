package ru.sdks454.taxservice.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record TaxPaymentView(
        long id,
        BigDecimal expenseAmount,
        BigDecimal taxAmount,
        LocalDateTime createdAt,
        String createdAtText
) {
}
