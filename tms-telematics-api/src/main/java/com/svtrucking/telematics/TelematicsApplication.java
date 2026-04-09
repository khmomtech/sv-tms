package com.svtrucking.telematics;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableJpaRepositories(basePackages = "com.svtrucking.telematics.repository")
public class TelematicsApplication {
    public static void main(String[] args) {
        SpringApplication.run(TelematicsApplication.class, args);
    }
}
