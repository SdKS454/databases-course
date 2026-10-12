<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="header.jspf" %>

<div class="page-heading">
    <h1>Регистрация</h1>
    <p>Заполните данные на русском языке.</p>
</div>
<section class="card auth-card">
    <c:if test="${not empty error}">
        <div class="alert"><c:out value="${error}"/></div>
    </c:if>
    <form method="post" action="${pageContext.request.contextPath}/register">
        <label for="login">Логин</label>
        <input id="login" name="login" type="text" autocomplete="username"
               value="${fn:escapeXml(param.login)}" required>
        <label for="lastName">Фамилия</label>
        <input id="lastName" name="lastName" type="text"
               value="${fn:escapeXml(param.lastName)}" required>
        <label for="firstName">Имя</label>
        <input id="firstName" name="firstName" type="text"
               value="${fn:escapeXml(param.firstName)}" required>
        <label for="patronymic">Отчество</label>
        <input id="patronymic" name="patronymic" type="text"
               value="${fn:escapeXml(param.patronymic)}" required>
        <label for="password">Пароль</label>
        <input id="password" name="password" type="password"
               autocomplete="new-password" required>
        <button type="submit">Создать аккаунт</button>
    </form>
    <p class="auth-link">Уже есть аккаунт?
        <a href="${pageContext.request.contextPath}/login">Войти</a>
    </p>
</section>
<%@ include file="footer.jspf" %>
