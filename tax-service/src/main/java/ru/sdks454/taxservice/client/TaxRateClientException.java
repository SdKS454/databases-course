package ru.sdks454.taxservice.client;

public class TaxRateClientException extends RuntimeException {

    public TaxRateClientException(String message) {
        super(message);
    }

    public TaxRateClientException(String message, Throwable cause) {
        super(message, cause);
    }
}
