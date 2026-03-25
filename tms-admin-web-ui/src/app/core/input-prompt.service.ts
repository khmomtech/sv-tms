import { Injectable } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { InputPromptComponent } from '../shared/components/input-prompt/input-prompt.component';
import { lastValueFrom } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class InputPromptService {
  constructor(private dialog: MatDialog) {}

  prompt(
    message: string,
    options?: {
      title?: string;
      placeholder?: string;
      defaultValue?: string;
      multiline?: boolean;
      confirmText?: string;
      cancelText?: string;
    },
  ): Promise<string | null> {
    const ref = this.dialog.open(InputPromptComponent, {
      data: {
        title: options?.title,
        message,
        placeholder: options?.placeholder,
        defaultValue: options?.defaultValue,
        multiline: options?.multiline,
        confirmText: options?.confirmText,
        cancelText: options?.cancelText,
      },
      disableClose: true,
    });

    return lastValueFrom(ref.afterClosed());
  }
}
