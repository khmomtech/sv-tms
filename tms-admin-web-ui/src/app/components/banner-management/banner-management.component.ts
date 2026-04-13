import { Component, OnInit, inject, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { environment } from '../../environments/environment';
import { BannerService, Banner, ApiResponse } from '../../services/banner.service';
import { ImageManagementService } from '../../services/image-management.service';
import type { ImageInfo } from '../../services/image-management.service';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';

@Component({
  selector: 'app-banner-management',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './banner-management.component.html',
  styleUrls: ['./banner-management.component.css'],
})
export class BannerManagementComponent implements OnInit {
  banners: Banner[] = [];
  filteredBanners: Banner[] = [];
  isLoading = false;
  showForm = false;
  isEditing = false;

  // Filter
  selectedCategory = '';
  categories = ['all', 'announcement', 'promotion', 'safety', 'news', 'general'];

  // Form model
  bannerForm: Banner = this.getEmptyBanner();

  // Image selection
  availableImages: any[] = [];
  showImagePicker = false;
  uploadProgress = 0;
  isDragOver = false;
  errorMessage = '';
  successMessage = '';
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  private bannerService = inject(BannerService);
  private imageService = inject(ImageManagementService);
  private router = inject(Router);
  private confirm = inject(ConfirmService);
  private notification = inject(NotificationService);

  constructor() {}

  ngOnInit(): void {
    this.loadBanners();
    this.loadImages();
  }

  onFileSelected(event: any): void {
    const file: File = event.target.files[0];
    if (!file) return;
    // Show immediate local preview while upload is in progress
    try {
      const blobUrl = URL.createObjectURL(file);
      this.bannerForm.imageUrl = blobUrl;
    } catch {}
    this.uploadFile(file);
  }

  uploadFile(file: File): void {
    this.clearMessages();

    const validation = this.imageService.validateImageFile(file);
    if (!validation.valid) {
      this.showError(validation.error || 'Invalid file');
      return;
    }

    this.uploadProgress = 0;
    this.isLoading = true;

    // Simulate progress for better UX
    const progressInterval = setInterval(() => {
      if (this.uploadProgress < 90) {
        this.uploadProgress += Math.random() * 15;
      }
    }, 200);

    this.imageService.uploadImage({ file, category: 'banners' }).subscribe({
      next: (imageInfo: ImageInfo) => {
        clearInterval(progressInterval);
        this.uploadProgress = 100;
        this.bannerForm.imageUrl = imageInfo.url;

        // Ensure availableImages is an array before using unshift
        if (!Array.isArray(this.availableImages)) {
          this.availableImages = [];
        }
        this.availableImages.unshift(imageInfo);
        this.showSuccess('Image uploaded successfully!');

        setTimeout(() => {
          this.uploadProgress = 0;
          this.isLoading = false;
        }, 1000);
      },
      error: (err) => {
        clearInterval(progressInterval);
        this.uploadProgress = 0;
        this.isLoading = false;
        this.showError('Failed to upload image. Please try again.');
        console.error('Upload error:', err);
      },
    });
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.uploadFile(files[0]);
    }
  }

  removeImage(): void {
    this.bannerForm.imageUrl = '';
  }

  // Fallback handler to replace broken images with placeholder
  handleImageError(event: any): void {
    this.onImageError(event);
  }

  onImageError(event: Event): void {
    const target = event?.target as HTMLImageElement | null;
    if (!target) return;
    const img = target;
    // avoid endless loops by sequencing fallbacks
    const tried = (img.dataset && img.dataset['fallbackTried']) || '';
    if (tried === '') {
      img.dataset['fallbackTried'] = 'png';
      img.src = 'assets/images/placeholder-banner.png';
      return;
    }
    if (tried === 'png') {
      img.dataset['fallbackTried'] = 'svg';
      img.src = 'assets/images/placeholder-banner.svg';
      return;
    }
    // final inline SVG data URI as last resort
    img.onerror = null; // stop further error handling
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='800' height='200'>
      <rect width='100%' height='100%' fill='#f3f4f6'/>
      <text x='50%' y='55%' text-anchor='middle' fill='#9ca3af' font-size='20' font-family='Arial' font-weight='600'>Image unavailable</text>
    </svg>`;
    img.src = `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
  }

  triggerFileInput(): void {
    this.fileInput.nativeElement.click();
  }

  showError(message: string): void {
    this.errorMessage = message;
    setTimeout(() => (this.errorMessage = ''), 5000);
  }

  showSuccess(message: string): void {
    this.successMessage = message;
    setTimeout(() => (this.successMessage = ''), 3000);
  }

  clearMessages(): void {
    this.errorMessage = '';
    this.successMessage = '';
  }

  loadBanners(): void {
    this.isLoading = true;
    this.bannerService.getAllBanners().subscribe({
      next: (response: ApiResponse<Banner[]>) => {
        console.log('Banners loaded:', response);
        if (response.success) {
          this.banners = response.data;
          this.applyFilter();
        } else {
          this.showError('Failed to load banners: ' + (response.message || 'Unknown error'));
        }
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error loading banners:', error);
        this.showError('Failed to load banners. Please refresh the page.');
        this.isLoading = false;
      },
    });
  }

  loadImages(): void {
    this.imageService.getImagesByCategory('banners').subscribe({
      next: (images: ImageInfo[]) => {
        // Ensure images is always an array
        this.availableImages = Array.isArray(images) ? images : [];
        console.log('Images loaded:', this.availableImages.length, 'items');
      },
      error: (error: any) => {
        console.error('Error loading images:', error);
        this.availableImages = []; // Fallback to empty array
        this.showError('Failed to load images. Please try again.');
      },
    });
  }

  applyFilter(): void {
    if (this.selectedCategory && this.selectedCategory !== 'all') {
      this.filteredBanners = this.banners.filter((b) => b.category === this.selectedCategory);
    } else {
      this.filteredBanners = [...this.banners];
    }
    // Sort by display order
    this.filteredBanners.sort((a, b) => a.displayOrder - b.displayOrder);
  }

  onFilterChange(): void {
    this.applyFilter();
  }

  getEmptyBanner(): Banner {
    const now = new Date();
    const oneYearLater = new Date();
    oneYearLater.setFullYear(now.getFullYear() + 1);

    return {
      title: '',
      titleKh: '',
      subtitle: '',
      subtitleKh: '',
      imageUrl: '',
      category: 'announcement',
      targetUrl: '',
      displayOrder: 0,
      startDate: now.toISOString().slice(0, 16),
      endDate: oneYearLater.toISOString().slice(0, 16),
      active: true,
    };
  }

  showCreateForm(): void {
    this.bannerForm = this.getEmptyBanner();
    this.isEditing = false;
    this.showForm = true;
  }

  editBanner(banner: Banner): void {
    this.bannerForm = {
      ...banner,
      startDate: this.formatDateForInput(banner.startDate),
      endDate: this.formatDateForInput(banner.endDate),
    };
    this.isEditing = true;
    this.showForm = true;
    this.clearMessages();
    console.log('Editing banner:', this.bannerForm);
  }
  private formatDateForInput(date: any): string {
    if (!date) return '';

    let d: Date;

    // Handle different date formats from backend
    if (Array.isArray(date)) {
      // Backend sends array [year, month, day, hour, minute, second]
      d = new Date(date[0], date[1] - 1, date[2], date[3] || 0, date[4] || 0, date[5] || 0);
    } else if (typeof date === 'string') {
      // ISO string or other string format
      d = new Date(date);
    } else {
      // Assume it's already a Date object or timestamp
      d = new Date(date);
    }

    if (isNaN(d.getTime())) {
      console.warn('Invalid date received:', date);
      return ''; // Return empty string for invalid dates
    }

    // Format to YYYY-MM-DDTHH:mm for datetime-local input
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  cancelForm(): void {
    this.showForm = false;
    this.bannerForm = this.getEmptyBanner();
  }

  private ensureLocalDateTime(dateStr: string): string {
    if (!dateStr) {
      return dateStr;
    }

    // Prefer preserving datetime-local format (no timezone part) for LocalDateTime backend fields
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      return dateStr;
    }

    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  saveBanner(): void {
    this.clearMessages();

    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;

    // Prepare banner data with proper date formatting (avoid Z offsets)
    const bannerData: Banner = {
      ...this.bannerForm,
      startDate: this.ensureLocalDateTime(this.bannerForm.startDate),
      endDate: this.ensureLocalDateTime(this.bannerForm.endDate),
    };

    console.log('Saving banner data:', bannerData);

    const observable = this.isEditing
      ? this.bannerService.updateBanner(this.bannerForm.id!, bannerData)
      : this.bannerService.createBanner(bannerData);

    observable.subscribe({
      next: (response: ApiResponse<Banner>) => {
        console.log('Save response:', response);
        if (response.success) {
          this.showSuccess(
            this.isEditing ? 'Banner updated successfully!' : 'Banner created successfully!',
          );
          setTimeout(() => {
            this.cancelForm();
            this.loadBanners();
          }, 1500);
        } else {
          this.showError('Failed: ' + (response.message || 'Unknown error'));
        }
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error saving banner:', error);
        const errorMsg =
          error?.error?.message || error?.message || 'Failed to save banner. Please try again.';
        this.showError(errorMsg);
        this.isLoading = false;
      },
    });
  }

  async deleteBanner(banner: Banner): Promise<void> {
    if (!(await this.confirm.confirm(`Delete banner "${banner.title}"?`))) {
      return;
    }

    this.bannerService.deleteBanner(banner.id!).subscribe({
      next: (response: ApiResponse<string>) => {
        if (response.success) {
          this.notification.simulateNotification('Success', 'Banner deleted successfully');
          this.loadBanners();
        } else {
          this.notification.simulateNotification('Error', 'Failed to delete: ' + response.message);
        }
      },
      error: (error: any) => {
        console.error('Error deleting banner:', error);
        this.notification.simulateNotification('Error', 'Failed to delete banner');
      },
    });
  }

  validateForm(): boolean {
    const errors: string[] = [];

    if (!this.bannerForm.title?.trim()) {
      errors.push('Title (English) is required');
    }

    if (!this.bannerForm.imageUrl?.trim()) {
      errors.push('Banner image is required');
    }

    if (!this.bannerForm.category) {
      errors.push('Category is required');
    }

    if (!this.bannerForm.startDate) {
      errors.push('Start date is required');
    }

    if (!this.bannerForm.endDate) {
      errors.push('End date is required');
    }

    if (this.bannerForm.startDate && this.bannerForm.endDate) {
      const startDate = new Date(this.bannerForm.startDate);
      const endDate = new Date(this.bannerForm.endDate);

      if (endDate <= startDate) {
        errors.push('End date must be after start date');
      }
    }

    if (errors.length > 0) {
      this.showError('Please fix the following errors:\n• ' + errors.join('\n• '));
      return false;
    }

    return true;
  }

  openImagePicker(): void {
    this.showImagePicker = true;
  }

  selectImage(image: any): void {
    this.bannerForm.imageUrl = image.url;
    this.showImagePicker = false;
  }

  toggleActive(banner: Banner): void {
    const updatedBanner: Banner = {
      ...banner,
      active: !banner.active,
      startDate: this.ensureLocalDateTime(banner.startDate),
      endDate: this.ensureLocalDateTime(banner.endDate),
    };

    this.bannerService.updateBanner(banner.id!, updatedBanner).subscribe({
      next: (response: ApiResponse<Banner>) => {
        if (response.success) {
          banner.active = updatedBanner.active;
        }
      },
      error: (error: any) => {
        console.error('Error toggling status:', error);
      },
    });
  }

  getImageUrl(url: string): string {
    // No URL provided → use placeholder
    if (!url || !url.trim()) {
      return 'assets/images/placeholder-banner.png';
    }

    const trimmed = url.trim();

    // Local blob preview URL
    if (trimmed.startsWith('blob:')) {
      return trimmed;
    }

    // Already absolute
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // If backend returned "/uploads/..." or "uploads/..." → prepend baseUrl (host),
    // otherwise rely on dev proxy mapping for /uploads
    if (trimmed.startsWith('/uploads') || trimmed.startsWith('uploads/')) {
      const path = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
      const base = (environment.baseUrl || '').trim();
      if (base && (base.startsWith('http://') || base.startsWith('https://'))) {
        const normalizedBase = base.endsWith('/') ? base.slice(0, -1) : base;
        return `${normalizedBase}${path}`;
      }
      return path; // let dev proxy handle it
    }

    // If it's already an assets path, pass through
    if (trimmed.startsWith('/assets/') || trimmed.startsWith('assets/')) {
      return trimmed.startsWith('/') ? trimmed : trimmed; // allow either
    }

    // Treat as image filename under assets/images
    return `assets/images/${trimmed}`;
  }

  formatDisplayDate(date: any): string {
    if (!date) return 'Not set';

    let d: Date;

    if (Array.isArray(date)) {
      d = new Date(date[0], date[1] - 1, date[2], date[3] || 0, date[4] || 0, date[5] || 0);
    } else {
      d = new Date(date);
    }

    if (isNaN(d.getTime())) {
      return 'Invalid date';
    }

    return d.toLocaleString('en-US', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    });
  }
}
