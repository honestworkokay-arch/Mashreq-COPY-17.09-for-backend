package com.mashreq.backend;

import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperReport;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;

import static org.assertj.core.api.Assertions.assertThat;

class ReceiptTemplateTest {

    @Test
    void jasperReceiptTemplateCompiles() throws Exception {
        try (InputStream input = new ClassPathResource("reports/fund_transfer_receipt.jrxml").getInputStream()) {
            JasperReport report = JasperCompileManager.compileReport(input);
            assertThat(report.getName()).isEqualTo("FundTransferReceipt");
        }
    }
}
