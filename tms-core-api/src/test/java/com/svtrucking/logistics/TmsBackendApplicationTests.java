package com.svtrucking.logistics;

import com.svtrucking.logistics.config.TestRedisConfig;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestRedisConfig.class)
class TmsBackendApplicationTests {

  @Test
  void contextLoads() {}
}
