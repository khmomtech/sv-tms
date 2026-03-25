import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-status-chip',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span [ngClass]="classFor(status)" class="px-2 py-1 rounded text-sm">{{status}}</span>
  `
})
export class StatusChipComponent {
  @Input() status: string = '';
  classFor(s: string){
    if(!s) return 'bg-gray-200 text-gray-800';
    const st = s.toLowerCase();
    if(st.includes('pass') || st === 'ready') return 'bg-green-100 text-green-800';
    if(st.includes('warn') || st === 'warning') return 'bg-yellow-100 text-yellow-800';
    if(st.includes('fail') || st === 'blocked') return 'bg-red-100 text-red-800';
    return 'bg-gray-200 text-gray-800';
  }
}
