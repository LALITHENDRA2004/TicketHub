package com.tickethub;

import org.springframework.boot.SpringApplication;

/** Runs the app locally against throwaway Testcontainers instead of docker-compose. */
public class TestTicketHubApplication {

    public static void main(String[] args) {
        SpringApplication.from(TicketHubApplication::main).with(TestcontainersConfiguration.class).run(args);
    }
}
