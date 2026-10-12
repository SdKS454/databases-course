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

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

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
        request.getRequestDispatcher("/jsp/register.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        try {
            authService.register(request.getParameter("login"),
                    request.getParameter("firstName"),
                    request.getParameter("lastName"),
                    request.getParameter("patronymic"),
                    request.getParameter("password"));
            response.sendRedirect(request.getContextPath() + "/login?registered=true");
        } catch (IllegalArgumentException exception) {
            request.setAttribute("error", exception.getMessage());
            request.getRequestDispatcher("/jsp/register.jsp").forward(request, response);
        }
    }
}
