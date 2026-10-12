package ru.sdks454.taxservice.repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import ru.sdks454.taxservice.model.TaxPayment;

public interface TaxPaymentRepository {

    TaxPayment save(long userId, BigDecimal expenseAmount);

    List<TaxPayment> findAll(long userId);

    Optional<TaxPayment> findById(long userId, long id);

    Optional<TaxPayment> updateExpenseAmount(long userId, long id, BigDecimal expenseAmount);
}
