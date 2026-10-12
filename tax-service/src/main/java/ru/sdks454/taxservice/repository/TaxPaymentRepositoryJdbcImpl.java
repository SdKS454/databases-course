package ru.sdks454.taxservice.repository;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;

import ru.sdks454.taxservice.model.TaxPayment;

public class TaxPaymentRepositoryJdbcImpl implements TaxPaymentRepository {

    private static final String INSERT_SQL = """
            INSERT INTO tax_payment (id, user_id, expense_amount, created_at)
            VALUES (nextval('tax_payment_id_seq'), ?, ?, CURRENT_TIMESTAMP)
            RETURNING id, expense_amount, created_at
            """;

    private static final String FIND_ALL_SQL = """
            SELECT id, expense_amount, created_at
            FROM tax_payment
            WHERE user_id = ?
            ORDER BY created_at DESC, id DESC
            """;

    private static final String FIND_BY_ID_SQL = """
            SELECT id, expense_amount, created_at
            FROM tax_payment
            WHERE user_id = ? AND id = ?
            """;

    private static final String UPDATE_EXPENSE_AMOUNT_SQL = """
            UPDATE tax_payment
            SET expense_amount = ?
            WHERE user_id = ? AND id = ?
            RETURNING id, expense_amount, created_at
            """;

    private final JdbcTemplate jdbcTemplate;

    public TaxPaymentRepositoryJdbcImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public TaxPayment save(long userId, BigDecimal expenseAmount) {
        return jdbcTemplate.queryForObject(
                INSERT_SQL,
                (resultSet, rowNumber) -> mapRow(resultSet.getLong("id"),
                        resultSet.getBigDecimal("expense_amount"),
                        resultSet.getTimestamp("created_at")),
                userId, expenseAmount
        );
    }

    @Override
    public List<TaxPayment> findAll(long userId) {
        return jdbcTemplate.query(FIND_ALL_SQL, (resultSet, rowNumber) ->
                mapRow(resultSet.getLong("id"),
                        resultSet.getBigDecimal("expense_amount"),
                        resultSet.getTimestamp("created_at")),
                userId);
    }

    @Override
    public Optional<TaxPayment> findById(long userId, long id) {
        List<TaxPayment> payments = jdbcTemplate.query(
                FIND_BY_ID_SQL,
                (resultSet, rowNumber) -> mapRow(resultSet.getLong("id"),
                        resultSet.getBigDecimal("expense_amount"),
                        resultSet.getTimestamp("created_at")),
                userId, id
        );
        return payments.stream().findFirst();
    }

    @Override
    public Optional<TaxPayment> updateExpenseAmount(long userId, long id, BigDecimal expenseAmount) {
        List<TaxPayment> updatedPayments = jdbcTemplate.query(
                UPDATE_EXPENSE_AMOUNT_SQL,
                (resultSet, rowNumber) -> mapRow(resultSet.getLong("id"),
                        resultSet.getBigDecimal("expense_amount"),
                        resultSet.getTimestamp("created_at")),
                expenseAmount, userId, id
        );
        return updatedPayments.stream().findFirst();
    }

    private TaxPayment mapRow(long id, BigDecimal expenseAmount, Timestamp createdAt) {
        return new TaxPayment(id, expenseAmount, createdAt.toLocalDateTime());
    }
}
