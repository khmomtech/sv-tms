import { CommonModule } from '@angular/common';
import { Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import AgoraRTC from 'agora-rtc-sdk-ng';
import type { IAgoraRTCClient, IMicrophoneAudioTrack, IAgoraRTCRemoteUser } from 'agora-rtc-sdk-ng';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { Subscription } from 'rxjs';

import { environment } from '../../../environments/environment';
import { WebSocketService } from '../../../services/websocket.service';
import {
  CallTokenResponse,
  DriverChatConversationSummary,
  DriverChatEvent,
  DriverChatMessage,
  DriverChatService,
} from './driver-chat.service';

// ─── Call state machine ───────────────────────────────────────────────────────

export type CallState =
  | 'idle'
  | 'outgoing'       // admin rang driver, waiting for answer
  | 'incoming'       // driver rang admin, waiting for admin to accept
  | 'connecting'     // Agora join in progress
  | 'connected'      // media flowing
  | 'ended'
  | 'declined'
  | 'error';

@Component({
  selector: 'app-driver-messages',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslateModule],
  templateUrl: './driver-messages.component.html',
  styleUrls: ['./driver-messages.component.css'],
})
export class DriverMessagesComponent implements OnInit, OnDestroy {

  // ─── Conversation list ────────────────────────────────────────────────────
  conversations: DriverChatConversationSummary[] = [];
  filteredConversations: DriverChatConversationSummary[] = [];
  messages: DriverChatMessage[] = [];

  /** Controls which nav section is shown: 'inbox' (active) or 'archived'. */
  activeTab: 'inbox' | 'archived' = 'inbox';

  // ─── UI state ─────────────────────────────────────────────────────────────
  currentVoiceUrl: string | null = null;
  private currentAudio: HTMLAudioElement | null = null;
  isVoicePlaying = false;
  voicePlayPosition = 0;
  selectedConversation: DriverChatConversationSummary | null = null;
  draftMessage = '';
  searchTerm = '';
  isLoadingConversations = false;
  isLoadingMessages = false;
  isSending = false;
  isLoadingMoreMessages = false;
  hasMoreMessages = false;
  messagePage = 0;
  messagePageSize = 30;
  errorMessage = '';
  previewImageUrl: string | null = null;

  // ─── Voice recording ──────────────────────────────────────────────────────
  isRecording = false;
  private mediaRecorder: MediaRecorder | null = null;
  private audioChunks: Blob[] = [];

  // ─── Typing indicator ─────────────────────────────────────────────────────
  isRemoteTyping = false;
  private remoteTypingTimer: ReturnType<typeof setTimeout> | null = null;
  private localTypingTimer: ReturnType<typeof setTimeout> | null = null;
  private lastTypingSentAt = 0;

  // ─── Call state ───────────────────────────────────────────────────────────
  callState: CallState = 'idle';
  callDriverName = '';
  callDurationSec = 0;
  callError = '';
  isMuted = false;
  /** The driverId that is currently in a call / has an incoming call pending. */
  callDriverId: number | null = null;

  // ─── Agora client ─────────────────────────────────────────────────────────
  private agoraClient: IAgoraRTCClient | null = null;
  private localAudioTrack: IMicrophoneAudioTrack | null = null;
  private callDurationTimer: ReturnType<typeof setInterval> | null = null;
  private ringTimeoutTimer: ReturnType<typeof setTimeout> | null = null;
  private readonly RING_TIMEOUT_SEC = 45;

  @ViewChild('fileInput') private fileInputRef!: ElementRef<HTMLInputElement>;
  @ViewChild('threadBody') private threadBodyRef?: ElementRef<HTMLDivElement>;
  private readonly subscriptions = new Subscription();

  // ─── Ringtone ─────────────────────────────────────────────────────────────
  private ringtoneAudio: HTMLAudioElement | null = null;

  // ─── Scroll state for load-more ───────────────────────────────────────────
  private scrollHeightBeforeLoad = 0;

  constructor(
    private readonly chatService: DriverChatService,
    private readonly webSocketService: WebSocketService,
    private readonly route: ActivatedRoute,
    private readonly ngZone: NgZone,
    private readonly translate: TranslateService,
  ) {}

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  ngOnInit(): void {
    this.loadConversations();
    this.webSocketService.connectStomp();
    this.subscriptions.add(
      this.webSocketService
        .subscribe<DriverChatEvent>('/topic/admin-driver-chat')
        .subscribe((event) => this.applyRealtimeEvent(event)),
    );
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    this.cleanupAgoraResources();
    this.clearRingTimeout();
    this.clearCallDurationTimer();
    if (this.remoteTypingTimer) clearTimeout(this.remoteTypingTimer);
    if (this.localTypingTimer) clearTimeout(this.localTypingTimer);
  }

  // ─── Conversation list ────────────────────────────────────────────────────

  loadConversations(): void {
    this.isLoadingConversations = true;
    this.errorMessage = '';
    this.chatService.listConversations().subscribe({
      next: (conversations) => {
        this.conversations = conversations;
        this.applySearch();
        this.restoreSelection();
        this.isLoadingConversations = false;
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || 'Failed to load driver conversations.';
        this.isLoadingConversations = false;
      },
    });
  }

  selectConversation(conversation: DriverChatConversationSummary): void {
    this.selectedConversation = conversation;
    this.messagePage = 0;
    this.hasMoreMessages = false;
    this.isRemoteTyping = false;
    this.loadMessages(conversation.driverId, true, 0);
  }

  loadMoreMessages(): void {
    if (!this.selectedConversation || !this.hasMoreMessages || this.isLoadingMoreMessages) return;
    // Capture scroll height before prepending so we can restore position after.
    const el = this.threadBodyRef?.nativeElement;
    this.scrollHeightBeforeLoad = el?.scrollHeight ?? 0;
    this.loadMessages(this.selectedConversation.driverId, false, this.messagePage + 1);
  }

  loadMessages(driverId: number, markRead = false, page = 0): void {
    if (page === 0) {
      this.messages = [];
      this.hasMoreMessages = false;
      this.messagePage = 0;
    }
    this.isLoadingMessages = page === 0;
    this.isLoadingMoreMessages = page > 0;
    this.errorMessage = '';

    this.chatService.listMessages(driverId, page, this.messagePageSize).subscribe({
      next: (messages) => {
        const sorted = [...messages].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
        if (page === 0) {
          this.messages = sorted;
          // Scroll to bottom after initial load renders.
          setTimeout(() => this.scrollToBottom(), 0);
        } else {
          const prevHeight = this.scrollHeightBeforeLoad;
          this.messages = [...sorted, ...this.messages];
          // Restore scroll position so the view doesn't jump to top.
          setTimeout(() => {
            const scrollEl = this.threadBodyRef?.nativeElement;
            if (scrollEl && prevHeight) {
              scrollEl.scrollTop = scrollEl.scrollHeight - prevHeight;
            }
            this.scrollHeightBeforeLoad = 0;
          }, 0);
        }
        this.messagePage = page;
        this.hasMoreMessages = messages.length === this.messagePageSize;
        this.isLoadingMessages = false;
        this.isLoadingMoreMessages = false;
        if (markRead) this.markConversationRead(driverId);
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || 'Failed to load conversation.';
        this.isLoadingMessages = false;
        this.isLoadingMoreMessages = false;
        this.scrollHeightBeforeLoad = 0;
      },
    });
  }

  // ─── Sending messages ─────────────────────────────────────────────────────

  sendMessage(): void {
    const message = this.draftMessage.trim();
    if (!this.selectedConversation || !message || this.isSending) return;

    this.isSending = true;
    this.errorMessage = '';
    const optimistic = this.createOptimisticMessage(this.selectedConversation.driverId, message);
    this.upsertMessage(optimistic);
    this.upsertConversationSummaryFromMessage(optimistic);
    this.draftMessage = '';

    this.chatService.sendMessage(this.selectedConversation.driverId, message).subscribe({
      next: (created) => {
        this.replacePendingMessage(optimistic.id, created);
        this.upsertConversationSummaryFromMessage(created);
        this.isSending = false;
      },
      error: (error) => {
        this.messages = this.messages.filter((item) => item.id !== optimistic.id);
        this.errorMessage = error?.error?.message || 'Failed to send message.';
        this.draftMessage = message;
        this.isSending = false;
      },
    });
  }

  triggerFileSelect(): void {
    this.errorMessage = '';
    this.fileInputRef?.nativeElement?.click();
  }

  handleFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file || !this.selectedConversation) return;

    if (file.type.startsWith('audio/')) {
      this.sendVoiceFile(file);
    } else if (file.type.startsWith('video/')) {
      this.sendVideoFile(file);
    } else {
      this.isSending = true;
      this.chatService
        .uploadPhoto(this.selectedConversation.driverId, file, this.draftMessage.trim())
        .subscribe({
          next: (created) => {
            this.upsertMessage(created);
            this.upsertConversationSummaryFromMessage(created);
            this.draftMessage = '';
            this.isSending = false;
          },
          error: (error) => {
            this.errorMessage = error?.error?.message || 'Failed to send attachment.';
            this.isSending = false;
          },
        });
    }
    input.value = '';
  }

  sendVideoFile(file: File): void {
    if (!this.selectedConversation || this.isSending) return;
    this.isSending = true;
    this.errorMessage = '';
    this.chatService.sendVideoMessage(this.selectedConversation.driverId, file).subscribe({
      next: (created) => {
        this.upsertMessage(created);
        this.upsertConversationSummaryFromMessage(created);
        this.isSending = false;
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || 'Failed to send video.';
        this.isSending = false;
      },
    });
  }

  sendVoiceFile(file: File): void {
    if (!this.selectedConversation || this.isSending) return;
    this.isSending = true;
    this.errorMessage = '';
    this.chatService.sendVoiceMessage(this.selectedConversation.driverId, file).subscribe({
      next: (created) => {
        this.upsertMessage(created);
        this.upsertConversationSummaryFromMessage(created);
        this.isSending = false;
      },
      error: (error) => {
        this.errorMessage = error?.error?.message || 'Failed to send voice message.';
        this.isSending = false;
      },
    });
  }

  markConversationRead(driverId: number): void {
    this.chatService.markConversationRead(driverId).subscribe({
      next: () => {
        const target = this.conversations.find((item) => item.driverId === driverId);
        if (target) {
          target.unreadDriverMessageCount = 0;
          this.applySearch();
        }
      },
    });
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────

  /** Called from the textarea (input) event. Debounces to avoid flooding. */
  onLocalTyping(): void {
    if (!this.selectedConversation) return;
    const now = Date.now();
    if (now - this.lastTypingSentAt < 2500) return;   // throttle to once per 2.5s
    this.lastTypingSentAt = now;
    this.chatService.sendTyping(this.selectedConversation.driverId).subscribe();
  }

  // ─── Call initiation (admin → driver) ─────────────────────────────────────

  callDriver(): void {
    if (!this.selectedConversation) return;
    if (this.callState !== 'idle') return;

    this.callDriverId = this.selectedConversation.driverId;
    this.callDriverName = this.selectedConversation.driverName;
    this.callState = 'outgoing';
    this.callError = '';

    this.chatService.startCall(this.selectedConversation.driverId).subscribe({
      next: (resp) => this.onCallTokenReceived(resp, 'outgoing'),
      error: (error) => {
        this.callError = error?.error?.message || 'Failed to start call.';
        this.transitionCallState('error');
      },
    });

    // 45s ring timeout — driver might not answer
    this.startRingTimeout();
  }

  // ─── Call acceptance (admin accepts driver-initiated CALL_REQUEST) ─────────

  acceptIncomingCall(): void {
    if (this.callState !== 'incoming' || !this.callDriverId) return;
    this.clearRingTimeout();
    this.stopRingtone();
    this.callState = 'connecting';

    this.chatService.acceptCall(this.callDriverId).subscribe({
      next: (resp) => this.onCallTokenReceived(resp, 'incoming'),
      error: (error) => {
        this.callError = error?.error?.message || 'Failed to accept call.';
        this.transitionCallState('error');
      },
    });
  }

  declineIncomingCall(): void {
    if (this.callState !== 'incoming' || !this.callDriverId) return;
    this.clearRingTimeout();
    this.chatService.endCall(this.callDriverId).subscribe();
    this.transitionCallState('declined');
  }

  // ─── End / hang up ────────────────────────────────────────────────────────

  endCallSession(): void {
    const driverId = this.callDriverId;
    this.cleanupAgoraResources();
    this.clearRingTimeout();
    this.clearCallDurationTimer();

    if (driverId) {
      this.chatService.endCall(driverId).subscribe();
    }
    this.transitionCallState('ended');
  }

  // ─── Mute toggle ──────────────────────────────────────────────────────────

  toggleMute(): void {
    if (!this.localAudioTrack) return;
    this.isMuted = !this.isMuted;
    this.localAudioTrack.setEnabled(!this.isMuted);
  }

  // ─── Legacy accept from call-request message banner ───────────────────────

  acceptCall(driverId: number): void {
    if (this.callState !== 'idle' && this.callState !== 'incoming') return;
    const conv = this.conversations.find((c) => c.driverId === driverId);
    this.callDriverId = driverId;
    this.callDriverName = conv?.driverName ?? `Driver #${driverId}`;
    this.callState = 'connecting';
    this.callError = '';

    this.chatService.acceptCall(driverId).subscribe({
      next: (resp) => this.onCallTokenReceived(resp, 'incoming'),
      error: (error) => {
        this.callError = error?.error?.message || 'Failed to accept call.';
        this.transitionCallState('error');
      },
    });
  }

  // ─── Agora helpers ────────────────────────────────────────────────────────

  private async onCallTokenReceived(resp: CallTokenResponse, direction: 'outgoing' | 'incoming'): Promise<void> {
    this.callState = 'connecting';
    try {
      this.agoraClient = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

      // Subscribe to remote user events
      this.agoraClient.on('user-published', async (user: IAgoraRTCRemoteUser, mediaType: 'audio' | 'video') => {
        await this.agoraClient!.subscribe(user, mediaType);
        if (mediaType === 'audio') {
          user.audioTrack?.play();
          this.transitionCallState('connected');
        }
      });

      // user-left fires when the remote participant actually disconnects/hangs up.
      // user-unpublished only means they stopped publishing a track (e.g. muted) — do NOT hang up on that.
      this.agoraClient.on('user-left', (_user: IAgoraRTCRemoteUser) => {
        if (this.callState === 'connected' || this.callState === 'outgoing') {
          this.cleanupAgoraResources();
          this.transitionCallState('ended');
        }
      });

      this.agoraClient.on('connection-state-change', (curState: string) => {
        if (curState === 'DISCONNECTED' && this.callState === 'connected') {
          this.callError = 'Connection lost.';
          this.transitionCallState('error');
        }
      });

      await this.agoraClient.join(resp.appId, resp.channelName, resp.agoraToken, resp.uid);
      this.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
      await this.agoraClient.publish([this.localAudioTrack]);
      this.isMuted = false;

      // If outgoing, we are connected immediately (admin joined first, driver joins later)
      // If incoming, remote user is already there; 'user-published' will fire
      if (direction === 'outgoing') {
        this.transitionCallState('outgoing');   // stay in outgoing until driver joins
      }
    } catch (err) {
      console.error('[Agora] join failed', err);
      this.callError = 'Could not join call channel. Please try again.';
      this.transitionCallState('error');
    }
  }

  private transitionCallState(next: CallState): void {
    this.callState = next;
    if (next === 'connected') {
      this.stopRingtone();
      this.startCallDurationTimer();
      this.clearRingTimeout();
    }
    if (next === 'ended' || next === 'declined' || next === 'error') {
      this.stopRingtone();
      this.clearCallDurationTimer();
      this.clearRingTimeout();
      // Auto-dismiss overlay after 3 s
      setTimeout(() => {
        if (this.callState === next) {
          this.callState = 'idle';
          this.callDriverId = null;
          this.callDriverName = '';
          this.callDurationSec = 0;
          this.callError = '';
          this.isMuted = false;
        }
      }, 3000);
    }
  }

  private async cleanupAgoraResources(): Promise<void> {
    try {
      if (this.localAudioTrack) {
        this.localAudioTrack.stop();
        this.localAudioTrack.close();
        this.localAudioTrack = null;
      }
      if (this.agoraClient) {
        await this.agoraClient.leave();
        this.agoraClient = null;
      }
    } catch {
      // Ignore teardown errors
    }
  }

  private startCallDurationTimer(): void {
    this.callDurationSec = 0;
    this.callDurationTimer = setInterval(() => {
      this.callDurationSec++;
    }, 1000);
  }

  private clearCallDurationTimer(): void {
    if (this.callDurationTimer) {
      clearInterval(this.callDurationTimer);
      this.callDurationTimer = null;
    }
  }

  private startRingTimeout(): void {
    this.clearRingTimeout();
    this.ringTimeoutTimer = setTimeout(() => {
      if (this.callState === 'outgoing' || this.callState === 'incoming') {
        this.callError = 'No answer.';
        this.endCallSession();
      }
    }, this.RING_TIMEOUT_SEC * 1000);
  }

  private clearRingTimeout(): void {
    if (this.ringTimeoutTimer) {
      clearTimeout(this.ringTimeoutTimer);
      this.ringTimeoutTimer = null;
    }
  }

  // ─── Format call duration ─────────────────────────────────────────────────

  get inboxCount(): number {
    return this.conversations.filter((c) => !c.archivedByAdmin).length;
  }

  get archivedCount(): number {
    return this.conversations.filter((c) => c.archivedByAdmin === true).length;
  }

  get callDurationFormatted(): string {
    const m = Math.floor(this.callDurationSec / 60);
    const s = this.callDurationSec % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  get callStatusLabel(): string {
    switch (this.callState) {
      case 'outgoing':    return this.translate.instant('chat.call.ringing');
      case 'incoming':    return this.translate.instant('chat.call.incoming');
      case 'connecting':  return this.translate.instant('chat.call.connecting');
      case 'connected':   return this.callDurationFormatted;
      case 'ended':       return this.translate.instant('chat.call.call_ended');
      case 'declined':    return this.translate.instant('chat.call.call_declined');
      case 'error':       return this.callError || this.translate.instant('chat.call.error');
      default:            return '';
    }
  }

  // ─── STOMP realtime event handler ────────────────────────────────────────

  private applyRealtimeEvent(event: DriverChatEvent): void {
    if (!event?.driverId) return;

    // ── Typing ──────────────────────────────────────────────────────────────
    if (event.eventType === 'TYPING') {
      if (this.selectedConversation?.driverId === event.driverId) {
        this.isRemoteTyping = true;
        if (this.remoteTypingTimer) clearTimeout(this.remoteTypingTimer);
        this.remoteTypingTimer = setTimeout(() => { this.isRemoteTyping = false; }, 4000);
      }
      return;
    }

    // ── Conversation summary update ──────────────────────────────────────────
    if (event.conversation) {
      this.upsertConversation(event.conversation);
    } else {
      const existing = this.conversations.find((item) => item.driverId === event.driverId);
      if (existing && event.message) {
        existing.latestMessage = event.message.message;
        existing.latestSenderRole = event.message.senderRole;
        existing.latestMessageAt = event.message.createdAt;
      }
    }

    if (!event.message) return;

    const msgType = event.message.messageType?.toUpperCase();

    // ── Call signal routing ──────────────────────────────────────────────────
    if (msgType === 'CALL_REQUEST' && event.message.senderRole?.toUpperCase() === 'DRIVER') {
      // Driver is calling us
      if (this.callState === 'idle') {
        const conv = this.conversations.find((c) => c.driverId === event.driverId);
        this.callDriverId = event.driverId;
        this.callDriverName = conv?.driverName ?? `Driver #${event.driverId}`;
        this.callState = 'incoming';
        this.startRingTimeout();
        this.startRingtone();
      }
    }

    if (msgType === 'CALL_ACCEPTED' && event.driverId === this.callDriverId) {
      // Driver accepted our outgoing call — transition to connected
      if (this.callState === 'outgoing') {
        this.transitionCallState('connected');
      }
    }

    if (msgType === 'CALL_DECLINED' && event.driverId === this.callDriverId) {
      if (this.callState === 'outgoing') {
        this.cleanupAgoraResources();
        this.callError = 'Driver declined the call.';
        this.transitionCallState('declined');
      }
    }

    if (msgType === 'CALL_ENDED' && event.driverId === this.callDriverId) {
      if (this.callState === 'connected' || this.callState === 'outgoing') {
        this.cleanupAgoraResources();
        this.transitionCallState('ended');
      }
    }

    // ── Message thread update ────────────────────────────────────────────────
    if (this.selectedConversation?.driverId === event.driverId) {
      // Don't add ephemeral TYPING messages to thread
      if (msgType !== 'TYPING') {
        this.upsertMessage(event.message);
      }

      if (event.message.senderRole?.toUpperCase() === 'DRIVER' && msgType === 'TEXT') {
        this.playSound('/assets/audio/notification.wav');
      }

      if (event.message.senderRole?.toUpperCase() === 'DRIVER' && msgType === 'TEXT') {
        this.markConversationRead(event.driverId);
      }
    }
  }

  // ─── Search / filter ─────────────────────────────────────────────────────

  applySearch(): void {
    const query = this.searchTerm.trim().toLowerCase();
    // First filter by active tab (inbox vs archived)
    const tabFiltered = this.conversations.filter((c) =>
      this.activeTab === 'archived' ? c.archivedByAdmin === true : !c.archivedByAdmin,
    );
    if (!query) {
      this.filteredConversations = tabFiltered;
      return;
    }
    this.filteredConversations = tabFiltered.filter((conversation) =>
      [
        conversation.driverName,
        conversation.phone,
        conversation.employeeName,
        conversation.latestMessage,
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query)),
    );
  }

  switchTab(tab: 'inbox' | 'archived'): void {
    this.activeTab = tab;
    this.selectedConversation = null;
    this.messages = [];
    this.applySearch();
  }

  archiveConversation(driverId: number, archive: boolean): void {
    this.chatService.archiveConversation(driverId, archive).subscribe({
      next: () => {
        const conv = this.conversations.find((c) => c.driverId === driverId);
        if (conv) {
          conv.archivedByAdmin = archive;
          // If we archived the currently selected conversation, deselect it.
          if (archive && this.selectedConversation?.driverId === driverId) {
            this.selectedConversation = null;
            this.messages = [];
          }
        }
        this.applySearch();
      },
      error: () => {
        // Non-fatal: just show nothing — don't crash
      },
    });
  }

  resolveConversation(driverId: number, resolved: boolean): void {
    this.chatService.resolveConversation(driverId, resolved).subscribe({
      next: () => {
        const conv = this.conversations.find((c) => c.driverId === driverId);
        if (conv) conv.resolvedByAdmin = resolved;
        this.applySearch();
      },
      error: () => {
        // Non-fatal
      },
    });
  }

  // ─── Message type helpers ─────────────────────────────────────────────────

  isCallSignalMessage(message: DriverChatMessage): boolean {
    const type = message.messageType?.toUpperCase();
    return (
      type === 'CALL_REQUEST' ||
      type === 'CALL_ACCEPTED' ||
      type === 'CALL_DECLINED' ||
      type === 'CALL_ENDED'
    );
  }

  callSignalLabel(message: DriverChatMessage): string {
    switch (message.messageType?.toUpperCase()) {
      case 'CALL_REQUEST':  return this.translate.instant('chat.message.call_request');
      case 'CALL_ACCEPTED': return this.translate.instant('chat.message.call_accepted');
      case 'CALL_DECLINED': return this.translate.instant('chat.message.call_declined');
      case 'CALL_ENDED':    return this.translate.instant('chat.message.call_ended');
      default:              return '📞';
    }
  }

  callSignalClass(message: DriverChatMessage): string {
    switch (message.messageType?.toUpperCase()) {
      case 'CALL_REQUEST':  return 'call-signal request';
      case 'CALL_ACCEPTED': return 'call-signal accepted';
      case 'CALL_DECLINED': return 'call-signal declined';
      case 'CALL_ENDED':    return 'call-signal ended';
      default:              return 'call-signal';
    }
  }

  /** True if the message is an incoming call request from the driver. */
  isIncomingCallRequest(message: DriverChatMessage): boolean {
    return (
      message.messageType?.toUpperCase() === 'CALL_REQUEST' &&
      message.senderRole?.toUpperCase() === 'DRIVER'
    );
  }

  // ─── Track helpers ────────────────────────────────────────────────────────

  trackConversation(_: number, conversation: DriverChatConversationSummary): number {
    return conversation.driverId;
  }

  trackMessage(_: number, message: DriverChatMessage): number {
    return message.id;
  }

  // ─── Conversation list helpers ────────────────────────────────────────────

  hasCallPending(conversation: DriverChatConversationSummary): boolean {
    const message = (conversation.latestMessage || '').toLowerCase();
    return message.includes('📞') || message.includes('call request');
  }

  hasVoiceMessage(conversation: DriverChatConversationSummary): boolean {
    const msg = conversation.latestMessage || '';
    return msg.includes('🔊') || msg.includes('🎬');
  }

  // ─── Formatting helpers ───────────────────────────────────────────────────

  formatTime(value?: string | null): string {
    if (!value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '';
    return new Intl.DateTimeFormat(undefined, {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    }).format(date);
  }

  isAdminMessage(message: DriverChatMessage): boolean {
    return message.senderRole?.toUpperCase() !== 'DRIVER';
  }

  resolveMediaUrl(raw: string | null): string | null {
    if (!raw) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      const base = (environment.apiBaseUrl as string).replace(/\/api\/?$/, '');
      if (base.startsWith('http')) return `${base}${raw}`;
    }
    return raw;
  }

  conversationPreview(text: string): string {
    let t = text || '';
    for (const marker of ['📷 ', '🔊 ', '🎬 ', '📍 ']) {
      const idx = t.indexOf(marker);
      if (idx >= 0) {
        const after = t.indexOf('\n', idx);
        t = (t.slice(0, idx) + (after >= 0 ? t.slice(after) : '')).trim();
      }
    }
    return t || text;
  }

  extractPhotoUrl(message: DriverChatMessage): string | null {
    const marker = '📷 ';
    const index = message.message.indexOf(marker);
    if (index < 0) return null;
    const raw = message.message.slice(index + marker.length);
    const end = raw.indexOf('\n');
    return this.resolveMediaUrl((end >= 0 ? raw.slice(0, end) : raw).trim());
  }

  extractVoiceUrl(message: DriverChatMessage): string | null {
    const marker = '🔊 ';
    const index = message.message.indexOf(marker);
    if (index < 0) return null;
    const raw = message.message.slice(index + marker.length);
    const end = raw.indexOf('\n');
    return this.resolveMediaUrl((end >= 0 ? raw.slice(0, end) : raw).trim());
  }

  extractVideoUrl(message: DriverChatMessage): string | null {
    const marker = '🎬 ';
    const index = message.message.indexOf(marker);
    if (index < 0) return null;
    const raw = message.message.slice(index + marker.length);
    const end = raw.indexOf('\n');
    return this.resolveMediaUrl((end >= 0 ? raw.slice(0, end) : raw).trim());
  }

  extractLocationParts(message: DriverChatMessage): { lat: number; lng: number; address: string } | null {
    const marker = '📍 ';
    const index = message.message.indexOf(marker);
    if (index < 0) return null;
    const raw = message.message.slice(index + marker.length);
    const end = raw.indexOf('\n');
    const segment = (end >= 0 ? raw.slice(0, end) : raw).trim();
    const pipeIdx = segment.indexOf('|');
    if (pipeIdx < 0) return null;
    const coords = segment.slice(0, pipeIdx).trim().split(',');
    const address = segment.slice(pipeIdx + 1).trim();
    if (coords.length < 2) return null;
    return { lat: parseFloat(coords[0]), lng: parseFloat(coords[1]), address };
  }

  openMapsLink(lat: number, lng: number): void {
    window.open(`https://maps.google.com/?q=${lat},${lng}`, '_blank');
  }

  visibleMessageText(message: DriverChatMessage): string {
    if (this.isCallSignalMessage(message)) return '';
    let text = message.message;
    for (const marker of ['📷 ', '🔊 ', '🎬 ', '📍 ']) {
      const idx = text.indexOf(marker);
      if (idx >= 0) {
        const after = text.indexOf('\n', idx);
        text = (text.slice(0, idx) + (after >= 0 ? text.slice(after) : '')).trim();
      }
    }
    return text;
  }

  // ─── Legacy helpers (kept for call-request banner detection) ─────────────

  isCallRequest(message: DriverChatMessage): boolean {
    return message.messageType?.toUpperCase() === 'CALL_REQUEST';
  }

  isVoiceMessage(message: DriverChatMessage): boolean {
    return this.extractVoiceUrl(message) != null;
  }

  // ─── Media playback ───────────────────────────────────────────────────────

  playVoice(voiceUrl: string): void {
    if (this.currentVoiceUrl === voiceUrl && this.currentAudio != null) {
      if (this.isVoicePlaying) {
        this.currentAudio.pause();
        this.isVoicePlaying = false;
      } else {
        this.currentAudio.play().catch(() => {});
        this.isVoicePlaying = true;
      }
      return;
    }
    this.currentAudio?.pause();
    this.currentAudio = new Audio(voiceUrl);
    this.currentVoiceUrl = voiceUrl;
    this.voicePlayPosition = 0;
    this.currentAudio.ontimeupdate = () => {
      const dur = this.currentAudio!.duration;
      this.voicePlayPosition = dur > 0 ? this.currentAudio!.currentTime / dur : 0;
    };
    this.currentAudio.onended = () => {
      this.isVoicePlaying = false;
      this.voicePlayPosition = 0;
      this.currentVoiceUrl = null;
    };
    this.currentAudio.play().catch(() => {});
    this.isVoicePlaying = true;
  }

  openImagePreview(url: string | null): void {
    if (!url) return;
    this.previewImageUrl = url;
  }

  closeImagePreview(): void {
    this.previewImageUrl = null;
  }

  // ─── Voice recording ──────────────────────────────────────────────────────

  async toggleRecording(): Promise<void> {
    if (this.isRecording) {
      this.mediaRecorder?.stop();
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(stream);
      this.mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) this.audioChunks.push(e.data);
      };
      this.mediaRecorder.onstop = () => {
        stream.getTracks().forEach((t) => t.stop());
        const blob = new Blob(this.audioChunks, { type: 'audio/webm' });
        const file = new File([blob], `voice_${Date.now()}.webm`, { type: 'audio/webm' });
        this.sendVoiceFile(file);
        this.isRecording = false;
      };
      this.mediaRecorder.start();
      this.isRecording = true;
    } catch {
      this.errorMessage = 'Microphone access denied.';
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  private playSound(path: string): void {
    try {
      const audio = new Audio(path);
      audio.play().catch(() => {});
    } catch {
      // Ignore in non-browser contexts
    }
  }

  private startRingtone(): void {
    this.stopRingtone();
    try {
      this.ringtoneAudio = new Audio('/assets/audio/ringtone.wav');
      this.ringtoneAudio.loop = true;
      this.ringtoneAudio.play().catch(() => {});
    } catch {
      // Ignore in non-browser contexts
    }
  }

  private stopRingtone(): void {
    if (this.ringtoneAudio) {
      this.ringtoneAudio.pause();
      this.ringtoneAudio.currentTime = 0;
      this.ringtoneAudio = null;
    }
  }

  private scrollToBottom(): void {
    this.ngZone.runOutsideAngular(() => {
      const el = this.threadBodyRef?.nativeElement;
      if (el) el.scrollTop = el.scrollHeight;
    });
  }

  private restoreSelection(): void {
    const requestedDriverId = Number(this.route.snapshot.queryParamMap.get('driverId'));
    const selectedDriverId = this.selectedConversation?.driverId ?? requestedDriverId;
    if (!selectedDriverId) {
      if (!this.selectedConversation && this.filteredConversations.length > 0) {
        this.selectConversation(this.filteredConversations[0]);
      }
      return;
    }
    const match = this.conversations.find((item) => item.driverId === selectedDriverId);
    if (match) {
      this.selectedConversation = match;
      this.loadMessages(match.driverId, true);
    }
  }

  private upsertConversation(conversation: DriverChatConversationSummary): void {
    const index = this.conversations.findIndex((item) => item.driverId === conversation.driverId);
    if (index >= 0) {
      this.conversations[index] = { ...this.conversations[index], ...conversation };
    } else {
      this.conversations.unshift(conversation);
    }
    this.conversations.sort((a, b) => b.latestMessageAt.localeCompare(a.latestMessageAt));
    if (this.selectedConversation?.driverId === conversation.driverId) {
      this.selectedConversation = this.conversations.find(
        (item) => item.driverId === conversation.driverId,
      )!;
    }
    this.applySearch();
  }

  private upsertMessage(message: DriverChatMessage): void {
    const index = this.messages.findIndex((item) => item.id === message.id);
    if (index >= 0) {
      this.messages[index] = message;
    } else {
      this.messages = [...this.messages, message].sort((a, b) =>
        a.createdAt.localeCompare(b.createdAt),
      );
      // Scroll to reveal the new message.
      setTimeout(() => this.scrollToBottom(), 0);
    }
  }

  private replacePendingMessage(pendingId: number, replacement: DriverChatMessage): void {
    const index = this.messages.findIndex((item) => item.id === pendingId);
    if (index >= 0) {
      this.messages[index] = replacement;
      this.messages = [...this.messages].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
      return;
    }
    this.upsertMessage(replacement);
  }

  private createOptimisticMessage(driverId: number, message: string): DriverChatMessage {
    return {
      id: -Date.now(),
      driverId,
      senderRole: 'ADMIN',
      sender: 'Dispatch',
      message,
      createdAt: new Date().toISOString(),
      read: false,
      isPending: true,
      localPreviewUrl: null,
    };
  }

  private upsertConversationSummaryFromMessage(message: DriverChatMessage): void {
    if (!this.selectedConversation) return;
    const conversation: DriverChatConversationSummary = {
      ...this.selectedConversation,
      latestMessage: message.message,
      latestSenderRole: message.senderRole,
      latestMessageAt: message.createdAt,
    };
    this.upsertConversation(conversation);
  }
}
