package com.svtrucking.logistics.exception;

/** Custom exception for handling duplicate license plate errors. */
public class DuplicateLicensePlateException extends RuntimeException {
  public DuplicateLicensePlateException(String message) {
    super(message);
  }
}
