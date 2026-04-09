import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { ActivatedRoute, convertToParamMap } from '@angular/router';
import { of, Subject } from 'rxjs';

import { WebSocketService } from '../../../services/websocket.service';
import {
  DriverChatConversationSummary,
  DriverChatEvent,
  DriverChatMessage,
  DriverChatService,
} from './driver-chat.service';
import { DriverMessagesComponent } from './driver-messages.component';

describe('DriverMessagesComponent', () => {
  let fixture: ComponentFixture<DriverMessagesComponent>;
  let component: DriverMessagesComponent;
  let chatService: jasmine.SpyObj<DriverChatService>;
  let webSocketService: jasmine.SpyObj<WebSocketService>;
  let realtime$: Subject<DriverChatEvent>;

  const conversation: DriverChatConversationSummary = {
    driverId: 99,
    driverName: 'Marcus Jenkins',
    phone: '010123456',
    employeeName: null,
    latestMessage: 'Initial support request',
    latestSenderRole: 'DRIVER',
    latestMessageAt: '2026-03-19T10:45:00',
    unreadDriverMessageCount: 1,
    totalMessageCount: 3,
  };

  const driverMessage: DriverChatMessage = {
    id: 1,
    driverId: 99,
    senderRole: 'DRIVER',
    sender: 'Marcus Jenkins',
    message: 'Initial support request',
    createdAt: '2026-03-19T10:45:00',
    read: false,
  };

  beforeEach(async () => {
    realtime$ = new Subject<DriverChatEvent>();
    chatService = jasmine.createSpyObj<DriverChatService>('DriverChatService', [
      'listConversations',
      'listMessages',
      'sendMessage',
      'markConversationRead',
    ]);
    webSocketService = jasmine.createSpyObj<WebSocketService>('WebSocketService', [
      'connectStomp',
      'subscribe',
    ]);

    chatService.listConversations.and.returnValue(of([conversation]));
    chatService.listMessages.and.returnValue(of([driverMessage]));
    chatService.markConversationRead.and.returnValue(of({ driverId: 99, updated: 1 }));
    chatService.sendMessage.and.returnValue(
      of({
        id: 2,
        driverId: 99,
        senderRole: 'ADMIN',
        sender: 'Admin',
        message: 'Reply from admin',
        createdAt: '2026-03-19T10:48:00',
        read: false,
      }),
    );
    webSocketService.subscribe.and.returnValue(realtime$.asObservable());

    await TestBed.configureTestingModule({
      imports: [
        DriverMessagesComponent,
        TranslateModule.forRoot({
          loader: { provide: TranslateLoader, useClass: TranslateFakeLoader },
        }),
      ],
      providers: [
        { provide: DriverChatService, useValue: chatService },
        { provide: WebSocketService, useValue: webSocketService },
        {
          provide: ActivatedRoute,
          useValue: {
            snapshot: {
              queryParamMap: convertToParamMap({ driverId: '99' }),
            },
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(DriverMessagesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('loads the selected conversation and existing messages on init', () => {
    expect(chatService.listConversations).toHaveBeenCalled();
    expect(chatService.listMessages).toHaveBeenCalledWith(99, 0, 30);
    expect(component.selectedConversation?.driverId).toBe(99);
    expect(component.messages.length).toBe(1);
    expect(component.messages[0].message).toBe('Initial support request');
    expect(webSocketService.connectStomp).toHaveBeenCalled();
    expect(webSocketService.subscribe).toHaveBeenCalledWith('/topic/admin-driver-chat');
  });

  it('applies realtime events to the open thread and unread summary', () => {
    realtime$.next({
      eventType: 'MESSAGE_CREATED',
      driverId: 99,
      message: {
        id: 3,
        driverId: 99,
        senderRole: 'DRIVER',
        sender: 'Marcus Jenkins',
        message: 'Realtime update from road',
        createdAt: '2026-03-19T10:49:00',
        read: false,
      },
      conversation: {
        ...conversation,
        latestMessage: 'Realtime update from road',
        latestMessageAt: '2026-03-19T10:49:00',
        unreadDriverMessageCount: 2,
        totalMessageCount: 4,
      },
    });

    expect(component.messages.map((item) => item.message)).toContain('Realtime update from road');
    expect(component.conversations[0].latestMessage).toBe('Realtime update from road');
    expect(chatService.markConversationRead).toHaveBeenCalledWith(99);
  });

  it('sends an admin reply and appends it to the thread', () => {
    component.selectedConversation = conversation;
    component.draftMessage = 'Reply from admin';

    component.sendMessage();

    expect(chatService.sendMessage).toHaveBeenCalledWith(99, 'Reply from admin');
    expect(component.messages[component.messages.length - 1].message).toBe('Reply from admin');
    expect(component.draftMessage).toBe('');
  });
});
