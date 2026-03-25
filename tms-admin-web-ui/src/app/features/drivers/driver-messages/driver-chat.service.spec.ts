import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { DriverChatService } from './driver-chat.service';

describe('DriverChatService', () => {
  let service: DriverChatService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [DriverChatService],
    });
    service = TestBed.inject(DriverChatService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('lists conversations from the admin driver chat endpoint', () => {
    service.listConversations().subscribe();

    const req = httpMock.expectOne('/api/admin/driver-chat/conversations');
    expect(req.request.method).toBe('GET');
    req.flush([]);
  });

  it('sends messages to the selected driver conversation', () => {
    service.sendMessage(42, 'Route updated').subscribe();

    const req = httpMock.expectOne('/api/admin/driver-chat/42/send');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ message: 'Route updated' });
    req.flush({
      id: 1,
      driverId: 42,
      senderRole: 'ADMIN',
      sender: 'Admin',
      message: 'Route updated',
      createdAt: '2026-03-19T10:00:00',
      read: false,
    });
  });
});
