// item.component.ts (Standalone CRUD Component)
/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, HostListener, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { RouterModule, ActivatedRoute } from '@angular/router';

import type { Item } from '../../../models/item.model';
import { ItemService } from '../../../services/item.service';
import { firstValueFrom } from 'rxjs';
import { ConfirmService } from '../../../services/confirm.service';

interface SortConfig {
  column: string;
  direction: 'asc' | 'desc' | '';
}

@Component({
  selector: 'app-items',
  standalone: true,
  templateUrl: './item.component.html',
  styleUrls: ['./item.component.css'],
  imports: [CommonModule, FormsModule, RouterModule, TranslateModule],
})
export class ItemComponent implements OnInit {
  private confirm = inject(ConfirmService);
  private translate = inject(TranslateService);
  items: Item[] = [];
  filteredItems: Item[] = [];
  selectedItem: Item = this.createDefaultItem();
  isModalOpen = false;
  dropdownOpen: number | string | null = null;
  selectedIds: number[] = [];
  keyword = '';
  filterStatus: string = '';
  filterType: string = '';
  currentPage = 1;
  pageSize = 10;
  totalPages = 1;
  Math = Math;
  isLoading = false;
  showFilters = true;
  errorMessage = '';
  successMessage = '';
  sortConfig: SortConfig = { column: '', direction: '' };

  // Page size options
  pageSizeOptions = [5, 10, 25, 50, 100];

  availableTypes: string[] = [
    'BEVERAGE',
    'DOCUMENT',
    'ELECTRONICS',
    'FURNITURE',
    'FRAGILE',
    'PERISHABLE',
    'HEAVY_EQUIPMENT',
    'CLOTHING',
    'PHARMACEUTICAL',
    'AUTOPARTS',
    'CONSUMER_GOODS',
    'OTHERS',
  ];

  // Column visibility toggle
  visibleColumns = {
    id: true,
    itemCode: true,
    itemName: true,
    itemNameKh: false, // Hidden by default
    itemType: true,
    quantity: true,
    unit: true,
    size: false, // Hidden by default
    weight: true,
    pallets: false, // Hidden by default
    palletType: false, // Hidden by default
    sortOrder: false, // Hidden by default
    status: true,
    actions: true,
  };

  constructor(
    private itemService: ItemService,
    private readonly route: ActivatedRoute,
  ) {}

  ngOnInit(): void {
    this.loadItems();

    // Check if route data indicates we should open create modal
    const action = this.route.snapshot.data['action'];
    if (action === 'create') {
      setTimeout(() => this.openItemModal(), 100);
    }
  }

  private createDefaultItem(): Item {
    return {
      itemCode: '',
      itemName: '',
      itemNameKh: '',
      itemType: '',
      size: '',
      weight: '',
      unit: '',
      quantity: 1,
      pallets: '',
      palletType: '',
      status: 1,
      sortOrder: 0,
    };
  }

  get paginatedItems(): Item[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredItems.slice(start, start + this.pageSize);
  }

  get totalItems(): number {
    return this.filteredItems.length;
  }

  get totalInventoryCount(): number {
    return this.items.length;
  }

  get activeItemsCount(): number {
    return this.items.filter((item) => item.status === 1).length;
  }

  get inactiveItemsCount(): number {
    return this.items.filter((item) => item.status !== 1).length;
  }

  get hasActiveFilters(): boolean {
    return !!(this.keyword.trim() || this.filterStatus.trim() || this.filterType.trim());
  }

  get startItem(): number {
    return (this.currentPage - 1) * this.pageSize + 1;
  }

  get endItem(): number {
    return Math.min(this.currentPage * this.pageSize, this.totalItems);
  }

  get visiblePages(): number[] {
    const pages: number[] = [];
    const maxVisible = 5;
    let start = Math.max(1, this.currentPage - Math.floor(maxVisible / 2));
    let end = Math.min(this.totalPages, start + maxVisible - 1);

    if (end - start + 1 < maxVisible) {
      start = Math.max(1, end - maxVisible + 1);
    }

    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    return pages;
  }

  updatePagination(): void {
    this.totalPages = Math.ceil(this.filteredItems.length / this.pageSize);
    if (this.currentPage > this.totalPages && this.totalPages > 0) {
      this.currentPage = this.totalPages;
    }
    if (this.currentPage < 1) {
      this.currentPage = 1;
    }
  }

  goToPage(page: number): void {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  onPageSizeChange(size: number): void {
    this.pageSize = size;
    this.currentPage = 1;
    this.updatePagination();
  }

  sortBy(column: string): void {
    if (this.sortConfig.column === column) {
      // Cycle through sort directions: asc -> desc -> none
      if (this.sortConfig.direction === 'asc') {
        this.sortConfig.direction = 'desc';
      } else if (this.sortConfig.direction === 'desc') {
        this.sortConfig.direction = '';
        this.sortConfig.column = '';
      } else {
        this.sortConfig.direction = 'asc';
      }
    } else {
      this.sortConfig.column = column;
      this.sortConfig.direction = 'asc';
    }

    this.applySorting();
  }

  private applySorting(): void {
    if (!this.sortConfig.column || !this.sortConfig.direction) {
      this.filteredItems = [...this.filteredItems];
    } else {
      this.filteredItems.sort((a, b) => {
        const aValue = this.getSortValue(a, this.sortConfig.column);
        const bValue = this.getSortValue(b, this.sortConfig.column);

        let result = 0;
        if (aValue < bValue) result = -1;
        if (aValue > bValue) result = 1;

        return this.sortConfig.direction === 'desc' ? -result : result;
      });
    }
    this.updatePagination();
  }

  private getSortValue(item: Item, column: string): any {
    switch (column) {
      case 'id':
        return item.id || 0;
      case 'itemCode':
        return item.itemCode || '';
      case 'itemName':
        return item.itemName || '';
      case 'itemNameKh':
        return item.itemNameKh || '';
      case 'itemType':
        return item.itemType || '';
      case 'quantity':
        return item.quantity || 0;
      case 'unit':
        return item.unit || '';
      case 'size':
        return item.size || '';
      case 'weight':
        return item.weight || '';
      case 'pallets':
        return item.pallets || '';
      case 'palletType':
        return item.palletType || '';
      case 'sortOrder':
        return item.sortOrder || 0;
      case 'status':
        return item.status || 0;
      default:
        return '';
    }
  }

  getSortIcon(column: string): string {
    if (this.sortConfig.column !== column) {
      return 'fas fa-sort';
    }
    switch (this.sortConfig.direction) {
      case 'asc':
        return 'fas fa-sort-up';
      case 'desc':
        return 'fas fa-sort-down';
      default:
        return 'fas fa-sort';
    }
  }

  loadItems(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.itemService.getAllItems().subscribe({
      next: (res) => {
        this.items = res || [];
        this.filteredItems = [...this.items];
        this.applySorting();
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Load items error:', err);
        this.errorMessage = err.message || 'Failed to load items.';
        this.isLoading = false;
      },
    });
  }

  searchItems(): void {
    const keyword = this.keyword.trim().toLowerCase();
    const status = this.filterStatus.trim();
    const type = this.filterType.trim().toLowerCase();

    this.filteredItems = this.items.filter((item) => {
      const matchesKeyword =
        !keyword ||
        item.itemCode?.toLowerCase().includes(keyword) ||
        item.itemName?.toLowerCase().includes(keyword) ||
        item.itemNameKh?.toLowerCase().includes(keyword);
      const matchesStatus = !status || item.status?.toString() === status;
      const matchesType = !type || item.itemType?.toLowerCase() === type;
      return matchesKeyword && matchesStatus && matchesType;
    });

    this.applySorting();
    this.currentPage = 1;
    this.updatePagination();
  }

  clearFilters(): void {
    this.keyword = '';
    this.filterStatus = '';
    this.filterType = '';
    this.searchItems();
  }

  toggleFilters(): void {
    this.showFilters = !this.showFilters;
  }

  isItemFormValid(): boolean {
    return !!(
      this.selectedItem.itemCode?.trim() &&
      this.selectedItem.itemName?.trim() &&
      typeof this.selectedItem.quantity === 'number' &&
      this.selectedItem.quantity > 0
    );
  }

  toggleColumnVisibility(column: string): void {
    this.visibleColumns[column as keyof typeof this.visibleColumns] =
      !this.visibleColumns[column as keyof typeof this.visibleColumns];
  }

  openItemModal(item?: Item): void {
    this.errorMessage = '';
    this.successMessage = '';
    this.selectedItem = item ? { ...item } : this.createDefaultItem();
    this.isModalOpen = true;
  }

  closeModal(): void {
    this.isModalOpen = false;
  }

  saveItem(): void {
    if (!this.isItemFormValid()) {
      this.errorMessage = this.translate.instant('items.messages.form_invalid');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    const op = this.selectedItem.id
      ? this.itemService.updateItem(this.selectedItem.id, this.selectedItem)
      : this.itemService.createItem(this.selectedItem);

    op.subscribe({
      next: () => {
        this.loadItems();
        this.closeModal();
        this.successMessage = this.selectedItem.id
          ? this.translate.instant('items.messages.updated_success')
          : this.translate.instant('items.messages.created_success');
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Save error:', err);
        this.errorMessage = err.message || 'Failed to save item.';
        this.isLoading = false;
      },
    });
  }

  async deleteItem(id?: number): Promise<void> {
    if (!id) return;
    if (!(await this.confirm.confirm('Delete this item?'))) return;

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    this.itemService.deleteItem(id).subscribe({
      next: () => {
        this.loadItems();
        this.successMessage = this.translate.instant('items.messages.deleted_success');
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Delete error:', err);
        this.errorMessage = err.message || 'Failed to delete item.';
        this.isLoading = false;
      },
    });
  }

  async deleteSelectedItems(): Promise<void> {
    if (!(await this.confirm.confirm('Delete all selected items?'))) return;

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    const deletions = this.selectedIds.map((id) => firstValueFrom(this.itemService.deleteItem(id)));

    Promise.all(deletions)
      .then(() => {
        this.loadItems();
        this.selectedIds = [];
        this.successMessage = this.translate.instant('items.messages.bulk_deleted_success');
        this.isLoading = false;
      })
      .catch((err) => {
        console.error('Bulk delete failed:', err);
        this.errorMessage = err.message || 'Failed to delete selected items.';
        this.isLoading = false;
      });
  }

  toggleItemSelection(id: number): void {
    this.selectedIds.includes(id)
      ? (this.selectedIds = this.selectedIds.filter((x) => x !== id))
      : this.selectedIds.push(id);
  }

  toggleAll(event: any): void {
    this.selectedIds = event.target.checked ? this.filteredItems.map((c) => c.id!) : [];
  }

  toggleDropdown(id: number | string): void {
    this.dropdownOpen = this.dropdownOpen === id ? null : id;
  }

  getColumnDisplayName(key: string): string {
    return key.replace(/([A-Z])/g, ' $1').trim();
  }

  formatItemType(type?: string | null): string {
    return type ? type.replace(/_/g, ' ') : 'Uncategorized';
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (!target.closest('.dropdown-menu') && !target.closest('.toggle-dropdown')) {
      this.dropdownOpen = null;
    }
  }
}
