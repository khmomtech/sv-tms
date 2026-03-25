#!/bin/bash

# Generate incident-list.component.ts
cat > incident-list.component.ts << 'EOF'
import { CommonModule } from '@angular/common';
import { Component, inject, signal, computed } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import type { Incident, IncidentFilter, IncidentStatistics } from '../models/incident.model';
import {
  IncidentStatus,
  IncidentGroup,
  IssueSeverity
} from '../models/incident.model';
import { IncidentService } from '../services/incident.service';

/**
 * Incident List Component
 *
 * Displays a comprehensive list of all incidents with:
 * - Statistics dashboard showing counts by status
 * - Advanced filtering (search, date range, status, group, severity, etc.)
 * - Sortable data table with pagination
 * - Drawer panel for quick incident preview
 * - Real-time status and SLA monitoring
 *
 * Features:
 * - Multiple tab views in drawer (overview, timeline, tasks, attachments, resolution)
 * - Responsive design with mobile support
 * - Export and bulk operations support
 *
 * Following Angular best practices:
 * - External template (incident-list.component.html)
 * - External styles (incident-list.component.css)
 * - Reactive signals for state management
 * - Standalone component architecture
 */
@Component({
  selector: 'app-incident-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './incident-list.component.html',
  styleUrls: ['./incident-list.component.css']
})
EOF

# Append class implementation from backup
tail -n +1167 incident-list.component.ts.backup >> incident-list.component.ts

echo "Generated incident-list.component.ts"

# Generate incident-detail.component.ts  
cat > incident-detail.component.ts << 'EOF'
import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import type { ApiResponse, Incident } from '../models/incident.model';
import { IncidentService } from '../services/incident.service';
import { CaseService } from '../services/case.service';
import { CaseCategory, IssueSeverity } from '../models/incident.model';

/**
 * Incident Detail Component
 *
 * Displays comprehensive incident information and provides supervisor actions.
 *
 * Features:
 * - Full incident details with evidence and timeline
 * - Supervisor decision panel (validate, close, escalate)
 * - Escalation to case workflow with form
 * - Real-time status and SLA tracking
 * - Modal dialogs for actions
 *
 * Action Workflows:
 * - Close as Small Issue: Quick resolution with notes
 * - Validate Incident: Marks as validated for further investigation  
 * - Escalate to Case: Creates formal investigation case
 *
 * Following Angular best practices:
 * - External template (incident-detail.component.html)
 * - External styles (incident-detail.component.css)
 * - Reactive forms with validation
 * - Standalone component architecture
 */
@Component({
  selector: 'app-incident-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './incident-detail.component.html',
  styleUrls: ['./incident-detail.component.css']
})
EOF

# Append class implementation from backup
tail -n +961 incident-detail.component.ts.backup >> incident-detail.component.ts

echo "Generated incident-detail.component.ts"

# Generate incident-form.component.ts
cat > incident-form.component.ts << 'EOF'
import { CommonModule } from '@angular/common';
import { Component, inject, signal, type OnInit } from '@angular/core';
import { FormsModule, ReactiveFormsModule, FormBuilder, type FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterModule } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import type { Observable } from 'rxjs';
import { of, catchError, map } from 'rxjs';

import type { Driver } from '../../../models/driver.model';
import type { Vehicle } from '../../../models/vehicle.model';
import { DriverService } from '../../../services/driver.service';
import { VehicleService } from '../../../services/vehicle.service';
import { IncidentGroup, IncidentStatus, IssueSeverity } from '../models/incident.model';
import { IncidentService } from '../services/incident.service';

/**
 * Incident Form Component
 *
 * Handles incident creation and editing with comprehensive form validation.
 *
 * Features:
 * - Multi-field form with validation
 * - Driver and vehicle selection with search (ng-select)
 * - Incident type categorization (Traffic, Behavior, Customer, Accident, Vehicle)
 * - Severity levels (Low, Medium, High, Critical)
 * - File attachment support
 * - Location tracking (GPS or manual entry)
 *
 * Form Fields:
 * - Title, Group, Type, Severity (required)
 * - Driver, Vehicle, Location (optional)
 * - Description (required)
 * - Attachments (optional)
 *
 * Following Angular best practices:
 * - External template (incident-form.component.html)
 * - External styles (incident-form.component.css)
 * - Reactive forms with validation
 * - Standalone component architecture
 */
@Component({
  selector: 'app-incident-form',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule, NgSelectModule],
  templateUrl: './incident-form.component.html',
  styleUrls: ['./incident-form.component.css']
})
EOF

# Append class implementation from backup
tail -n +516 incident-form.component.ts.backup >> incident-form.component.ts

echo "Generated incident-form.component.ts"

echo "All TypeScript files generated successfully!"
