import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

// ─── Domain types ─────────────────────────────────────────────────────────────

export interface DriverChatMessage {
  id: number;
  driverId: number;
  senderRole: string;
  sender?: string;
  message: string;
  messageType?: string;   // TEXT | IMAGE | VOICE | VIDEO | LOCATION | CALL_REQUEST | CALL_ACCEPTED | CALL_DECLINED | CALL_ENDED | TYPING
  createdAt: string;
  read: boolean;
  isPending?: boolean;
  localPreviewUrl?: string | null;
  /** Agora channel name for call-signal messages. */
  agoraChannelName?: string | null;
  /** Backend call session ID for call-signal messages. */
  callSessionId?: number | null;
}

export interface DriverChatConversationSummary {
  driverId: number;
  driverName: string;
  phone?: string | null;
  employeeName?: string | null;
  latestMessage: string;
  latestSenderRole: string;
  latestMessageAt: string;
  unreadDriverMessageCount: number;
  totalMessageCount: number;
  archivedByAdmin?: boolean;
  resolvedByAdmin?: boolean;
}

export interface DriverChatEvent {
  eventType: string;   // MESSAGE_CREATED | MESSAGE_READ | CONVERSATION_READ | TYPING
  driverId: number;
  message?: DriverChatMessage | null;
  conversation?: DriverChatConversationSummary | null;
}

/** Returned by start-call / accept-call / call-token endpoints. */
export interface CallTokenResponse {
  appId: string;
  agoraToken: string;
  channelName: string;
  uid: number;
  sessionId: number;
}

// ─── Service ──────────────────────────────────────────────────────────────────

@Injectable({ providedIn: 'root' })
export class DriverChatService {
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/driver-chat`;

  constructor(private readonly http: HttpClient) {}

  // ─── Conversation & message queries ────────────────────────────────────────

  listConversations(): Observable<DriverChatConversationSummary[]> {
    return this.http.get<DriverChatConversationSummary[]>(
      `${this.baseUrl}/conversations`,
    );
  }

  listMessages(
    driverId: number,
    page = 0,
    pageSize = 30,
  ): Observable<DriverChatMessage[]> {
    const params = new URLSearchParams({
      page: String(page),
      size: String(pageSize),   // Spring @RequestParam name is "size"
    });
    return this.http.get<DriverChatMessage[]>(
      `${this.baseUrl}/${driverId}?${params.toString()}`,
    );
  }

  // ─── Send messages ──────────────────────────────────────────────────────────

  sendMessage(driverId: number, message: string): Observable<DriverChatMessage> {
    return this.http.post<DriverChatMessage>(`${this.baseUrl}/${driverId}/send`, { message });
  }

  uploadPhoto(driverId: number, file: File, message?: string): Observable<DriverChatMessage> {
    const data = new FormData();
    data.append('file', file);
    if (message) data.append('message', message);
    return this.http.post<DriverChatMessage>(`${this.baseUrl}/${driverId}/send-photo`, data);
  }

  sendVoiceMessage(driverId: number, file: File, message?: string): Observable<DriverChatMessage> {
    const data = new FormData();
    data.append('file', file);
    if (message) data.append('message', message);
    return this.http.post<DriverChatMessage>(`${this.baseUrl}/${driverId}/send-voice`, data);
  }

  sendVideoMessage(driverId: number, file: File, message?: string): Observable<DriverChatMessage> {
    const data = new FormData();
    data.append('file', file);
    if (message) data.append('message', message);
    return this.http.post<DriverChatMessage>(`${this.baseUrl}/${driverId}/send-video`, data);
  }

  // ─── Read receipts ──────────────────────────────────────────────────────────

  markConversationRead(driverId: number): Observable<{ driverId: number; updated: number }> {
    return this.http.post<{ driverId: number; updated: number }>(
      `${this.baseUrl}/${driverId}/mark-read`,
      {},
    );
  }

  // ─── Typing indicator ───────────────────────────────────────────────────────

  sendTyping(driverId: number): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${driverId}/typing`, {});
  }

  // ─── Call signalling ────────────────────────────────────────────────────────

  /**
   * Admin initiates a call to a driver.
   * Returns Agora token + channel name so the admin web UI can join the call.
   */
  startCall(driverId: number): Observable<CallTokenResponse> {
    return this.http.post<CallTokenResponse>(
      `${this.baseUrl}/${driverId}/start-call`,
      {},
    );
  }

  /**
   * Admin accepts a driver-initiated call request.
   * Returns Agora token + channel name.
   */
  acceptCall(driverId: number): Observable<CallTokenResponse> {
    return this.http.post<CallTokenResponse>(
      `${this.baseUrl}/${driverId}/accept-call`,
      {},
    );
  }

  /** End the active call (either side). */
  endCall(driverId: number): Observable<{ status: string }> {
    return this.http.post<{ status: string }>(
      `${this.baseUrl}/${driverId}/end-call`,
      {},
    );
  }

  // ─── Archive / resolve ──────────────────────────────────────────────────────

  /** Archive or unarchive a conversation. */
  archiveConversation(driverId: number, archived: boolean): Observable<{ driverId: number; archivedByAdmin: boolean }> {
    return this.http.post<{ driverId: number; archivedByAdmin: boolean }>(
      `${this.baseUrl}/${driverId}/archive?archived=${archived}`,
      {},
    );
  }

  /** Mark a conversation as resolved or re-open it. */
  resolveConversation(driverId: number, resolved: boolean): Observable<{ driverId: number; resolvedByAdmin: boolean }> {
    return this.http.post<{ driverId: number; resolvedByAdmin: boolean }>(
      `${this.baseUrl}/${driverId}/resolve?resolved=${resolved}`,
      {},
    );
  }
}
