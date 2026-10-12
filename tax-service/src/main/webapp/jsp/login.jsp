<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="header.jspf" %>

<div class="page-heading">
    <h1>Вход</h1>
    <p>Войдите, чтобы работать с налоговыми расходами.</p>
</div>
<section class="card auth-card">
    <c:if test="${param.registered eq 'true'}">
        <div class="success">Регистрация завершена. Теперь войдите.</div>
    </c:if>
    <c:if test="${not empty error}">
        <div class="alert"><c:out value="${error}"/></div>
    </c:if>
    <form method="post" action="${pageContext.request.contextPath}/login">
        <label for="login">Логин</label>
        <input id="login" name="login" type="text" autocomplete="username" required>
        <label for="password">Пароль</label>
        <input id="password" name="password" type="password"
               autocomplete="current-password" required>
        <button type="submit">Войти</button>
    </form>
    <p class="auth-link">Нет аккаунта?
        <a href="${pageContext.request.contextPath}/register">Зарегистрироваться</a>
    </p>
</section>
<%@ include file="footer.jspf" %>
