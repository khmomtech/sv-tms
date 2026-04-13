import { ActivatedRoute } from '@angular/router';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';

import { ConfirmService } from '../../../services/confirm.service';
import { ItemService } from '../../../services/item.service';
import { ItemComponent } from './item.component';

describe('ItemComponent filter behavior', () => {
  let fixture: ComponentFixture<ItemComponent>;
  let component: ItemComponent;

  const itemServiceMock = {
    getAllItems: jasmine.createSpy('getAllItems').and.returnValue(of([])),
  };

  const confirmServiceMock = {
    confirm: jasmine.createSpy('confirm').and.resolveTo(true),
  };

  const translateServiceMock = {
    instant: jasmine.createSpy('instant').and.callFake((key: string) => key),
    get: jasmine.createSpy('get').and.callFake((key: string) => of(key)),
    stream: jasmine.createSpy('stream').and.callFake((key: string) => of(key)),
    onLangChange: of(),
    onTranslationChange: of(),
    onDefaultLangChange: of(),
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ItemComponent],
      providers: [
        { provide: ItemService, useValue: itemServiceMock },
        { provide: ConfirmService, useValue: confirmServiceMock },
        { provide: TranslateService, useValue: translateServiceMock },
        { provide: ActivatedRoute, useValue: { snapshot: { data: {} } } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ItemComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();

    component.items = [
      {
        id: 1,
        itemCode: 'CPD000001',
        itemName: 'Cambodia Beer Draught',
        itemNameKh: '',
        itemType: 'OTHERS',
        quantity: 1,
        unit: 'Pcs',
        weight: '1.5',
        status: 1,
        sortOrder: 0,
      },
      {
        id: 2,
        itemCode: 'CPD000002',
        itemName: 'Full CO2 Cylinder',
        itemNameKh: '',
        itemType: 'GAS',
        quantity: 1,
        unit: 'Pcs',
        weight: '1.6',
        status: 0,
        sortOrder: 0,
      },
    ] as any;
    component.filteredItems = [...component.items];
  });

  it('filters by keyword when no sort is active', () => {
    component.keyword = 'co2';

    component.searchItems();

    expect(component.filteredItems.length).toBe(1);
    expect(component.filteredItems[0].itemCode).toBe('CPD000002');
  });

  it('combines status and type filters', () => {
    component.filterStatus = '1';
    component.filterType = 'others';

    component.searchItems();

    expect(component.filteredItems.length).toBe(1);
    expect(component.filteredItems[0].itemCode).toBe('CPD000001');
  });

  it('clears filters back to the full dataset', () => {
    component.keyword = 'co2';
    component.searchItems();

    component.clearFilters();

    expect(component.keyword).toBe('');
    expect(component.filterStatus).toBe('');
    expect(component.filterType).toBe('');
    expect(component.filteredItems.length).toBe(2);
  });
});
