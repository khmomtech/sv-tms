import { Component } from '@angular/core';

@Component({
  selector: 'app-tables-page',
  template: `
    <div class="tables-page">
      <h2>Tables</h2>
      <div class="table-list">
        <div *ngFor="let table of tables">
          <div class="table">
            <div class="table-number">{{ table.number }}</div>
            <div class="table-status">{{ table.status }}</div>
          </div>
        </div>
      </div>
      <div class="create-table">
        <form [formGroup]="createForm">
          <input type="number" name="tableNumber" placeholder="Table number">
          <button type="submit">Create</button>
        </form>
      </div>
    </div>
  `,
})
export class TablesPageComponent {
  tables: any[] = [];
  createForm = {
    tableNumber: ''
  };

  isValidTableNumber(tableNumber: string): boolean {
    return !!tableNumber && /^\d+$/.test(tableNumber);
  }

  isValidCreateForm(): boolean {
    return this.isValidTableNumber(this.createForm.tableNumber);
  }

  creating(): boolean {
    return false;
  }

  createError(): string | null {
    return null;
  }

  createSuccess(): boolean {
    return false;
  }

  loading(): boolean {
    return false;
  }

  error(): string | null {
    return null;
  }

  search(): void {
  }

  createTable(): void {
  }
}