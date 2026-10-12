package ru.sdks454.taxservice.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import ru.sdks454.taxservice.model.TaxPayment;
import ru.sdks454.taxservice.model.TaxPaymentView;
import ru.sdks454.taxservice.model.TaxRateResponse;

public interface TaxPaymentService {

    List<TaxPayment> list(long userId);

    TaxPayment create(long userId, BigDecimal expenseAmount);

    Optional<TaxPayment> update(long userId, long id, BigDecimal expenseAmount);

    List<TaxPaymentView> listWithTax(long userId);

    List<TaxPaymentView> listWithTax(long userId, TaxRateResponse taxRate);
}
