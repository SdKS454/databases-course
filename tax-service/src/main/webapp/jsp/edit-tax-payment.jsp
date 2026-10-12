<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="header.jspf" %>

<c:if test="${not empty error}">
    <div class="alert"><c:out value="${error}"/></div>
</c:if>

<c:choose>
    <c:when test="${not empty payment or not empty paymentId}">
        <div class="page-heading">
            <h1>Изменить расходы</h1>
            <p>Обновите сумму — налог пересчитается по текущей ставке.</p>
        </div>
        <section class="card">
            <form method="post" action="${pageContext.request.contextPath}/tax-payments/edit">
                <input type="hidden" name="id"
                       value="${not empty payment ? payment.id : paymentId}">
                <label for="expenseAmount">Сумма расходов</label>
                <div class="form-row">
                    <input id="expenseAmount" name="expenseAmount" type="text"
                           inputmode="decimal"
                           value="${fn:escapeXml(formExpenseAmount)}" required>
                    <button type="submit">Сохранить</button>
                </div>
            </form>
            <a class="back-link" href="${pageContext.request.contextPath}/tax-payments">
                ← Вернуться к истории
            </a>
        </section>
    </c:when>
    <c:otherwise>
        <section class="card">
            <p class="empty">Запись не найдена.</p>
            <a class="back-link" href="${pageContext.request.contextPath}/tax-payments">
                ← Вернуться к истории
            </a>
        </section>
    </c:otherwise>
</c:choose>

<%@ include file="footer.jspf" %>
