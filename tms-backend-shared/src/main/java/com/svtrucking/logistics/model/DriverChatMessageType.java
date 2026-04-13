package com.svtrucking.logistics.model;

public enum DriverChatMessageType {
  TEXT,
  IMAGE,
  VOICE,
  VIDEO,
  LOCATION,
  CALL_REQUEST,
  CALL_ACCEPTED,
  /** Driver or admin declined the call before it was answered. */
  CALL_DECLINED,
  CALL_ENDED,
  /** Ephemeral typing indicator — never persisted to the database. */
  TYPING
}
