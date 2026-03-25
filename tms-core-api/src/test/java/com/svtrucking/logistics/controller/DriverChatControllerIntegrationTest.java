package com.svtrucking.logistics.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.config.TestSecurityConfig;
import com.svtrucking.logistics.model.DriverChatMessage;
import com.svtrucking.logistics.model.DriverChatMessageType;
import com.svtrucking.logistics.repository.DriverChatMessageRepository;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestRedisConfig.class, TestSecurityConfig.class})
@WithMockUser(roles = "ADMIN")
public class DriverChatControllerIntegrationTest {

  @Autowired
  private MockMvc mockMvc;

  @Autowired
  private ObjectMapper objectMapper;

  @Autowired
  private DriverChatMessageRepository repository;

  @Test
  void shouldCreateAndListDriverChatMessages() throws Exception {
    // Ensure repository starts empty
    repository.deleteAll();

    // Send a message as driver
    mockMvc.perform(post("/api/driver/chat/1/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(new SendMessageRequest("Hello dispatcher")))
            .with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.driverId").value(1))
        .andExpect(jsonPath("$.message").value("Hello dispatcher"))
        .andExpect(jsonPath("$.read").value(false));

    // Verify list endpoint returns it
    mockMvc.perform(get("/api/driver/chat/1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].driverId").value(1))
        .andExpect(jsonPath("$[0].message").value("Hello dispatcher"));

    List<DriverChatMessage> list = repository.findByDriverId(1L, org.springframework.data.domain.Sort.by("createdAt"));
    assertThat(list).hasSize(1);
  }

  @Test
  void shouldMarkMessageAsRead() throws Exception {
    repository.deleteAll();

    DriverChatMessage msg = DriverChatMessage.builder()
        .driverId(2L)
        .senderRole("ADMIN")
        .sender("system")
        .message("Please confirm delivery")
        .messageType(DriverChatMessageType.TEXT)
        .read(false)
        .createdAt(java.time.LocalDateTime.now())
        .build();
    msg = repository.save(msg);

    mockMvc.perform(post("/api/driver/chat/mark-read/" + msg.getId()).with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.read").value(true));

    DriverChatMessage updated = repository.findById(msg.getId()).orElseThrow();
    assertThat(updated.isRead()).isTrue();
  }

  @Test
  void shouldListConversationSummariesAndSupportAdminReply() throws Exception {
    repository.deleteAll();

    repository.save(
        DriverChatMessage.builder()
            .driverId(9L)
            .senderRole("DRIVER")
            .sender("driver")
            .messageType(DriverChatMessageType.TEXT)
            .message("Need support at gate 4")
            .read(false)
            .createdAt(java.time.LocalDateTime.now().minusMinutes(2))
            .build());

    mockMvc
        .perform(get("/api/admin/driver-chat/conversations"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].driverId").value(9))
        .andExpect(jsonPath("$[0].latestMessage").value("Need support at gate 4"))
        .andExpect(jsonPath("$[0].unreadDriverMessageCount").value(1));

    mockMvc
        .perform(
            post("/api/admin/driver-chat/9/send")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new SendMessageRequest("Proceed to dock B")))
                .with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.driverId").value(9))
        .andExpect(jsonPath("$.senderRole").value("ADMIN"))
        .andExpect(jsonPath("$.message").value("Proceed to dock B"));
  }

  @Test
  void shouldMarkUnreadDriverMessagesReadForAdminConversation() throws Exception {
    repository.deleteAll();

    repository.save(
        DriverChatMessage.builder()
            .driverId(15L)
            .senderRole("DRIVER")
            .sender("driver")
            .messageType(DriverChatMessageType.TEXT)
            .message("Can you confirm the route?")
            .read(false)
            .createdAt(java.time.LocalDateTime.now())
            .build());

    mockMvc
        .perform(post("/api/admin/driver-chat/15/mark-read").with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.driverId").value(15))
        .andExpect(jsonPath("$.updated").value(1));

    assertThat(repository.countByDriverIdAndReadFalseAndSenderRoleIgnoreCase(15L, "DRIVER"))
        .isZero();
  }

  @Test
  void shouldHandleCallRequestAndCallRequestAlias() throws Exception {
    repository.deleteAll();

    // Primary route
    mockMvc.perform(post("/api/driver/chat/1/start-call").with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.appId").isNotEmpty())
        .andExpect(jsonPath("$.agoraToken").isNotEmpty())
        .andExpect(jsonPath("$.channelName").isNotEmpty())
        .andExpect(jsonPath("$.sessionId").isNumber());

    // Alias route
    mockMvc.perform(post("/api/driver/chat/1/call-request").with(csrf()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.appId").isNotEmpty())
        .andExpect(jsonPath("$.agoraToken").isNotEmpty())
        .andExpect(jsonPath("$.channelName").isNotEmpty())
        .andExpect(jsonPath("$.sessionId").isNumber());
  }

  static class SendMessageRequest {
    public String message;

    public SendMessageRequest(String message) {
      this.message = message;
    }

    public SendMessageRequest() {
    }

    public String getMessage() {
      return message;
    }

    public void setMessage(String message) {
      this.message = message;
    }
  }
}
