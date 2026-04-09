/**
 * Shared Import Constants for Angular Standalone Components
 *
 * Purpose: Eliminate repetitive imports across components following DRY principle.
 * Usage: import { BASE_IMPORTS, FORM_IMPORTS } from '@shared/common-imports';
 *
 * @example
 * @Component({
 *   standalone: true,
 *   imports: [...BASE_IMPORTS, ...FORM_IMPORTS, ...BUTTON_IMPORTS]
 * })
 */

import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

// Angular Material Modules
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatChipsModule } from '@angular/material/chips';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatDialogModule } from '@angular/material/dialog';
import { MatDividerModule } from '@angular/material/divider';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatMenuModule } from '@angular/material/menu';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSortModule } from '@angular/material/sort';
import { MatTableModule } from '@angular/material/table';
import { MatTabsModule } from '@angular/material/tabs';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatBadgeModule } from '@angular/material/badge';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatRadioModule } from '@angular/material/radio';

/**
 * BASE_IMPORTS - Essential Angular modules required by most components
 * Includes: CommonModule for *ngIf, *ngFor, pipes, etc.
 */
export const BASE_IMPORTS = [CommonModule] as const;

/**
 * FORM_IMPORTS - Form-related modules for reactive and template-driven forms
 * Includes: FormsModule, ReactiveFormsModule, Material form fields
 */
export const FORM_IMPORTS = [
  FormsModule,
  ReactiveFormsModule,
  MatFormFieldModule,
  MatInputModule,
  MatSelectModule,
  MatCheckboxModule,
  MatRadioModule,
  MatDatepickerModule,
  MatSlideToggleModule,
] as const;

/**
 * BUTTON_IMPORTS - Button and icon modules
 * Includes: Material buttons, icons, tooltips
 */
export const BUTTON_IMPORTS = [
  MatButtonModule,
  MatIconModule,
  MatTooltipModule,
  MatBadgeModule,
] as const;

/**
 * TOOLTIP_IMPORTS - Tooltip module
 * Includes: Material tooltips
 */
export const TOOLTIP_IMPORTS = [MatTooltipModule] as const;

/**
 * TABLE_IMPORTS - Data table related modules
 * Includes: Material table, paginator, sort
 */
export const TABLE_IMPORTS = [MatTableModule, MatPaginatorModule, MatSortModule] as const;

/**
 * DIALOG_IMPORTS - Dialog and modal modules
 * Includes: Material dialog, snackbar
 */
export const DIALOG_IMPORTS = [MatDialogModule, MatSnackBarModule] as const;

/**
 * LAYOUT_IMPORTS - Layout and navigation modules
 * Includes: Material toolbar, tabs, cards, expansion panels
 */
export const LAYOUT_IMPORTS = [
  MatCardModule,
  MatToolbarModule,
  MatTabsModule,
  MatExpansionModule,
] as const;

/**
 * LOADING_IMPORTS - Loading state modules
 * Includes: Material progress spinner, progress bar
 */
export const LOADING_IMPORTS = [MatProgressSpinnerModule, MatProgressBarModule] as const;

/**
 * NAV_IMPORTS - Navigation modules
 * Includes: Angular Router
 */
export const NAV_IMPORTS = [RouterModule] as const;

/**
 * AUTOCOMPLETE_IMPORTS - Autocomplete modules
 * Includes: Material autocomplete, chips
 */
export const AUTOCOMPLETE_IMPORTS = [MatAutocompleteModule, MatChipsModule] as const;

/**
 * MENU_IMPORTS - Menu and dropdown modules
 * Includes: Material menu, divider
 */
export const MENU_IMPORTS = [MatMenuModule, MatDividerModule] as const;

/**
 * MATERIAL_IMPORTS - Comprehensive Material UI bundle
 * Includes: All commonly used Material modules
 * Use with caution - prefer specific import groups for better tree-shaking
 */
export const MATERIAL_IMPORTS = [
  ...BUTTON_IMPORTS,
  ...FORM_IMPORTS,
  ...TABLE_IMPORTS,
  ...DIALOG_IMPORTS,
  ...LAYOUT_IMPORTS,
  ...LOADING_IMPORTS,
  ...AUTOCOMPLETE_IMPORTS,
  ...MENU_IMPORTS,
] as const;
