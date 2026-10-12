<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="header.jspf" %>

<c:if test="${not empty error}">
    <div class="alert"><c:out value="${error}"/></div>
</c:if>

<div class="page-heading">
    <h1>Налоговые расходы</h1>
    <p>Добавляйте расходы и отслеживайте актуальную сумму налога.</p>
</div>

<div class="grid">
    <section class="card">
        <div class="current-label">Текущий налоговый процент</div>
        <c:choose>
            <c:when test="${not empty taxPercent}">
                <div class="current">
                    <fmt:formatNumber value="${taxPercent}" minFractionDigits="0"
                                      maxFractionDigits="2"/>%
                </div>
                <p class="rate-note">Ставка получена от сервиса администрирования
                    при открытии этой страницы.</p>
            </c:when>
            <c:otherwise>
                <div class="current">—</div>
                <p class="rate-note">Не удалось получить текущую ставку.</p>
            </c:otherwise>
        </c:choose>
    </section>

    <section class="card">
        <h2>Добавить расходы</h2>
        <form method="post" action="${pageContext.request.contextPath}/tax-payments">
            <label for="expenseAmount">Сумма расходов</label>
            <div class="form-row">
                <input id="expenseAmount" name="expenseAmount" type="text"
                       inputmode="decimal"
                       placeholder="например, 1000.00"
                       value="${fn:escapeXml(formExpenseAmount)}" required>
                <button type="submit">Добавить</button>
            </div>
        </form>
    </section>
</div>

<section class="card" style="margin-top: 20px;">
    <h2>История расходов</h2>
    <c:choose>
        <c:when test="${not empty payments}">
            <div class="table-wrap">
                <table>
                    <thead>
                    <tr>
                        <th>Дата</th>
                        <th>Расходы</th>
                        <th>Налог</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <c:forEach var="payment" items="${payments}">
                        <tr>
                            <td><c:out value="${payment.createdAtText}"/></td>
                            <td class="amount"><fmt:formatNumber value="${payment.expenseAmount}"
                                minFractionDigits="2" maxFractionDigits="2"/></td>
                            <td class="amount"><fmt:formatNumber value="${payment.taxAmount}"
                                minFractionDigits="2" maxFractionDigits="2"/></td>
                            <td>
                                <a class="button button-secondary"
                                   href="${pageContext.request.contextPath}/tax-payments/edit?id=${payment.id}">
                                    Изменить
                                </a>
                            </td>
                        </tr>
                    </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <p class="empty">Записей пока нет. Добавьте первый расход выше.</p>
        </c:otherwise>
    </c:choose>
</section>

<%@ include file="footer.jspf" %>
