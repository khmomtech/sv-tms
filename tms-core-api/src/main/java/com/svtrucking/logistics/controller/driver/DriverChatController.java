package com.svtrucking.logistics.controller.driver;

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
import lombok.extern.slf4j.Slf4j;
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
@RequestMapping("/api/driver/chat")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Driver Chat", description = "Driver ↔ admin chat + voice/video call signalling.")
public class DriverChatController {

  private final DriverChatMessageService chatMessageService;
  private final FileStorageService fileStorageService;

  // ─── Message endpoints ──────────────────────────────────────────────────

  @GetMapping("/{driverId}")
  @Operation(summary = "List chat messages for a driver")
  public ResponseEntity<List<DriverChatMessage>> listMessages(
      @PathVariable Long driverId, Principal principal) {
    return ResponseEntity.ok(chatMessageService.listForDriver(driverId));
  }

  @PostMapping("/{driverId}/send")
  @Operation(summary = "Send a text message as driver")
  public ResponseEntity<DriverChatMessage> sendMessage(
      @PathVariable Long driverId,
      @RequestBody SendMessageRequest request,
      Principal principal) {
    String sender = resolveSender(principal);
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(driverId, "DRIVER", sender, request.message()));
  }

  @PostMapping("/{driverId}/send-photo")
  @Operation(summary = "Send a photo message as driver")
  public ResponseEntity<DriverChatMessage> sendPhoto(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file,
      Principal principal) {

    if (file.isEmpty() || file.getContentType() == null
        || !file.getContentType().startsWith("image/")) {
      return ResponseEntity.badRequest().build();
    }
    String sender = resolveSender(principal);
    String url = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n📷 " + url : "📷 " + url;
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId, "DRIVER", sender, text, DriverChatMessageType.IMAGE));
  }

  @PostMapping("/{driverId}/send-voice")
  @Operation(summary = "Send a voice note as driver")
  public ResponseEntity<DriverChatMessage> sendVoice(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file,
      Principal principal) {

    if (file.isEmpty() || file.getContentType() == null
        || !file.getContentType().startsWith("audio/")) {
      return ResponseEntity.badRequest().build();
    }
    String sender = resolveSender(principal);
    String url = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n🔊 " + url : "🔊 " + url;
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId, "DRIVER", sender, text, DriverChatMessageType.VOICE));
  }

  @PostMapping("/{driverId}/send-video")
  @Operation(summary = "Send a video clip as driver")
  public ResponseEntity<DriverChatMessage> sendVideo(
      @PathVariable Long driverId,
      @RequestParam(required = false) String message,
      @RequestParam MultipartFile file,
      Principal principal) {

    if (file.isEmpty() || file.getContentType() == null
        || !file.getContentType().startsWith("video/")) {
      return ResponseEntity.badRequest().build();
    }
    String sender = resolveSender(principal);
    String url = fileStorageService.storeFileInSubfolder(file, "chat");
    String text = (message != null && !message.isBlank())
        ? message + "\n🎬 " + url : "🎬 " + url;
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId, "DRIVER", sender, text, DriverChatMessageType.VIDEO));
  }

  @PostMapping("/{driverId}/send-location")
  @Operation(summary = "Send driver location to support")
  public ResponseEntity<DriverChatMessage> sendLocation(
      @PathVariable Long driverId,
      @RequestBody SendLocationRequest request,
      Principal principal) {
    String sender = resolveSender(principal);
    String text = "📍 " + request.lat() + "," + request.lng() + "|" + request.address();
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(
            driverId, "DRIVER", sender, text, DriverChatMessageType.LOCATION));
  }

  @PostMapping("/mark-read/{messageId}")
  @Operation(summary = "Mark a message as read")
  public ResponseEntity<DriverChatMessage> markRead(@PathVariable Long messageId) {
    return ResponseEntity.ok(chatMessageService.markAsRead(messageId));
  }

  // ─── Admin-send endpoint ────────────────────────────────────────────────

  @PostMapping("/{driverId}/admin/send")
  @Operation(summary = "Send a message as admin/support to driver")
  public ResponseEntity<DriverChatMessage> sendFromAdmin(
      @PathVariable Long driverId,
      @RequestBody SendMessageRequest request,
      Principal principal) {
    String sender = resolveSender(principal);
    return ResponseEntity.ok(
        chatMessageService.sendMessageToDriver(driverId, "ADMIN", sender, request.message()));
  }

  // ─── Typing indicator ────────────────────────────────────────────────────

  @PostMapping("/{driverId}/typing")
  @Operation(summary = "Broadcast typing indicator (ephemeral — no DB write)")
  public ResponseEntity<Void> typing(
      @PathVariable Long driverId, Principal principal) {
    String senderRole = "DRIVER"; // for driver-side; admin uses admin controller
    chatMessageService.broadcastTyping(driverId, senderRole);
    return ResponseEntity.ok().build();
  }

  // ─── Call signalling endpoints ───────────────────────────────────────────

  /**
   * Driver or admin requests a call.
   * Creates a [CallSession], generates Agora token, and broadcasts CALL_REQUEST.
   * Returns {appId, agoraToken, channelName, uid, sessionId}.
   */
  @PostMapping("/{driverId}/start-call")
  @Operation(summary = "Start a call (driver-initiated)")
  public ResponseEntity<CallTokenResponse> startCall(
      @PathVariable Long driverId, Principal principal) {
    String sender = resolveSender(principal);
    CallTokenResponse resp = chatMessageService.createCallSession(driverId, "DRIVER", sender);
    return ResponseEntity.ok(resp);
  }

  /** Alias kept for backwards compatibility. */
  @PostMapping("/{driverId}/call-request")
  @Operation(summary = "Request a support call (alias of start-call)")
  public ResponseEntity<CallTokenResponse> callRequestAlias(
      @PathVariable Long driverId, Principal principal) {
    return startCall(driverId, principal);
  }

  /**
   * Driver accepts an incoming admin call.
   * Transitions session → ACTIVE, returns Agora token.
   */
  @PostMapping("/{driverId}/accept-call")
  @Operation(summary = "Driver accepts an incoming call")
  public ResponseEntity<CallTokenResponse> acceptCall(
      @PathVariable Long driverId, Principal principal) {
    String sender = resolveSender(principal);
    CallTokenResponse resp = chatMessageService.acceptCallSession(driverId, "DRIVER", sender);
    return ResponseEntity.ok(resp);
  }

  /**
   * Fetch a fresh Agora token for the driver's current active call session.
   * Called by the driver app after receiving CALL_REQUEST via STOMP.
   */
  @PostMapping("/{driverId}/call-token")
  @Operation(summary = "Get Agora token for active call session")
  public ResponseEntity<CallTokenResponse> getCallToken(
      @PathVariable Long driverId, Principal principal) {
    try {
      CallTokenResponse resp = chatMessageService.fetchTokenForActiveSession(driverId);
      return ResponseEntity.ok(resp);
    } catch (IllegalStateException e) {
      // No active session → create one on demand (e.g. driver-initiated call).
      String sender = resolveSender(principal);
      CallTokenResponse resp = chatMessageService.createCallSession(driverId, "DRIVER", sender);
      return ResponseEntity.ok(resp);
    }
  }

  /**
   * Either party ended the call. Transitions session → ENDED.
   */
  @PostMapping("/{driverId}/end-call")
  @Operation(summary = "End an active call")
  public ResponseEntity<Map<String, String>> endCall(
      @PathVariable Long driverId, Principal principal) {
    String sender = resolveSender(principal);
    chatMessageService.endCallSession(driverId, "DRIVER", sender);
    return ResponseEntity.ok(Map.of("status", "ENDED"));
  }

  /**
   * Driver declined an incoming call. Transitions session → DECLINED.
   */
  @PostMapping("/{driverId}/decline-call")
  @Operation(summary = "Driver declines an incoming call")
  public ResponseEntity<Map<String, String>> declineCall(
      @PathVariable Long driverId, Principal principal) {
    String sender = resolveSender(principal);
    chatMessageService.declineCallSession(driverId, "DRIVER", sender);
    return ResponseEntity.ok(Map.of("status", "DECLINED"));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  private String resolveSender(Principal principal) {
    return principal != null ? principal.getName() : "unknown";
  }

  // ─── Request records ─────────────────────────────────────────────────────

  public record SendMessageRequest(String message) {}
  public record SendLocationRequest(double lat, double lng, String address) {}
}
