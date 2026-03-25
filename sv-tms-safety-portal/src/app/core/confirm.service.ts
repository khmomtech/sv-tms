import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ConfirmService {
  confirm(message: string): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const overlay = document.createElement('div');
      overlay.style.position = 'fixed';
      overlay.style.left = '0';
      overlay.style.top = '0';
      overlay.style.right = '0';
      overlay.style.bottom = '0';
      overlay.style.background = 'rgba(0,0,0,0.4)';
      overlay.style.display = 'flex';
      overlay.style.alignItems = 'center';
      overlay.style.justifyContent = 'center';
      overlay.style.zIndex = '10000';

      const box = document.createElement('div');
      box.style.background = '#fff';
      box.style.padding = '16px';
      box.style.borderRadius = '8px';
      box.style.maxWidth = '90%';
      box.style.boxShadow = '0 4px 20px rgba(0,0,0,0.2)';

      const msg = document.createElement('div');
      msg.textContent = message;
      msg.style.marginBottom = '12px';

      const actions = document.createElement('div');
      actions.style.display = 'flex';
      actions.style.justifyContent = 'flex-end';
      actions.style.gap = '8px';

      const btnNo = document.createElement('button');
      btnNo.textContent = 'Cancel';
      btnNo.style.padding = '6px 12px';

      const btnYes = document.createElement('button');
      btnYes.textContent = 'OK';
      btnYes.style.padding = '6px 12px';
      btnYes.style.background = '#dc2626';
      btnYes.style.color = '#fff';
      btnYes.style.border = 'none';

      actions.appendChild(btnNo);
      actions.appendChild(btnYes);

      box.appendChild(msg);
      box.appendChild(actions);
      overlay.appendChild(box);
      document.body.appendChild(overlay);

      const cleanup = () => { overlay.remove(); };

      btnYes.addEventListener('click', () => { cleanup(); resolve(true); });
      btnNo.addEventListener('click', () => { cleanup(); resolve(false); });

      // allow dismiss on overlay click
      overlay.addEventListener('click', (ev) => { if (ev.target === overlay) { cleanup(); resolve(false); } });
    });
  }
}
