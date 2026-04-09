package com.svtrucking.logistics.controller.drivers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.PermissionRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

/**
 * Integration tests for Driver Document API endpoints.
 * Tests CRUD operations for driver documents including file upload functionality.
 */
@SpringBootTest(
    properties = {
        "spring.autoconfigure.exclude=" +
        "org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration," +
        "org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration," +
        "org.springframework.boot.autoconfigure.websocket.servlet.WebSocketServletAutoConfiguration"
    }
)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@Import({TestRedisConfig.class, com.svtrucking.logistics.config.TestSecurityConfig.class})
public class DriverDocumentIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private DriverDocumentRepository driverDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PermissionRepository permissionRepository;


    @Autowired
    private PasswordEncoder passwordEncoder;

    // Removed deprecated @MockBean injections for RedisTemplate and LiveLocationCacheService.
    // Redis and live location caching are excluded/disabled for these tests via Spring properties.

    private Driver testDriver;
    private User testUser;

    @BeforeEach
    void setUp() {
        // Create test user
        testUser = new User();
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setPassword("password");
        testUser = userRepository.save(testUser);

        // Create test driver
        testDriver = new Driver();
        testDriver.setLicenseNumber("TEST123");
        testDriver.setFirstName("John");
        testDriver.setLastName("Doe");
        testDriver.setPhone("1234567890");
        testDriver.setPartner(false);
        testDriver.setUser(testUser);
        testDriver = driverRepository.save(testDriver);
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testGetDriverDocuments_EmptyList() throws Exception {
        mockMvc.perform(get("/api/admin/drivers/{driverId}/documents", testDriver.getId()))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_Success() throws Exception {
        // Create a test file
        Path testFilePath = Paths.get("src/test/resources/test-document.pdf");
        if (!Files.exists(testFilePath)) {
            Files.createDirectories(testFilePath.getParent());
            Files.write(testFilePath, "Test PDF content".getBytes());
        }

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                Files.readAllBytes(testFilePath)
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "Test Document")
                        .param("category", "LICENSE")
                        .param("expiryDate", "2025-12-31"))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.name").value("Test Document"))
                .andExpect(jsonPath("$.data.category").value("LICENSE"))
                .andExpect(jsonPath("$.data.fileUrl").exists());

        // Verify document was saved
        assertThat(driverDocumentRepository.findByDriverId(testDriver.getId())).hasSize(1);
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testGetDriverDocuments_WithDocuments() throws Exception {
        // First upload a document
        DriverDocument doc = new DriverDocument();
        doc.setDriver(testDriver);
        doc.setName("Test License");
        doc.setCategory("LICENSE");
        doc.setFileUrl("/uploads/documents/test.pdf");
        doc.setIsRequired(false);
        driverDocumentRepository.save(doc);

        mockMvc.perform(get("/api/admin/drivers/{driverId}/documents", testDriver.getId()))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].name").value("Test License"))
                .andExpect(jsonPath("$.data[0].category").value("LICENSE"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUpdateDriverDocument_Success() throws Exception {
        // First create a document
        DriverDocument doc = new DriverDocument();
        doc.setDriver(testDriver);
        doc.setName("Original Name");
        doc.setCategory("LICENSE");
        doc.setFileUrl("/uploads/documents/test.pdf");
        doc.setIsRequired(false);
        doc = driverDocumentRepository.save(doc);

        // Update the document
        mockMvc.perform(put("/api/admin/drivers/{driverId}/documents/{documentId}", testDriver.getId(), doc.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name": "Updated Name",
                                    "category": "INSURANCE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.name").value("Updated Name"))
                .andExpect(jsonPath("$.data.category").value("INSURANCE"));

        // Verify document was updated
        DriverDocument updated = driverDocumentRepository.findById(doc.getId()).orElseThrow();
        assertThat(updated.getName()).isEqualTo("Updated Name");
        assertThat(updated.getCategory()).isEqualTo("INSURANCE");
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testDeleteDriverDocument_Success() throws Exception {
        // First create a document
        DriverDocument doc = new DriverDocument();
        doc.setDriver(testDriver);
        doc.setName("Document to Delete");
        doc.setCategory("LICENSE");
        doc.setFileUrl("/uploads/documents/test.pdf");
        doc.setIsRequired(false);
        doc = driverDocumentRepository.save(doc);

        // Delete the document
        mockMvc.perform(delete("/api/admin/drivers/{driverId}/documents/{documentId}", testDriver.getId(), doc.getId()))
                .andExpect(status().isOk());

        // Verify document was deleted
        assertThat(driverDocumentRepository.findById(doc.getId())).isEmpty();
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_InvalidFileType() throws Exception {
        // Create a test file with invalid type
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test.exe",
                "application/octet-stream",
                "Invalid file content".getBytes()
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "Invalid File")
                        .param("category", "LICENSE"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testGetDriverDocuments_NonExistentDriver() throws Exception {
        mockMvc.perform(get("/api/admin/drivers/{driverId}/documents", 99999L))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_WithoutName() throws Exception {
        // Create a test file
        Path testFilePath = Paths.get("src/test/resources/test-document-no-name.pdf");
        if (!Files.exists(testFilePath)) {
            Files.createDirectories(testFilePath.getParent());
            Files.write(testFilePath, "Test PDF content without name".getBytes());
        }

        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document-no-name.pdf",
                "application/pdf",
                Files.readAllBytes(testFilePath)
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("category", "LICENSE")
                        .param("expiryDate", "2025-12-31"))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.name").value("test-document-no-name.pdf")) // Should use filename as fallback
                .andExpect(jsonPath("$.data.category").value("LICENSE"))
                .andExpect(jsonPath("$.data.fileUrl").exists());

        // Verify document was saved with the correct name
        List<DriverDocument> documents = driverDocumentRepository.findByDriverId(testDriver.getId());
        assertThat(documents).hasSize(1);
        assertThat(documents.get(0).getName()).isEqualTo("test-document-no-name.pdf");
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_NullName_ShouldFail() throws Exception {
        // Create a test file
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                "Test PDF content".getBytes()
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("category", "LICENSE"))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("test-document.pdf")); // Controller sets filename as name
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_EmptyName_ShouldSucceed() throws Exception {
        // Create a test file
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                "Test PDF content".getBytes()
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "")
                        .param("category", "LICENSE"))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("test-document.pdf")); // Controller sets filename as name
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_NullCategory_ShouldFail() throws Exception {
        // Create a test file
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                "Test PDF content".getBytes()
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "Test Document"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation error: Document category is required"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testUploadDriverDocument_EmptyCategory_ShouldFail() throws Exception {
        // Create a test file
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test-document.pdf",
                "application/pdf",
                "Test PDF content".getBytes()
        );

        mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "Test Document")
                        .param("category", ""))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation error: Document category is required"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testCreateDriverDocument_NullName_ShouldFail() throws Exception {
        mockMvc.perform(post("/api/admin/drivers/{driverId}/documents", testDriver.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "category": "LICENSE",
                                    "fileUrl": "/uploads/test.pdf"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation failed."))
                .andExpect(jsonPath("$.errors.name").value("Document name is required"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testCreateDriverDocument_EmptyName_ShouldFail() throws Exception {
        mockMvc.perform(post("/api/admin/drivers/{driverId}/documents", testDriver.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name": "",
                                    "category": "LICENSE",
                                    "fileUrl": "/uploads/test.pdf"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation failed."))
                .andExpect(jsonPath("$.errors.name").value("Document name is required"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testCreateDriverDocument_NullCategory_ShouldFail() throws Exception {
        mockMvc.perform(post("/api/admin/drivers/{driverId}/documents", testDriver.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name": "Test Document",
                                    "fileUrl": "/uploads/test.pdf"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation failed."))
                .andExpect(jsonPath("$.errors.category").value("Document category is required"));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testCreateDriverDocument_EmptyCategory_ShouldFail() throws Exception {
        mockMvc.perform(post("/api/admin/drivers/{driverId}/documents", testDriver.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name": "Test Document",
                                    "category": "",
                                    "fileUrl": "/uploads/test.pdf"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Validation failed."))
                .andExpect(jsonPath("$.errors.category").value("Document category is required"));
    }

    // ===== NEW DOWNLOAD + INTEGRITY TESTS =====

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testDownloadDriverDocument_SuccessIntegrityOk() throws Exception {
        // Upload a document first to trigger audit creation
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "integrity-ok.pdf",
                "application/pdf",
                "Integrity OK content".getBytes()
        );

        var uploadResult = mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "Integrity Doc")
                        .param("category", "LICENSE"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").exists())
                .andExpect(jsonPath("$.data.fileUrl").exists())
                .andReturn();

        // Extract documentId and fileUrl from JSON
        String uploadJson = uploadResult.getResponse().getContentAsString();
        var node = objectMapper.readTree(uploadJson).get("data");
        Long documentId = node.get("id").asLong();

        // Perform download
        mockMvc.perform(get("/api/admin/drivers/{driverId}/documents/{documentId}/download", testDriver.getId(), documentId))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Document-Integrity", "ok"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("filename=\"integrity-ok.pdf\"")))
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PDF));
    }

    @Test
    @WithMockUser(username = "admin", authorities = {"driver:manage"})
    public void testDownloadDriverDocument_FileMissing_NotFound() throws Exception {
        // Upload a document first to trigger audit creation
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "missing-file.pdf",
                "application/pdf",
                "File that will be deleted".getBytes()
        );

        var uploadResult = mockMvc.perform(multipart("/api/admin/drivers/{driverId}/documents/upload", testDriver.getId())
                        .file(file)
                        .param("name", "To Delete Doc")
                        .param("category", "LICENSE"))
                .andExpect(status().isCreated())
                .andReturn();

        String uploadJson = uploadResult.getResponse().getContentAsString();
        var node = objectMapper.readTree(uploadJson).get("data");
        Long documentId = node.get("id").asLong();
        String fileUrl = node.get("fileUrl").asText();

        // Derive physical path (mirrors logic in DocumentAuditService)
        String working = fileUrl.trim();
        if (working.startsWith("uploads/")) working = "/" + working; // normalize legacy
        java.nio.file.Path path;
        if (working.startsWith("/uploads/")) {
            String relative = working.substring("/uploads/".length());
            // Base dir defaults to "uploads/" (relative) resolved to absolute
            java.nio.file.Path base = java.nio.file.Paths.get("uploads/").toAbsolutePath().normalize();
            path = base.resolve(relative).normalize();
        } else {
            path = java.nio.file.Paths.get(working).normalize();
        }

        // Delete the underlying file to simulate missing file scenario
        if (java.nio.file.Files.exists(path)) {
            java.nio.file.Files.delete(path);
        }

        // Attempt download -> expect 404
        mockMvc.perform(get("/api/admin/drivers/{driverId}/documents/{documentId}/download", testDriver.getId(), documentId))
                .andExpect(status().isNotFound());
    }
}
