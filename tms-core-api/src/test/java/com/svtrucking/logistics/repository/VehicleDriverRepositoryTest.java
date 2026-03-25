package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.VehicleDriver;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;
import com.svtrucking.logistics.service.DeviceRegistrationService;
import com.svtrucking.logistics.service.TelematicsProxyService;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

@DataJpaTest
@ActiveProfiles("test")
@TestPropertySource(properties = "test.security.enabled=false")
public class VehicleDriverRepositoryTest {

    @Autowired
    private VehicleDriverRepository repository;

    @Test
    void findByRevokedAtIsNull_shouldReturnPagedResults() {
        Page<VehicleDriver> page = repository.findByRevokedAtIsNull(PageRequest.of(0, 10));
        List<VehicleDriver> content = page.getContent();
        assertThat(content).isNotNull();
        // No exception = pass. For real test, insert test data and assert size/content.
    }

    @TestConfiguration
    static class TestConfig {

        @Bean
        public DeviceRegistrationService deviceRegistrationService() {
            return mock(DeviceRegistrationService.class);
        }

        @Bean
        public TelematicsProxyService telematicsProxyService() {
            return mock(TelematicsProxyService.class);
        }
    }
}
