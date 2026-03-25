import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private container?: HTMLElement;

  private ensureContainer(){
    if(this.container) return this.container;
    const c = document.createElement('div');
    c.style.position = 'fixed'; c.style.right = '16px'; c.style.top = '16px'; c.style.zIndex = '9999';
    document.body.appendChild(c);
    this.container = c;
    return c;
  }

  show(message: string, type: 'info' | 'success' | 'error' = 'info', timeout = 4000){
    const c = this.ensureContainer();
    const el = document.createElement('div');
    el.textContent = message;
    el.style.color = '#fff';
    el.style.padding = '8px 12px';
    el.style.marginTop = '8px';
    el.style.borderRadius = '6px';
    el.style.boxShadow = '0 2px 8px rgba(0,0,0,0.2)';
    el.style.opacity = '1';

    switch(type){
      case 'success':
        el.style.background = '#16a34a';
        break;
      case 'error':
        el.style.background = '#dc2626';
        break;
      default:
        el.style.background = '#111827';
    }

    c.appendChild(el);
    setTimeout(()=>{ el.style.transition = 'opacity 300ms'; el.style.opacity = '0'; setTimeout(()=> el.remove(), 300); }, timeout);
  }

  success(message: string, timeout = 3000){ this.show(message, 'success', timeout); }
  error(message: string, timeout = 5000){ this.show(message, 'error', timeout); }
}
