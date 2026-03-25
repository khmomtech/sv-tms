package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.controller.driver.DriverChatController.SendMessageRequest;
import com.svtrucking.logistics.dto.chat.DriverChatConversationSummaryDto;
import com.svtrucking.logistics.model.DriverChatMessage;
import com.svtrucking.logistics.model.DriverChatMessageType;
import com.svtrucking.logistics.service.DriverChatMessageService;
import com.svtrucking.logistics.service.DriverChatMessageService.CallTokenResponse;
import com.svtrucking.logistics.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.security.Principal;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/driver-chat")
@RequiredArgsConstructor
@Tag(name = "Admin Driver Chat", description = "Admin inbox for driver support conversations.")
public class AdminDriverChatController {

  private final DriverChatMessageService chatMessageService;
  private final FileStorageService fileStorageService;

  @GetMapping("/conversations")
  @Operation(summary = "List driver chat conversations ordered by latest activity.")
  public ResponseEntity<List<DriverChatConversationSummaryDto>> listConversations() {
    return ResponseEntity.ok(chatMessageService.listConversationSummaries());
  }

  @GetMapping("/{driverId}")
  @Operation(summary = "List messages for a driver conversation with optional pagination.")
  public ResponseEntity<List<DriverChatMessage>> listConversation(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "30") int size) {
    return ResponseEntity.ok(chatMessageService.listForDriver(driverId, page, size));
  }

  @PostMapping("/{driverId}/send")
  @Operation(summary = "Send a message from admin to driver.")
  public ResponseEntity<DriverChatMessage> sendMessage(
      @PathVariable Long driverId,
      @RequestBody SendMessageRequest request) {
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(driverId, "ADMIN", "Admin", request.message()));
  }

  @PostMapping("/{driverId}/send-photo")
  @Operation(summary = "Send a chat photo message from admin to driver.")
  public ResponseEntity<DriverChatMessage> sendPhoto(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file) {
    if (file.isEmpty() || file.getContentType() == null || !file.getContentType().startsWith("image/")) {
      return ResponseEntity.badRequest().build();
    }
    String fileUrl = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n📷 " + fileUrl
        : "📷 " + fileUrl;
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId,
            "ADMIN",
            "Admin",
            text,
            DriverChatMessageType.IMAGE));
  }

  @PostMapping("/{driverId}/send-voice")
  @Operation(summary = "Send a chat message with a voice note from admin.")
  public ResponseEntity<DriverChatMessage> sendVoice(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file) {

    if (file.isEmpty() || file.getContentType() == null || !file.getContentType().startsWith("audio/")) {
      return ResponseEntity.badRequest().build();
    }

    String fileUrl = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n🔊 " + fileUrl
        : "🔊 " + fileUrl;

    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId,
            "ADMIN",
            "Admin",
            text,
            DriverChatMessageType.VOICE));
  }

  @PostMapping("/{driverId}/send-video")
  @Operation(summary = "Send a chat video from admin to driver.")
  public ResponseEntity<DriverChatMessage> sendVideo(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file) {
    if (file.isEmpty() || file.getContentType() == null || !file.getContentType().startsWith("video/")) {
      return ResponseEntity.badRequest().build();
    }
    String fileUrl = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n🎬 " + fileUrl
        : "🎬 " + fileUrl;
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId, "ADMIN", "Admin", text, DriverChatMessageType.VIDEO));
  }

  /**
   * Admin initiates a call to driver.
   * Creates a CallSession, generates Agora token, broadcasts CALL_REQUEST via STOMP.
   * Admin web-UI uses the returned {appId, agoraToken, channelName} to join the channel.
   */
  @PostMapping("/{driverId}/start-call")
  @Operation(summary = "Admin initiates a call to driver (creates Agora session).")
  public ResponseEntity<CallTokenResponse> startCall(
      @PathVariable Long driverId, Principal principal) {
    String adminName = principal != null ? principal.getName() : "Admin";
    CallTokenResponse resp = chatMessageService.createCallSession(driverId, "ADMIN", adminName);
    return ResponseEntity.ok(resp);
  }

  /** Admin accepts a driver-initiated call. */
  @PostMapping("/{driverId}/accept-call")
  @Operation(summary = "Admin accepts a driver call request.")
  public ResponseEntity<CallTokenResponse> acceptCall(
      @PathVariable Long driverId, Principal principal) {
    String adminName = principal != null ? principal.getName() : "Admin";
    CallTokenResponse resp = chatMessageService.acceptCallSession(driverId, "ADMIN", adminName);
    return ResponseEntity.ok(resp);
  }

  /** Admin ends the active call. */
  @PostMapping("/{driverId}/end-call")
  @Operation(summary = "Admin ends an active call.")
  public ResponseEntity<Map<String, String>> endCall(
      @PathVariable Long driverId, Principal principal) {
    String adminName = principal != null ? principal.getName() : "Admin";
    chatMessageService.endCallSession(driverId, "ADMIN", adminName);
    return ResponseEntity.ok(Map.of("status", "ENDED"));
  }

  /** Broadcast typing indicator from admin side. */
  @PostMapping("/{driverId}/typing")
  @Operation(summary = "Admin typing indicator (ephemeral).")
  public ResponseEntity<Void> typing(@PathVariable Long driverId) {
    chatMessageService.broadcastTyping(driverId, "ADMIN");
    return ResponseEntity.ok().build();
  }

  @PostMapping("/{driverId}/mark-read")
  @Operation(summary = "Mark all unread driver messages in a conversation as read by admin.")
  public ResponseEntity<Map<String, Object>> markConversationRead(@PathVariable Long driverId) {
    int updated = chatMessageService.markDriverMessagesReadByAdmin(driverId);
    return ResponseEntity.ok(Map.of("driverId", driverId, "updated", updated));
  }

  @PostMapping("/{driverId}/archive")
  @Operation(summary = "Archive a driver conversation (hide from inbox).")
  public ResponseEntity<Map<String, Object>> archiveConversation(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "true") boolean archived) {
    chatMessageService.setArchived(driverId, archived);
    return ResponseEntity.ok(Map.of("driverId", driverId, "archivedByAdmin", archived));
  }

  @PostMapping("/{driverId}/resolve")
  @Operation(summary = "Mark a driver conversation as resolved by admin.")
  public ResponseEntity<Map<String, Object>> resolveConversation(
      @PathVariable Long driverId,
      @RequestParam(defaultValue = "true") boolean resolved) {
    chatMessageService.setResolved(driverId, resolved);
    return ResponseEntity.ok(Map.of("driverId", driverId, "resolvedByAdmin", resolved));
  }
}
