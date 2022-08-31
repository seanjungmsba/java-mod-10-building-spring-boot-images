package com.example.restservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication
public class RestServiceApplication {
	public static void main(String[] args) {
		System.setProperty("datastax-java-driver.advanced.request-tracker.class", "RequestLogger");
		System.setProperty("datastax-java-driver.advanced.request-tracker.logs.success.enabled", "true");
		SpringApplication.run(RestServiceApplication.class, args);
	}
}
