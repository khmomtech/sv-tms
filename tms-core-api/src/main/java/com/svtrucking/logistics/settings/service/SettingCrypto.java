package com.svtrucking.logistics.settings.service;

import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class SettingCrypto {
  private static final String ALG = "AES";
  private static final String TRANSFORMATION = "AES/GCM/NoPadding";
  private static final int GCM_TAG_LEN = 128; // bits
  private static final int IV_LEN = 12; // bytes

  private final SecretKeySpec key;
  private final SecureRandom rnd = new SecureRandom();

  public SettingCrypto(@Value("${svtms.settings.cryptoKey:}") String b64Key) {
    if (b64Key == null || b64Key.isBlank()) {
      // WARNING: dev fallback only
      byte[] dev = new byte[32];
      for (int i = 0; i < 32; i++) dev[i] = (byte) i;
      this.key = new SecretKeySpec(dev, ALG);
    } else {
      byte[] raw = Base64.getDecoder().decode(b64Key);
      this.key = new SecretKeySpec(raw, ALG);
    }
  }

  public String encrypt(String plaintext) {
    if (plaintext == null) return null;
    try {
      byte[] iv = new byte[IV_LEN];
      rnd.nextBytes(iv);
      Cipher c = Cipher.getInstance(TRANSFORMATION);
      c.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_LEN, iv));
      byte[] ct = c.doFinal(plaintext.getBytes());
      ByteBuffer buf = ByteBuffer.allocate(IV_LEN + ct.length);
      buf.put(iv).put(ct);
      return Base64.getEncoder().encodeToString(buf.array());
    } catch (Exception e) {
      throw new IllegalStateException("Encrypt failed", e);
    }
  }

  public String decrypt(String encoded) {
    if (encoded == null) return null;
    try {
      byte[] all = Base64.getDecoder().decode(encoded);
      byte[] iv = new byte[IV_LEN];
      byte[] ct = new byte[all.length - IV_LEN];
      System.arraycopy(all, 0, iv, 0, IV_LEN);
      System.arraycopy(all, IV_LEN, ct, 0, ct.length);
      Cipher c = Cipher.getInstance(TRANSFORMATION);
      c.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_LEN, iv));
      return new String(c.doFinal(ct));
    } catch (Exception e) {
      throw new IllegalStateException("Decrypt failed", e);
    }
  }
}
