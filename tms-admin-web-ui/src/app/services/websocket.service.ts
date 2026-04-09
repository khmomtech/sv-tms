import { Injectable } from '@angular/core';
import { Client, type IMessage, type StompConfig } from '@stomp/stompjs';
import { BehaviorSubject, type Observable, Subject } from 'rxjs';
import SockJS from 'sockjs-client';

import { environment } from '../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

type WS = WebSocket;

export interface WebSocketMessage<T = any> {
  type: string;
  payload: T;
  timestamp: number;
}

export interface DriverLocationUpdate {
  driverId: number;
  latitude: number;
  longitude: number;
  heading: number;
  speed: number;
  accuracy: number;
  timestamp: string;
}

export interface VehicleStatusUpdate {
  vehicleId: number;
  status: string;
  location?: {
    latitude: number;
    longitude: number;
  };
  updatedAt: string;
}

@Injectable({ providedIn: 'root' })
export class WebSocketService {
  private socket?: WS;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  // STOMP client for real-time updates
  private stompClient?: Client;
  private connectionState$ = new BehaviorSubject<'CONNECTED' | 'CONNECTING' | 'DISCONNECTED'>(
    'DISCONNECTED',
  );
  private subscriptions = new Map<string, Subject<any>>();

  constructor(private readonly authService: AuthService) {}

  async connect(baseUrl: string, path: string): Promise<void> {
    const token = await this.ensureFreshToken();
    const url = this.buildUrl(baseUrl, path, token);

    this.connectionState$.next('CONNECTING');

    this.socket = new WebSocket(url);

    this.socket.onopen = () => {
      this.reconnectAttempts = 0;
      this.connectionState$.next('CONNECTED');
      // no-op: consumers can attach handlers after connect
    };

    this.socket.onclose = async () => {
      this.connectionState$.next('DISCONNECTED');
      // Attempt refresh and reconnect with backoff
      if (this.reconnectAttempts >= this.maxReconnectAttempts) {
        this.authService.logout();
        return;
      }
      this.reconnectAttempts++;
      const backoffMs = Math.min(30000, 1000 * Math.pow(2, this.reconnectAttempts));
      setTimeout(async () => {
        const fresh = await this.ensureFreshToken();
        const u = this.buildUrl(baseUrl, path, fresh);
        this.socket = new WebSocket(u);
      }, backoffMs);
    };

    this.socket.onerror = async () => {
      // Proactively refresh then let onclose handle reconnection
      await this.authService.refreshToken();
    };
  }

  getSocket(): WS | undefined {
    return this.socket;
  }

  private buildUrl(baseUrl: string, path: string, token: string | null): string {
    const sep = path.startsWith('/') ? '' : '/';
    const t = token ? `?token=${encodeURIComponent(token)}` : '';
    return `${baseUrl}${sep}${path}${t}`.replace('http', 'ws');
  }

  private async ensureFreshToken(): Promise<string | null> {
    const token = this.authService.getToken();
    if (token && !this.authService.isTokenExpired(token)) return token;
    return await this.authService.refreshToken();
  }

  /**
   * Connect to STOMP/WebSocket for real-time updates
   * Uses SockJS for fallback support
   */
  connectStomp(): void {
    if (this.connectionState$.value === 'CONNECTED') {
      console.log('[WebSocket] Already connected');
      return;
    }

    console.log('[WebSocket] Connecting via STOMP...');
    this.connectionState$.next('CONNECTING');

    const token = this.authService.getToken();
    const sockJsPath = token
      ? `${environment.sockJsUrl}?token=${encodeURIComponent(token)}`
      : environment.sockJsUrl;
    const config: StompConfig = {
      webSocketFactory: () => new SockJS(sockJsPath),
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : {},
      debug: (str: string) => {
        if (!environment.production) {
          console.log('[STOMP]', str);
        }
      },
      reconnectDelay: this.calculateReconnectDelay(),
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,

      onConnect: () => {
        console.log('[WebSocket] STOMP connected');
        this.connectionState$.next('CONNECTED');
        this.reconnectAttempts = 0;
        this.resubscribeAll();
      },

      onDisconnect: () => {
        console.log('[WebSocket] STOMP disconnected');
        this.connectionState$.next('DISCONNECTED');
      },

      onStompError: (frame) => {
        console.error('[WebSocket] STOMP error:', frame);
        this.handleStompError();
      },

      onWebSocketError: (event) => {
        console.error('[WebSocket] WebSocket error:', event);
        this.handleStompError();
      },
    };

    this.stompClient = new Client(config);
    this.stompClient.activate();
  }

  private calculateReconnectDelay(): number {
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
    return delay + Math.random() * 1000;
  }

  private handleStompError(): void {
    if (this.reconnectAttempts < 10) {
      this.reconnectAttempts++;
      console.log(`[WebSocket] Will retry (${this.reconnectAttempts}/10)`);
    } else {
      console.error('[WebSocket] Max reconnection attempts reached');
      this.connectionState$.next('DISCONNECTED');
    }
  }

  private resubscribeAll(): void {
    this.subscriptions.forEach((subject, destination) => {
      console.log(`[WebSocket] Resubscribing to ${destination}`);
      this.stompClient?.subscribe(destination, (message: IMessage) => {
        this.handleMessage(destination, message);
      });
    });
  }

  private handleMessage(destination: string, message: IMessage): void {
    try {
      const body = JSON.parse(message.body);
      const subject = this.subscriptions.get(destination);
      if (subject) {
        subject.next(body);
      }
    } catch (error) {
      console.error('[WebSocket] Error parsing message:', error);
    }
  }

  /**
   * Subscribe to a STOMP topic for real-time updates
   */
  subscribe<T = any>(destination: string): Observable<T> {
    if (this.subscriptions.has(destination)) {
      return this.subscriptions.get(destination)!.asObservable();
    }

    const subject = new Subject<T>();
    this.subscriptions.set(destination, subject);

    if (this.connectionState$.value === 'CONNECTED') {
      this.stompClient?.subscribe(destination, (message: IMessage) => {
        this.handleMessage(destination, message);
      });
    }

    return subject.asObservable();
  }

  unsubscribe(destination: string): void {
    const subject = this.subscriptions.get(destination);
    if (subject) {
      subject.complete();
      this.subscriptions.delete(destination);
    }
  }

  send(destination: string, body: any): void {
    if (this.connectionState$.value !== 'CONNECTED') {
      console.warn('[WebSocket] Cannot send - not connected');
      return;
    }
    this.stompClient?.publish({ destination, body: JSON.stringify(body) });
  }

  getConnectionState(): Observable<'CONNECTED' | 'CONNECTING' | 'DISCONNECTED'> {
    return this.connectionState$.asObservable();
  }

  isConnected(): boolean {
    return this.connectionState$.value === 'CONNECTED';
  }

  disconnectStomp(): void {
    if (this.stompClient?.active) {
      console.log('[WebSocket] Disconnecting STOMP...');
      this.stompClient.deactivate();
      this.subscriptions.clear();
    }
  }
}
