package com.grhmobile;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class GrhMobileApplication {

    public static void main(String[] args) {
        SpringApplication.run(GrhMobileApplication.class, args);
    }
}
