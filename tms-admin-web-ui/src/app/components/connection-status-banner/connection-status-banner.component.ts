// 📁 connection-status-banner.component.ts
import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { combineLatest } from 'rxjs';

import type { ConnectionStatus } from '../../services/connection-monitor.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ConnectionMonitorService } from '../../services/connection-monitor.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { SocketService } from '../../services/socket.service';

@Component({
  selector: 'app-connection-status-banner',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './connection-status-banner.component.html',
  styleUrls: ['./connection-status-banner.component.css'],
})
export class ConnectionStatusBannerComponent implements OnInit {
  status: ConnectionStatus = 'disconnected';
  visible = false;

  constructor(
    private monitor: ConnectionMonitorService,
    private socketService: SocketService,
  ) {}

  ngOnInit(): void {
    combineLatest([this.monitor.status$, this.socketService.activeDemand$]).subscribe(
      ([status, hasDemand]) => {
        this.status = status;
        this.visible = hasDemand;
      },
    );
  }

  reconnect(): void {
    this.socketService.reconnect();
  }
}
