package com.svtrucking.logistics.service;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Random;
import java.util.zip.DeflaterOutputStream;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Generates Agora RTC AccessToken2 (version "007") for driver voice/video calls.
 *
 * <p>Algorithm:
 * <ol>
 *   <li>Build the RTC service payload (channelName + uid + privilege expire timestamps).</li>
 *   <li>Sign with HMAC-SHA256 using appCertificate.</li>
 *   <li>Compress (zlib deflate) the signed content.</li>
 *   <li>Base64-encode and prepend the appId to produce the final token string.</li>
 * </ol>
 *
 * <p>Reference: https://github.com/AgoraIO/Tools/tree/master/DynamicKey/AgoraDynamicKey/java
 */
@Service
@Slf4j
public class AgoraTokenService {

  // ─── Service type constants ──────────────────────────────────────────────

  private static final short SERVICE_TYPE_RTC = 1;
  private static final short PRIVILEGE_JOIN_CHANNEL = 1;
  private static final short PRIVILEGE_PUBLISH_AUDIO_STREAM = 2;
  private static final short PRIVILEGE_PUBLISH_VIDEO_STREAM = 3;
  private static final short PRIVILEGE_PUBLISH_DATA_STREAM = 4;
  private static final short PRIVILEGE_SUBSCRIBE_AUDIO_STREAM = 5;
  private static final short PRIVILEGE_SUBSCRIBE_VIDEO_STREAM = 6;
  private static final short PRIVILEGE_SUBSCRIBE_DATA_STREAM = 7;
  private static final String TOKEN_VERSION = "007";

  // ─── Config ──────────────────────────────────────────────────────────────

  @Value("${agora.app-id:REPLACE_WITH_YOUR_AGORA_APP_ID}")
  private String appId;

  @Value("${agora.app-certificate:REPLACE_WITH_YOUR_AGORA_APP_CERTIFICATE}")
  private String appCertificate;

  @Value("${agora.token.expire-seconds:3600}")
  private int tokenExpireSeconds;

  @PostConstruct
  void validate() {
    if (appId.startsWith("REPLACE") || appCertificate.startsWith("REPLACE")) {
      log.warn("[Agora] agora.app-id / agora.app-certificate are not configured. "
          + "Set them in application.properties or environment variables.");
    }
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  public String getAppId() {
    return appId;
  }

  /**
   * Generate a voice/video call token for the given channel.
   *
   * @param channelName Agora channel name (must match on both sides)
   * @param uid         Driver UID — 0 means Agora assigns one automatically
   * @return AccessToken2 string starting with "007{appId}..."
   */
  public String generateRtcToken(String channelName, int uid) {
    return generateRtcToken(channelName, uid, tokenExpireSeconds);
  }

  /**
   * Generate a token with an explicit expiry window.
   */
  public String generateRtcToken(String channelName, int uid, int expireSeconds) {
    try {
      final int now = (int) (System.currentTimeMillis() / 1000);
      final int tokenExpire = now + expireSeconds;
      final int privilegeExpire = now + expireSeconds;
      final int salt = new Random().nextInt(Integer.MAX_VALUE);

      // 1. Build service payload (no signature yet).
      byte[] servicePayload = buildRtcServicePayload(
          channelName, uid, privilegeExpire);

      // 2. Build the content-to-sign:
      //    appId (raw bytes) + tokenExpire(uint32) + salt(uint32) + now(uint32) + servicePayload
      byte[] toSign = buildSigningContent(appId, tokenExpire, salt, now, servicePayload);

      // 3. HMAC-SHA256 signature.
      byte[] sig = hmacSha256(appCertificate.getBytes(), toSign);

      // 4. Build the full packed token content:
      //    sig_length(uint16) + sig + tokenExpire(uint32) + salt(uint32) + now(uint32) + servicePayload
      byte[] tokenContent = buildTokenContent(sig, tokenExpire, salt, now, servicePayload);

      // 5. Zlib-compress.
      byte[] compressed = zlibCompress(tokenContent);

      // 6. Base64-encode.
      String encoded = Base64.getEncoder().encodeToString(compressed);

      return TOKEN_VERSION + appId + encoded;

    } catch (Exception e) {
      log.error("[Agora] Token generation failed: {}", e.getMessage(), e);
      throw new RuntimeException("Failed to generate Agora RTC token", e);
    }
  }

  // ─── Internal builders ───────────────────────────────────────────────────

  /**
   * Packs the RTC service section:
   *   serviceType(uint16) + channelName_len(uint16) + channelName
   *   + uid_str_len(uint16) + uid_str
   *   + num_privileges(uint16) + [privilegeType(uint16) + expire(uint32)] ...
   */
  private byte[] buildRtcServicePayload(String channelName, int uid,
      int privilegeExpire) throws IOException {
    String uidStr = uid == 0 ? "" : String.valueOf(uid);

    // Privileges granted: join + publish audio/video + subscribe audio/video
    short[][] privileges = {
        {PRIVILEGE_JOIN_CHANNEL,            (short) privilegeExpire},
        {PRIVILEGE_PUBLISH_AUDIO_STREAM,    (short) privilegeExpire},
        {PRIVILEGE_PUBLISH_VIDEO_STREAM,    (short) privilegeExpire},
        {PRIVILEGE_PUBLISH_DATA_STREAM,     (short) privilegeExpire},
        {PRIVILEGE_SUBSCRIBE_AUDIO_STREAM,  (short) privilegeExpire},
        {PRIVILEGE_SUBSCRIBE_VIDEO_STREAM,  (short) privilegeExpire},
        {PRIVILEGE_SUBSCRIBE_DATA_STREAM,   (short) privilegeExpire},
    };

    ByteArrayOutputStream out = new ByteArrayOutputStream();
    writeUint16(out, SERVICE_TYPE_RTC);
    writeString(out, channelName);
    writeString(out, uidStr);
    writeUint16(out, (short) privileges.length);
    for (short[] p : privileges) {
      writeUint16(out, p[0]);
      writeUint32(out, (int) p[1]);
    }
    return out.toByteArray();
  }

  /**
   * Assembles the content that is signed by HMAC-SHA256.
   * Format: appId_bytes + tokenExpire(uint32) + salt(uint32) + ts(uint32) + servicePayload
   */
  private byte[] buildSigningContent(String appId, int tokenExpire, int salt,
      int ts, byte[] servicePayload) throws IOException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    out.write(appId.getBytes());
    writeUint32(out, tokenExpire);
    writeUint32(out, salt);
    writeUint32(out, ts);
    out.write(servicePayload);
    return out.toByteArray();
  }

  /**
   * Assembles the full token body (before compression):
   * sig_len(uint16) + sig + tokenExpire(uint32) + salt(uint32) + ts(uint32) + servicePayload
   */
  private byte[] buildTokenContent(byte[] sig, int tokenExpire, int salt,
      int ts, byte[] servicePayload) throws IOException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    writeBytes(out, sig);          // uint16 length-prefixed sig
    writeUint32(out, tokenExpire);
    writeUint32(out, salt);
    writeUint32(out, ts);
    out.write(servicePayload);
    return out.toByteArray();
  }

  // ─── Byte-level helpers ──────────────────────────────────────────────────

  private void writeUint16(ByteArrayOutputStream out, short value)
      throws IOException {
    ByteBuffer buf = ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN);
    buf.putShort(value);
    out.write(buf.array());
  }

  private void writeUint32(ByteArrayOutputStream out, int value)
      throws IOException {
    ByteBuffer buf = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN);
    buf.putInt(value);
    out.write(buf.array());
  }

  /** Write a length-prefixed (uint16) byte array. */
  private void writeBytes(ByteArrayOutputStream out, byte[] bytes)
      throws IOException {
    writeUint16(out, (short) bytes.length);
    out.write(bytes);
  }

  /** Write a length-prefixed (uint16) UTF-8 string. */
  private void writeString(ByteArrayOutputStream out, String s)
      throws IOException {
    writeBytes(out, s.getBytes());
  }

  private byte[] hmacSha256(byte[] key, byte[] data)
      throws NoSuchAlgorithmException, InvalidKeyException {
    Mac mac = Mac.getInstance("HmacSHA256");
    mac.init(new SecretKeySpec(key, "HmacSHA256"));
    return mac.doFinal(data);
  }

  private byte[] zlibCompress(byte[] data) throws IOException {
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    try (DeflaterOutputStream dos = new DeflaterOutputStream(bos)) {
      dos.write(data);
    }
    return bos.toByteArray();
  }
}
