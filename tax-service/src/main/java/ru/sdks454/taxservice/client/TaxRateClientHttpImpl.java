package ru.sdks454.taxservice.client;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.math.BigDecimal;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import ru.sdks454.taxservice.model.TaxRateResponse;

public class TaxRateClientHttpImpl implements TaxRateClient {

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(5);
    private static final BigDecimal MIN_PERCENT = BigDecimal.ZERO;
    private static final BigDecimal MAX_PERCENT = BigDecimal.valueOf(100);

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final URI taxEndpoint;

    public TaxRateClientHttpImpl() {
        this(
                HttpClient.newBuilder()
                        .connectTimeout(CONNECT_TIMEOUT)
                        .build(),
                new ObjectMapper(),
                requiredTaxServiceUrl()
        );
    }

    TaxRateClientHttpImpl(HttpClient httpClient, ObjectMapper objectMapper, String baseUrl) {
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
        this.taxEndpoint = createTaxEndpoint(baseUrl);
    }

    @Override
    public TaxRateResponse getCurrentRate() {
        HttpRequest request = HttpRequest.newBuilder(taxEndpoint)
                .timeout(REQUEST_TIMEOUT)
                .GET()
                .build();

        final HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException | InterruptedException | RuntimeException exception) {
            if (exception instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new TaxRateClientException("Tax service is unavailable", exception);
        }

        if (response.statusCode() != 200) {
            throw new TaxRateClientException(
                    "Tax service returned unexpected HTTP status: " + response.statusCode());
        }

        final TaxRateResponse taxRate;
        try {
            taxRate = objectMapper.readValue(response.body(), TaxRateResponse.class);
        } catch (JsonProcessingException | RuntimeException exception) {
            throw new TaxRateClientException("Tax service returned invalid JSON", exception);
        }

        validatePercent(taxRate);
        return taxRate;
    }

    private static String requiredTaxServiceUrl() {
        String baseUrl = System.getenv("TAX_SERVICE_URL");
        if (baseUrl == null || baseUrl.isBlank()) {
            throw new TaxRateClientException("Environment variable is required: TAX_SERVICE_URL");
        }
        return baseUrl;
    }

    private static URI createTaxEndpoint(String baseUrl) {
        try {
            return URI.create(stripTrailingSlashes(baseUrl) + "/api/tax");
        } catch (IllegalArgumentException exception) {
            throw new TaxRateClientException("TAX_SERVICE_URL is invalid", exception);
        }
    }

    private static String stripTrailingSlashes(String value) {
        int end = value.length();
        while (end > 0 && value.charAt(end - 1) == '/') {
            end--;
        }
        return value.substring(0, end);
    }

    private static void validatePercent(TaxRateResponse taxRate) {
        if (taxRate == null
                || Boolean.FALSE.equals(taxRate.success())
                || taxRate.percent() == null
                || taxRate.percent().compareTo(MIN_PERCENT) < 0
                || taxRate.percent().compareTo(MAX_PERCENT) > 0) {
            throw new TaxRateClientException("Tax service returned invalid percent");
        }
    }
}
