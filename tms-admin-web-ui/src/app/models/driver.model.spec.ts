// @ts-nocheck
import { mapToDriverCreateDto } from './driver.model';

describe('Driver model mapping', () => {
  it('maps partnerCompanyId when provided', () => {
    const form: any = {
      firstName: 'Jane',
      lastName: 'Doe',
      phone: '012',
      isPartner: true,
      partnerCompanyId: 123,
    };
    const dto = mapToDriverCreateDto(form);
    expect(dto.partner).toBe(true);
    expect(dto.partnerCompanyId).toBe(123);
  });

  it('omits partnerCompanyId when null/undefined', () => {
    const dto1 = mapToDriverCreateDto({
      firstName: 'A',
      lastName: 'B',
      phone: '1',
      isPartner: true,
    });
    expect((dto1 as any).partnerCompanyId).toBeUndefined();

    const dto2 = mapToDriverCreateDto({
      firstName: 'A',
      lastName: 'B',
      phone: '1',
      isPartner: true,
      partnerCompanyId: null,
    } as any);
    expect((dto2 as any).partnerCompanyId).toBeUndefined();
  });
});
