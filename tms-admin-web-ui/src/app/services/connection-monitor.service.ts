//  connection-monitor.service.ts
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { BehaviorSubject } from 'rxjs';

export type ConnectionStatus = 'connected' | 'disconnected' | 'error';

@Injectable({ providedIn: 'root' })
export class ConnectionMonitorService {
  private readonly connectionStatusSubject = new BehaviorSubject<ConnectionStatus>('disconnected');
  public readonly status$: Observable<ConnectionStatus> =
    this.connectionStatusSubject.asObservable();

  setStatus(status: ConnectionStatus): void {
    if (this.connectionStatusSubject.value === status) {
      return;
    }
    console.log(`[ConnectionMonitor] Status changed to: ${status}`);
    this.connectionStatusSubject.next(status);
  }

  get currentStatus(): ConnectionStatus {
    return this.connectionStatusSubject.value;
  }
}
