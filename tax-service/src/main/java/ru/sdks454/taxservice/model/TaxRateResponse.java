package ru.sdks454.taxservice.model;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record TaxRateResponse(
        BigDecimal percent,
        Boolean success,
        String updatedAt,
        String message
) {

    public TaxRateResponse(BigDecimal percent) {
        this(percent, null, null, null);
    }
}
