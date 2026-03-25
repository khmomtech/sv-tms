import { Component } from '@angular/core';

@Component({
  selector: 'app-audit',
  standalone: true,
  template: `
    <h2 class="text-xl font-semibold">Audit Logs</h2>
    <p class="mt-4">Shows audit entries for CRUD and overrides (placeholder)</p>
  `
})
export class AuditComponent {}
