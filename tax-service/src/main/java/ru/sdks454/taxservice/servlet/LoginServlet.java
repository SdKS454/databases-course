package ru.sdks454.taxservice.servlet;

import java.io.IOException;

import jakarta.servlet.ServletConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import ru.sdks454.taxservice.config.DatabaseConfig;
import ru.sdks454.taxservice.filter.AuthFilter;
import ru.sdks454.taxservice.repository.UserRepositoryJdbcImpl;
import ru.sdks454.taxservice.service.AuthService;
import ru.sdks454.taxservice.service.AuthServiceImpl;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private AuthService authService;

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        authService = new AuthServiceImpl(
                new UserRepositoryJdbcImpl(DatabaseConfig.getJdbcTemplate()));
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setCharacterEncoding("UTF-8");
        if (request.getSession(false) != null
                && request.getSession(false).getAttribute(AuthFilter.USER_ATTRIBUTE) != null) {
            response.sendRedirect(request.getContextPath() + "/tax-payments");
            return;
        }
        request.getRequestDispatcher("/jsp/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String login = request.getParameter("login");
        String password = request.getParameter("password");
        if (authService.authenticate(login, password).isEmpty()) {
            request.setAttribute("error", "Неверный логин или пароль.");
            doGet(request, response);
            return;
        }
        request.getSession(true).setAttribute(AuthFilter.USER_ATTRIBUTE,
                authService.authenticate(login, password).orElseThrow());
        response.sendRedirect(request.getContextPath() + "/tax-payments");
    }
}
