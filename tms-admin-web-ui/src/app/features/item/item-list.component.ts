import { Component, OnInit } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged, filter, switchMap } from 'rxjs/operators';
import { ItemService, SuggestDto } from '../../services/item.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-item-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <input [formControl]="searchControl" placeholder="Search items" />
    <ul>
      <li *ngFor="let s of suggestions">{{ s.label }}</li>
    </ul>
  `,
})
export class ItemListComponent implements OnInit {
  searchControl = new FormControl<string | null>(null);
  suggestions: SuggestDto[] = [];

  constructor(private itemService: ItemService) {}

  ngOnInit(): void {
    this.searchControl.valueChanges
      .pipe(
        filter((v): v is string => !!v && v.length > 1),
        debounceTime(300),
        distinctUntilChanged(),
        switchMap((q: string) => this.itemService.autocomplete(q, 10)),
      )
      .subscribe((r) => (this.suggestions = r));
  }
}
