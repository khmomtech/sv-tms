import { Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';

export class TablesPageComponent {
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

  tables(): any[] {
    return [];
  }

  search(): void {
  }

  createTable(): void {
  }
}