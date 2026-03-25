/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ToastrService } from 'ngx-toastr';

import {
  RefreshTokenAdminService,
  type RefreshTokenDto,
} from '../../services/refresh-token-admin.service';

@Component({
  standalone: true,
  imports: [CommonModule],
  selector: 'app-token-admin',
  template: `
    <div class="p-4">
      <h2>Refresh Tokens (Admin)</h2>
      <table class="table table-striped" *ngIf="tokens?.length">
        <thead>
          <tr>
            <th>id</th>
            <th>userId</th>
            <th>issuedAt</th>
            <th>expiresAt</th>
            <th>revoked</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let t of tokens">
            <td>{{ t.id }}</td>
            <td>{{ t.userId }}</td>
            <td>{{ t.issuedAt }}</td>
            <td>{{ t.expiresAt }}</td>
            <td>{{ t.revoked }}</td>
            <td><button class="btn btn-sm btn-danger" (click)="revoke(t.id)">Revoke</button></td>
          </tr>
        </tbody>
      </table>
      <div *ngIf="!tokens || tokens.length === 0">No tokens found.</div>
    </div>
  `,
})
export class TokenAdminComponent {
  tokens: RefreshTokenDto[] = [];

  constructor(
    private svc: RefreshTokenAdminService,
    private toastr: ToastrService,
  ) {
    this.load();
  }

  load() {
    this.svc.list().subscribe({
      next: (r) => (this.tokens = r),
      error: (e) => this.toastr.error('Failed to load tokens'),
    });
  }

  revoke(id: number) {
    this.svc.revoke(id).subscribe({
      next: () => {
        this.toastr.success('Revoked');
        this.load();
      },
      error: () => this.toastr.error('Failed to revoke'),
    });
  }
}
