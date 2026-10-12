package ru.sdks454.taxservice.client;

import ru.sdks454.taxservice.model.TaxRateResponse;

public interface TaxRateClient {

    TaxRateResponse getCurrentRate();
}
