import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CdkDragDrop, DragDropModule, moveItemInArray } from '@angular/cdk/drag-drop';
import { HomeLayoutService } from '../../services/home-layout.service';
import { NotificationService } from '../../services/notification.service';
import { ConfirmService } from '../../services/confirm.service';
import {
  HomeLayoutSection,
  HomeLayoutSectionRequest,
  SECTION_CATEGORIES,
  SECTION_ICONS,
} from '../../models/home-layout-section.model';

@Component({
  selector: 'app-home-layout-management',
  standalone: true,
  imports: [CommonModule, FormsModule, DragDropModule],
  templateUrl: './home-layout-management.component.html',
  styleUrls: ['./home-layout-management.component.scss'],
})
export class HomeLayoutManagementComponent implements OnInit {
  sections: HomeLayoutSection[] = [];
  filteredSections: HomeLayoutSection[] = [];
  isLoading = false;
  showForm = false;
  isEditing = false;

  // Filter
  selectedCategory = 'all';
  categories = SECTION_CATEGORIES;
  availableIcons = SECTION_ICONS;

  // Form model
  sectionForm: HomeLayoutSectionRequest = this.getEmptyForm();

  constructor(
    private layoutService: HomeLayoutService,
    private notification: NotificationService,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.loadSections();
  }

  loadSections(): void {
    this.isLoading = true;
    this.layoutService.getAllSections().subscribe({
      next: (sections) => {
        this.sections = sections.sort((a, b) => a.displayOrder - b.displayOrder);
        this.applyFilter();
        this.isLoading = false;
      },
      error: (error) => {
        this.notification.error('Failed to load sections: ' + error.message);
        this.isLoading = false;
      },
    });
  }

  applyFilter(): void {
    if (this.selectedCategory === 'all') {
      this.filteredSections = [...this.sections];
    } else {
      this.filteredSections = this.sections.filter((s) => s.category === this.selectedCategory);
    }
  }

  onCategoryChange(): void {
    this.applyFilter();
  }

  onDrop(event: CdkDragDrop<HomeLayoutSection[]>): void {
    if (event.previousIndex === event.currentIndex) return;

    moveItemInArray(this.sections, event.previousIndex, event.currentIndex);

    // Update display orders and save
    const orderedIds = this.sections.map((s) => s.id!);
    this.layoutService.reorderSections(orderedIds).subscribe({
      next: (updatedSections) => {
        this.sections = updatedSections;
        this.applyFilter();
        this.notification.success('Section order updated successfully');
      },
      error: (error) => {
        this.notification.error('Failed to reorder sections: ' + error.message);
        this.loadSections(); // Reload to reset order
      },
    });
  }

  toggleVisibility(section: HomeLayoutSection): void {
    if (section.isMandatory && section.visible) {
      this.notification.warn('Cannot hide mandatory sections');
      return;
    }

    this.layoutService.toggleVisibility(section.id!).subscribe({
      next: (updated) => {
        const index = this.sections.findIndex((s) => s.id === updated.id);
        if (index !== -1) {
          this.sections[index] = updated;
          this.applyFilter();
        }
        this.notification.success(`Section ${updated.visible ? 'shown' : 'hidden'} successfully`);
      },
      error: (error) => {
        this.notification.error('Failed to toggle visibility: ' + error.message);
      },
    });
  }

  showCreateForm(): void {
    this.sectionForm = this.getEmptyForm();
    this.isEditing = false;
    this.showForm = true;
  }

  editSection(section: HomeLayoutSection): void {
    this.sectionForm = {
      sectionKey: section.sectionKey,
      sectionName: section.sectionName,
      sectionNameKh: section.sectionNameKh,
      description: section.description,
      descriptionKh: section.descriptionKh,
      displayOrder: section.displayOrder,
      visible: section.visible,
      isMandatory: section.isMandatory,
      icon: section.icon,
      category: section.category || 'general',
      configJson: section.configJson,
    };
    this.isEditing = true;
    this.showForm = true;
  }

  async deleteSection(section: HomeLayoutSection): Promise<void> {
    if (section.isMandatory) {
      this.notification.error('Cannot delete mandatory sections');
      return;
    }

    const confirmed = await this.confirm.confirm(
      `Delete section "${section.sectionName}"? This action cannot be undone.`,
    );

    if (!confirmed) return;

    this.layoutService.deleteSection(section.id!).subscribe({
      next: () => {
        this.notification.success('Section deleted successfully');
        this.loadSections();
      },
      error: (error) => {
        this.notification.error('Failed to delete section: ' + error.message);
      },
    });
  }

  saveSection(): void {
    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;

    const request = this.sectionForm;

    if (this.isEditing) {
      const section = this.sections.find((s) => s.sectionKey === request.sectionKey);
      if (!section || !section.id) {
        this.notification.error('Section not found');
        this.isLoading = false;
        return;
      }

      this.layoutService.updateSection(section.id, request).subscribe({
        next: () => {
          this.notification.success('Section updated successfully');
          this.showForm = false;
          this.loadSections();
        },
        error: (error) => {
          this.notification.error('Failed to update section: ' + error.message);
          this.isLoading = false;
        },
      });
    } else {
      this.layoutService.createSection(request).subscribe({
        next: () => {
          this.notification.success('Section created successfully');
          this.showForm = false;
          this.loadSections();
        },
        error: (error) => {
          this.notification.error('Failed to create section: ' + error.message);
          this.isLoading = false;
        },
      });
    }
  }

  cancelForm(): void {
    this.showForm = false;
    this.sectionForm = this.getEmptyForm();
  }

  initializeDefaults(): void {
    this.confirm
      .confirm(
        "Initialize default sections? This will create the default home screen sections if they don't already exist.",
      )
      .then((confirmed: boolean) => {
        if (!confirmed) return;

        this.layoutService.initializeDefaults().subscribe({
          next: (message) => {
            this.notification.success(message);
            this.loadSections();
          },
          error: (error) => {
            this.notification.error('Failed to initialize: ' + error.message);
          },
        });
      });
  }

  private validateForm(): boolean {
    if (!this.sectionForm.sectionKey || !this.sectionForm.sectionName) {
      this.notification.error('Section key and name are required');
      return false;
    }

    if (this.sectionForm.displayOrder < 0) {
      this.notification.error('Display order must be >= 0');
      return false;
    }

    return true;
  }

  private getEmptyForm(): HomeLayoutSectionRequest {
    return {
      sectionKey: '',
      sectionName: '',
      sectionNameKh: '',
      description: '',
      descriptionKh: '',
      displayOrder: this.sections.length,
      visible: true,
      isMandatory: false,
      icon: 'dashboard',
      category: 'general',
      configJson: '',
    };
  }
}
