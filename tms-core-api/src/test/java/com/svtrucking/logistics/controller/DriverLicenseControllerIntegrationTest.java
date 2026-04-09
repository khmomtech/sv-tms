package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.service.DriverLicenseService;
import com.svtrucking.logistics.service.FileStorageService;
import com.svtrucking.logistics.service.AuditTrailService;
import com.svtrucking.logistics.security.JwtUtil;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class DriverLicenseControllerIntegrationTest {

  @InjectMocks private DriverLicenseController controller;

  private MockMvc mockMvc;

  @Mock private FileStorageService fileStorageService;
  @Mock private DriverLicenseService driverLicenseService;
  @Mock private AuditTrailService auditTrailService;
  @Mock private JwtUtil jwtUtil;
  @Mock private MeterRegistry meterRegistry;

  @Test
  void uploadFront_shouldStoreFileAndCallService() throws Exception {
    mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    MockMultipartFile file =
        new MockMultipartFile("file", "front.jpg", "image/jpeg", "dummy-data".getBytes());

    when(fileStorageService.storeFileInSubfolder(any(), eq("licenses")))
        .thenReturn("/uploads/licenses/front.jpg");
    doNothing().when(driverLicenseService).updateLicenseImage(eq(2L), eq(true), any());

    mockMvc
        .perform(multipart("/api/admin/driver-licenses/2/upload-front").file(file).contentType(MediaType.MULTIPART_FORM_DATA))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));

    verify(fileStorageService).storeFileInSubfolder(any(), eq("licenses"));
    verify(driverLicenseService).updateLicenseImage(eq(2L), eq(true), any());
  }
}
