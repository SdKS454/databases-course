package ru.sdks454.taxservice.servlet;

import java.io.IOException;
import java.math.BigDecimal;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.dao.DataAccessException;

import ru.sdks454.taxservice.client.TaxRateClient;
import ru.sdks454.taxservice.client.TaxRateClientException;
import ru.sdks454.taxservice.config.DatabaseConfig;
import ru.sdks454.taxservice.client.TaxRateClientHttpImpl;
import ru.sdks454.taxservice.filter.AuthFilter;
import ru.sdks454.taxservice.model.User;
import ru.sdks454.taxservice.model.TaxRateResponse;
import ru.sdks454.taxservice.repository.TaxPaymentRepositoryJdbcImpl;
import ru.sdks454.taxservice.service.TaxPaymentService;
import ru.sdks454.taxservice.service.TaxPaymentServiceImpl;

@WebServlet("/tax-payments")
public class TaxPaymentsServlet extends HttpServlet {

    private static final String VIEW = "/jsp/tax-payments.jsp";
    private static final String ERROR_ATTRIBUTE = "error";
    private static final String FORM_EXPENSE_ATTRIBUTE = "formExpenseAmount";

    private TaxPaymentService taxPaymentService;
    private TaxRateClient taxRateClient;

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        TaxPaymentRepositoryJdbcImpl repository =
                new TaxPaymentRepositoryJdbcImpl(DatabaseConfig.getJdbcTemplate());
        taxRateClient = new TaxRateClientHttpImpl();
        taxPaymentService = new TaxPaymentServiceImpl(repository, taxRateClient);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setCharacterEncoding("UTF-8");
        long userId = currentUserId(request);
        try {
            TaxRateResponse taxRate = taxRateClient.getCurrentRate();
            request.setAttribute("taxPercent", taxRate.percent());
            request.setAttribute("payments", taxPaymentService.listWithTax(userId, taxRate));
        } catch (TaxRateClientException exception) {
            request.setAttribute(ERROR_ATTRIBUTE, exception.getMessage());
        } catch (DataAccessException exception) {
            request.setAttribute(ERROR_ATTRIBUTE,
                    "Не удалось подключиться к базе данных. Проверьте DB_URL, DB_USER и DB_PASSWORD.");
        }
        request.getRequestDispatcher(VIEW).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        String expenseAmount = request.getParameter("expenseAmount");
        request.setAttribute(FORM_EXPENSE_ATTRIBUTE, expenseAmount);

        try {
            BigDecimal amount = parsePositiveAmount(expenseAmount);
            taxPaymentService.create(currentUserId(request), amount);
            response.sendRedirect(request.getContextPath() + "/tax-payments");
        } catch (IllegalArgumentException exception) {
            request.setAttribute(ERROR_ATTRIBUTE, exception.getMessage());
            doGet(request, response);
        } catch (DataAccessException exception) {
            request.setAttribute(ERROR_ATTRIBUTE,
                    "Не удалось подключиться к базе данных. Проверьте DB_URL, DB_USER и DB_PASSWORD.");
            request.getRequestDispatcher(VIEW).forward(request, response);
        }

    }

    private long currentUserId(HttpServletRequest request) {
        User user = (User) request.getSession(false).getAttribute(AuthFilter.USER_ATTRIBUTE);
        return user.id();
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
