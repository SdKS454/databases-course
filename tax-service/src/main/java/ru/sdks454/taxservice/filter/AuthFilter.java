package ru.sdks454.taxservice.filter;

import java.io.IOException;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebFilter(urlPatterns = {"/tax-payments", "/tax-payments/*"})
public class AuthFilter implements Filter {

    public static final String USER_ATTRIBUTE = "authenticatedUser";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        if (httpRequest.getSession(false) == null
                || httpRequest.getSession(false).getAttribute(USER_ATTRIBUTE) == null) {
            ((HttpServletResponse) response).sendRedirect(
                    httpRequest.getContextPath() + "/login");
            return;
        }
        chain.doFilter(request, response);
    }
}
