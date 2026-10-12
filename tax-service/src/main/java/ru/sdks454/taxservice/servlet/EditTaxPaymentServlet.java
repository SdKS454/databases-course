package ru.sdks454.taxservice.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Optional;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.dao.DataAccessException;

import ru.sdks454.taxservice.config.DatabaseConfig;
import ru.sdks454.taxservice.model.TaxPayment;
import ru.sdks454.taxservice.repository.TaxPaymentRepositoryJdbcImpl;
import ru.sdks454.taxservice.service.TaxPaymentService;
import ru.sdks454.taxservice.service.TaxPaymentServiceImpl;
import ru.sdks454.taxservice.client.TaxRateClientHttpImpl;
import ru.sdks454.taxservice.filter.AuthFilter;
import ru.sdks454.taxservice.model.User;

@WebServlet("/tax-payments/edit")
public class EditTaxPaymentServlet extends HttpServlet {

    private static final String VIEW = "/jsp/edit-tax-payment.jsp";
    private static final String ERROR_ATTRIBUTE = "error";
    private static final String FORM_EXPENSE_ATTRIBUTE = "formExpenseAmount";

    private TaxPaymentService taxPaymentService;

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        TaxPaymentRepositoryJdbcImpl repository =
                new TaxPaymentRepositoryJdbcImpl(DatabaseConfig.getJdbcTemplate());
        taxPaymentService = new TaxPaymentServiceImpl(repository, new TaxRateClientHttpImpl());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setCharacterEncoding("UTF-8");
        Optional<Long> id = parseId(request.getParameter("id"));
        if (id.isEmpty()) {
            request.setAttribute(ERROR_ATTRIBUTE, "Укажите корректный идентификатор записи.");
        } else {
            try {
                Optional<TaxPayment> payment = taxPaymentService.list(currentUserId(request)).stream()
                        .filter(item -> item.id() == id.get()).findFirst();
                if (payment.isPresent()) {
                    request.setAttribute("payment", payment.get());
                    request.setAttribute(FORM_EXPENSE_ATTRIBUTE,
                            payment.get().expenseAmount().toPlainString());
                } else {
                    request.setAttribute(ERROR_ATTRIBUTE, "Запись не найдена.");
                }
            } catch (DataAccessException exception) {
                request.setAttribute(ERROR_ATTRIBUTE,
                        "Не удалось подключиться к базе данных. Проверьте DB_URL, DB_USER и DB_PASSWORD.");
            }
        }
        request.getRequestDispatcher(VIEW).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        String idParameter = request.getParameter("id");
        String expenseAmount = request.getParameter("expenseAmount");
        request.setAttribute(FORM_EXPENSE_ATTRIBUTE, expenseAmount);

        Optional<Long> id = parseId(idParameter);
        if (id.isEmpty()) {
            request.setAttribute(ERROR_ATTRIBUTE, "Укажите корректный идентификатор записи.");
            request.getRequestDispatcher(VIEW).forward(request, response);
            return;
        }

        try {
            BigDecimal amount = parsePositiveAmount(expenseAmount);
            Optional<TaxPayment> updated = taxPaymentService.update(
                    currentUserId(request), id.get(), amount);
            if (updated.isEmpty()) {
                request.setAttribute(ERROR_ATTRIBUTE, "Запись не найдена.");
                request.getRequestDispatcher(VIEW).forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/tax-payments");
        } catch (IllegalArgumentException exception) {
            request.setAttribute(ERROR_ATTRIBUTE, exception.getMessage());
            request.setAttribute("paymentId", id.get());
            request.getRequestDispatcher(VIEW).forward(request, response);
        } catch (DataAccessException exception) {
            request.setAttribute(ERROR_ATTRIBUTE,
                    "Не удалось подключиться к базе данных. Проверьте DB_URL, DB_USER и DB_PASSWORD.");
            request.setAttribute("paymentId", id.get());
            request.getRequestDispatcher(VIEW).forward(request, response);
        }
    }

    private long currentUserId(HttpServletRequest request) {
        User user = (User) request.getSession(false).getAttribute(AuthFilter.USER_ATTRIBUTE);
        return user.id();
    }

    private Optional<Long> parseId(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            long id = Long.parseLong(value);
            return id > 0 ? Optional.of(id) : Optional.empty();
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
    }

    private BigDecimal parsePositiveAmount(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Укажите сумму расходов.");
        }
        try {
            BigDecimal amount = new BigDecimal(value.trim());
            if (amount.signum() <= 0) {
                throw new IllegalArgumentException("Сумма расходов должна быть положительной.");
            }
            return amount;
        } catch (NumberFormatException exception) {
            throw new IllegalArgumentException("Сумма расходов должна быть числом.", exception);
        }
    }
}
