package com.mashreq.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MashreqBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(MashreqBackendApplication.class, args);
    }
}
