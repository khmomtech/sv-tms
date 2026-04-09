package com.svtrucking.logistics.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.repository.DispatchRepository;
import java.io.ByteArrayOutputStream;
import java.util.Map;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DispatchQrService {

  private final DispatchRepository dispatchRepository;
  private final ObjectMapper objectMapper;

  public String buildPayload(Long dispatchId) {
    Dispatch dispatch =
        dispatchRepository
            .findById(dispatchId)
            .orElseThrow(() -> new NoSuchElementException("Dispatch not found: " + dispatchId));
    try {
      return objectMapper.writeValueAsString(Map.of("dispatchId", dispatch.getId()));
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Unable to generate QR payload", e);
    }
  }

  public byte[] buildPng(Long dispatchId, int size) {
    String payload = buildPayload(dispatchId);
    try {
      BitMatrix matrix = new QRCodeWriter().encode(payload, BarcodeFormat.QR_CODE, size, size);
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      MatrixToImageWriter.writeToStream(matrix, "PNG", out);
      return out.toByteArray();
    } catch (WriterException | java.io.IOException e) {
      throw new IllegalStateException("Unable to generate QR code image", e);
    }
  }
}
