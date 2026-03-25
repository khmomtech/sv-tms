import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-slide-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './slide-panel.component.html',
  styleUrls: ['./slide-panel.component.css'],
})
export class SlidePanelComponent {
  @Input() title: string = '';
  @Input() visible: boolean = false;
  @Output() closed = new EventEmitter<void>();

  close(): void {
    this.closed.emit();
  }
}
