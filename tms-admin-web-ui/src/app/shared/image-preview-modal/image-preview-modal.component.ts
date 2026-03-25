import { CommonModule } from '@angular/common';
import type { OnDestroy, OnInit } from '@angular/core';
import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';

@Component({
  selector: 'app-image-preview-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './image-preview-modal.component.html',
  styleUrls: ['./image-preview-modal.component.css'],
})
export class ImagePreviewModalComponent implements OnInit, OnDestroy {
  @Input() images: string[] = [];
  @Input() currentIndex = 0;
  @Output() closeModal = new EventEmitter<void>();
  @Output() next = new EventEmitter<void>();
  @Output() prev = new EventEmitter<void>();

  zoom = 1;

  ngOnInit(): void {
    document.body.style.overflow = 'hidden';
  }

  ngOnDestroy(): void {
    document.body.style.overflow = 'auto';
  }

  @HostListener('document:keydown', ['$event'])
  handleKeyboardEvent(event: KeyboardEvent) {
    switch (event.key) {
      case 'Escape':
        this.onClose();
        break;
      case 'ArrowRight':
        this.onNext();
        break;
      case 'ArrowLeft':
        this.onPrev();
        break;
      case '+':
      case '=':
        this.onZoomIn();
        break;
      case '-':
        this.onZoomOut();
        break;
    }
  }

  onClose(): void {
    this.zoom = 1;
    this.closeModal.emit();
  }

  onNext(): void {
    this.next.emit();
    this.zoom = 1;
  }

  onPrev(): void {
    this.prev.emit();
    this.zoom = 1;
  }

  onZoomIn(): void {
    this.zoom += 0.1;
  }

  onZoomOut(): void {
    if (this.zoom > 0.2) {
      this.zoom -= 0.1;
    }
  }
}
