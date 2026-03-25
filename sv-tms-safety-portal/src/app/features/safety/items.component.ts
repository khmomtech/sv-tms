import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-safety-items',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h2 class="text-xl font-semibold">Safety Items</h2>
    <div class="mt-4">
      <button class="px-3 py-2 bg-green-600 text-white rounded" (click)="create()">Create Item</button>
      <ul class="mt-4">
        <li *ngFor="let it of items">{{it.nameKh}} / {{it.nameEn}} <span *ngIf="it.requiresPhotoOnFail" class="text-red-600">(photo on fail)</span></li>
      </ul>
    </div>
  `,
  providers: [ApiService]
})
export class ItemsComponent implements OnInit {
  items: any[] = [];
  constructor(private api: ApiService) {}
  ngOnInit(){ this.api.get<any>('/safety/items').subscribe(r=> this.items = r || []); }
  create(){ const payload = { categoryId:1, nameKh:'ថ្មី', nameEn:'New', requiresPhotoOnFail:false, active:true}; this.api.post('/safety/items', payload).subscribe(x=> this.items.push(x)); }
}
