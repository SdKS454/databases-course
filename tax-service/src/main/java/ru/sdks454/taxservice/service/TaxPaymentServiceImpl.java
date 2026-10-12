package ru.sdks454.taxservice.service;

import ru.sdks454.taxservice.client.TaxRateClient;
import ru.sdks454.taxservice.model.TaxPayment;
import ru.sdks454.taxservice.model.TaxPaymentView;
import ru.sdks454.taxservice.model.TaxRateResponse;
import ru.sdks454.taxservice.repository.TaxPaymentRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

public class TaxPaymentServiceImpl implements TaxPaymentService {

    private final TaxPaymentRepository taxPaymentRepository;
    private final TaxRateClient taxRateClient;
    private static final DateTimeFormatter DATE_TIME_FORMATTER =
            DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");

    public TaxPaymentServiceImpl(TaxPaymentRepository taxPaymentRepository, TaxRateClient taxRateClient) {
        this.taxPaymentRepository = taxPaymentRepository;
        this.taxRateClient = taxRateClient;
    }

    @Override
    public List<TaxPayment> list(long userId) {
        return taxPaymentRepository.findAll(userId);
    }

    @Override
    public TaxPayment create(long userId, BigDecimal expenseAmount) {
        return taxPaymentRepository.save(userId, expenseAmount);
    }

    @Override
    public Optional<TaxPayment> update(long userId, long id, BigDecimal expenseAmount) {
        return taxPaymentRepository.updateExpenseAmount(userId, id, expenseAmount);
    }

    @Override
    public List<TaxPaymentView> listWithTax(long userId) {
        return listWithTax(userId, taxRateClient.getCurrentRate());
    }

    @Override
    public List<TaxPaymentView> listWithTax(long userId, TaxRateResponse taxRate) {
        BigDecimal percent = taxRate.percent();
        BigDecimal multiplier = percent.divide(BigDecimal.valueOf(100));

        return taxPaymentRepository.findAll(userId).stream()
                .map(payment -> new TaxPaymentView(
                        payment.id(),
                        payment.expenseAmount(),
                        payment.expenseAmount()
                                .multiply(multiplier)
                                .setScale(2, RoundingMode.HALF_UP),
                        payment.createdAt(),
                        payment.createdAt().format(DATE_TIME_FORMATTER)
                ))
                .toList();
    }
}
