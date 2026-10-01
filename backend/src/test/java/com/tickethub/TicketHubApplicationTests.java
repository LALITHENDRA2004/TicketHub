package com.tickethub;

import static org.assertj.core.api.Assertions.assertThat;

import com.tickethub.common.CorrelationIdFilter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
@AutoConfigureMockMvc
class TicketHubApplicationTests {

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void flywayCreatesSchema() {
        Integer tables = jdbc.queryForObject(
                "select count(*) from information_schema.tables where table_schema = 'public' "
                        + "and table_name in ('users', 'shows', 'show_seats', 'bookings', 'payments', 'tickets')",
                Integer.class);
        assertThat(tables).isEqualTo(6);
    }

    @Test
    void healthIsUpAndCarriesCorrelationId() {
        assertThat(mvc.get().uri("/actuator/health"))
                .hasStatusOk()
                .containsHeader(CorrelationIdFilter.HEADER)
                .bodyJson().extractingPath("$.status").isEqualTo("UP");
    }

    @Test
    void incomingCorrelationIdIsEchoed() {
        assertThat(mvc.get().uri("/actuator/health").header(CorrelationIdFilter.HEADER, "abc-123"))
                .hasHeader(CorrelationIdFilter.HEADER, "abc-123");
    }

    @Test
    void unknownRoutesAreDenied() {
        assertThat(mvc.get().uri("/api/v1/anything")).hasStatus(403);
    }
}
