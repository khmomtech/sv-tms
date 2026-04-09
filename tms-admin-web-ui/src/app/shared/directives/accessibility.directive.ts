import { Directive, ElementRef, Input, OnInit } from '@angular/core';

/**
 * Directive to improve accessibility by automatically adding ARIA labels
 * Usage: <button appAriaLabel="Close dialog">X</button>
 */
@Directive({
  selector: '[appAriaLabel]',
  standalone: true,
})
export class AriaLabelDirective implements OnInit {
  @Input() appAriaLabel = '';

  constructor(private el: ElementRef) {}

  ngOnInit(): void {
    if (this.appAriaLabel) {
      this.el.nativeElement.setAttribute('aria-label', this.appAriaLabel);
    }
  }
}

/**
 * Directive to set role attribute for accessibility
 * Usage: <div appRole="navigation">...</div>
 */
@Directive({
  selector: '[appRole]',
  standalone: true,
})
export class RoleDirective implements OnInit {
  @Input() appRole = '';

  constructor(private el: ElementRef) {}

  ngOnInit(): void {
    if (this.appRole) {
      this.el.nativeElement.setAttribute('role', this.appRole);
    }
  }
}

/**
 * Directive to mark elements as live regions for screen readers
 * Usage: <div appAriaLive="polite">Status updates...</div>
 */
@Directive({
  selector: '[appAriaLive]',
  standalone: true,
})
export class AriaLiveDirective implements OnInit {
  @Input() appAriaLive: 'off' | 'polite' | 'assertive' = 'polite';

  constructor(private el: ElementRef) {}

  ngOnInit(): void {
    this.el.nativeElement.setAttribute('aria-live', this.appAriaLive);
  }
}
