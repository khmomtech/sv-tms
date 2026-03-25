import { Injectable } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { MatSnackBar } from '@angular/material/snack-bar';
import type { Observable } from 'rxjs';
import { BehaviorSubject } from 'rxjs';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { SocketService } from './socket.service';

export interface AppNotification {
  title: string;
  message: string;
  receivedAt: Date;
  read: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class NotificationService {
  private notifications: AppNotification[] = [];
  private readonly notificationsSubject = new BehaviorSubject<AppNotification[]>([]);
  public readonly notifications$: Observable<AppNotification[]> =
    this.notificationsSubject.asObservable();

  private readonly realtimeNotificationSubject = new BehaviorSubject<AppNotification | null>(null);
  public readonly realtimeNotification$ = this.realtimeNotificationSubject.asObservable();

  constructor(
    private readonly snackBar: MatSnackBar,
    private readonly socketService: SocketService,
  ) {
    this.listenToWebSocket();
  }

  /**
   *  Listen to WebSocket and push into in-memory notifications list
   */
  private listenToWebSocket(): void {
    this.socketService.notification$.subscribe((notif) => {
      if (notif) {
        const newNotif: AppNotification = {
          title: notif.title,
          message: notif.message,
          receivedAt: new Date(notif.createdAt),
          read: false,
        };

        this.storeNotification(newNotif);
        this.realtimeNotificationSubject.next(newNotif);
        this.showPopup(newNotif.title, newNotif.message);
      }
    });
  }

  /**
   *  Show Angular Material Snackbar
   */
  private showPopup(title: string, message: string): void {
    this.snackBar.open(`${title}: ${message}`, 'OK', {
      duration: 5000,
      horizontalPosition: 'right',
      verticalPosition: 'top',
      panelClass: ['custom-snackbar'],
    });
  }

  success(message: string, title = 'Success'): void {
    this.simulateNotification(title, message);
  }

  info(message: string, title = 'Info'): void {
    this.simulateNotification(title, message);
  }

  warn(message: string, title = 'Warning'): void {
    this.simulateNotification(title, message);
  }

  error(message: string, title = 'Error'): void {
    this.simulateNotification(title, message);
  }

  /**
   *  Save to memory and notify UI
   */
  private storeNotification(notification: AppNotification): void {
    this.notifications.unshift(notification);
    this.notificationsSubject.next([...this.notifications]);
  }

  /**
   *  Manually simulate a notification (e.g., for testing)
   */
  simulateNotification(title: string, message: string): void {
    const newNotification: AppNotification = {
      title,
      message,
      receivedAt: new Date(),
      read: false,
    };

    this.storeNotification(newNotification);
    this.realtimeNotificationSubject.next(newNotification);
    this.showPopup(title, message);
  }

  /**
   *  Mark all as read
   */
  markAllAsRead(): void {
    this.notifications = this.notifications.map((n) => ({ ...n, read: true }));
    this.notificationsSubject.next([...this.notifications]);
  }

  /**
   *  Count of unread notifications
   */
  getUnreadCount(): number {
    return this.notifications.filter((n) => !n.read).length;
  }

  /**
   *  Clear all notifications
   */
  clear(): void {
    this.notifications = [];
    this.notificationsSubject.next([]);
  }
}
