import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DriverVehicleComponent } from './tabs/driver-vehicle.component';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';

describe('DriverVehicleComponent (focused)', () => {
  let component: DriverVehicleComponent;
  let fixture: ComponentFixture<DriverVehicleComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        MatFormFieldModule,
        MatInputModule,
        MatAutocompleteModule,
        MatButtonModule,
        DriverVehicleComponent,
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(DriverVehicleComponent);
    component = fixture.componentInstance;
    // minimal inputs
    component.driverData = { id: 1, assignedVehicleId: null } as any;
    component.allVehicles = [
      { id: 10, licensePlate: 'ABC-123', model: 'Model X', type: 'TRUCK' } as any,
      { id: 11, licensePlate: 'XYZ-999', model: 'Model Y', type: 'VAN' } as any,
    ];
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('assign button is disabled when no selection', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const btn = compiled.querySelector('button') as HTMLButtonElement;
    expect(btn).toBeTruthy();
    expect(btn.disabled).toBeTrue();
  });

  it('enables assign button when a different vehicle is selected', async () => {
    component.selectedVehicleId = 10;
    // component.driverData.assignedVehicleId = null;
    fixture.detectChanges();
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    const btn = compiled.querySelector('button') as HTMLButtonElement;
    expect(btn.disabled).toBeFalse();
  });
});
