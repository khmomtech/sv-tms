import { CommonModule } from '@angular/common';
import { Component, Inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-input-prompt',
  standalone: true,
  imports: [CommonModule, FormsModule, MatDialogModule, MatFormFieldModule, MatInputModule],
  templateUrl: './input-prompt.component.html',
})
export class InputPromptComponent {
  value: string;

  constructor(
    public dialogRef: MatDialogRef<InputPromptComponent>,
    @Inject(MAT_DIALOG_DATA)
    public data: {
      title?: string;
      message?: string;
      placeholder?: string;
      defaultValue?: string;
      multiline?: boolean;
      confirmText?: string;
      cancelText?: string;
    },
  ) {
    this.value = data?.defaultValue ?? '';
  }

  onConfirm(): void {
    this.dialogRef.close(this.value);
  }

  onCancel(): void {
    this.dialogRef.close(null);
  }
}
