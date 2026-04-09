import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import {
  NotificationSettingsService,
  type NotificationSetting,
} from '../../services/notification-settings.service';
import { NotificationService } from '../../services/notification.service';
import { SettingsService, type SettingReadResponse } from '../../services/settings.service';

type PushProvider = 'fcm' | 'kafka' | 'none';

interface PushProviderSettings {
  provider: PushProvider;
  queueEnabled: boolean;
  kafkaTopic: string;
  kafkaCallTopic: string;
  // change-reason is required by the SettingService audit trail
  changeReason: string;
  // track which fields are saving
  saving: boolean;
  // last saved info
  savedAt: string | null;
  savedBy: string | null;
}

@Component({
  selector: 'app-notification-settings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './notification-settings.component.html',
  styleUrls: ['./notification-settings.component.css'],
})
export class NotificationSettingsComponent implements OnInit {
  // ── Expiry / channel settings (TELEGRAM, EMAIL, IN_APP) ─────────────────
  settings: NotificationSetting[] = [];

  // ── Push provider settings (FCM / Kafka / none) ──────────────────────────
  pushSettings: PushProviderSettings = {
    provider: 'fcm',
    queueEnabled: true,
    kafkaTopic: 'notifications.push',
    kafkaCallTopic: 'notifications.call',
    changeReason: '',
    saving: false,
    savedAt: null,
    savedBy: null,
  };
  pushLoading = false;
  pushError: string | null = null;

  readonly providerOptions: { value: PushProvider; label: string; description: string }[] = [
    {
      value: 'fcm',
      label: 'Firebase (FCM)',
      description: 'Direct send via Firebase Cloud Messaging. Requires FIREBASE_CONFIG_PATH.',
    },
    {
      value: 'kafka',
      label: 'Kafka',
      description:
        'Publish to Kafka topic. A downstream worker forwards to FCM/APNS. '
        + 'Better throughput and resilience when Firebase is unreachable.',
    },
    {
      value: 'none',
      label: 'None (disabled)',
      description: 'Suppress all push notifications. Use in local dev / CI environments.',
    },
  ];

  constructor(
    private readonly channelSettingsService: NotificationSettingsService,
    private readonly settingsService: SettingsService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    this.loadChannelSettings();
    this.loadPushProviderSettings();
  }

  // ── Channel settings (TELEGRAM / EMAIL / IN_APP) ─────────────────────────

  loadChannelSettings(): void {
    this.channelSettingsService.list().subscribe({
      next: (res) => (this.settings = res?.data ?? []),
      error: () => this.notify.error('Failed to load notification channel settings'),
    });
  }

  saveChannel(setting: NotificationSetting): void {
    this.channelSettingsService.update(setting.channel, setting).subscribe({
      next: () => this.notify.success(`${setting.channel} notification setting saved`),
      error: () => this.notify.error(`Failed to save ${setting.channel} setting`),
    });
  }

  // ── Push provider settings ────────────────────────────────────────────────

  loadPushProviderSettings(): void {
    this.pushLoading = true;
    this.pushError = null;

    this.settingsService.listValues('notification').subscribe({
      next: (rows: SettingReadResponse[]) => {
        const get = (key: string) => rows.find((r) => r.keyCode === key);

        const providerRow    = get('push.provider');
        const queueRow       = get('queue.enabled');
        const topicRow       = get('kafka.topic');
        const callTopicRow   = get('kafka.call-topic');

        this.pushSettings = {
          ...this.pushSettings,
          provider:       (providerRow?.value  as PushProvider) ?? 'fcm',
          queueEnabled:   queueRow?.value === true || queueRow?.value === 'true',
          kafkaTopic:     (topicRow?.value     as string) ?? 'notifications.push',
          kafkaCallTopic: (callTopicRow?.value as string) ?? 'notifications.call',
          savedAt:        providerRow?.updatedAt ?? null,
          savedBy:        providerRow?.updatedBy ?? null,
        };
        this.pushLoading = false;
      },
      error: (err) => {
        // If the notification group isn't seeded yet, show a soft warning
        this.pushError = 'Could not load push provider settings. '
          + 'Ensure the notification settings group is seeded in the database.';
        this.pushLoading = false;
      },
    });
  }

  savePushProvider(): void {
    if (!this.pushSettings.changeReason?.trim()) {
      this.notify.error('A change reason is required for audit trail.');
      return;
    }

    this.pushSettings.saving = true;

    const upserts = [
      { keyCode: 'push.provider',    value: this.pushSettings.provider },
      { keyCode: 'queue.enabled',    value: String(this.pushSettings.queueEnabled) },
      { keyCode: 'kafka.topic',      value: this.pushSettings.kafkaTopic },
      { keyCode: 'kafka.call-topic', value: this.pushSettings.kafkaCallTopic },
    ];

    // Run all upserts sequentially (could be parallelised with forkJoin but
    // sequential is easier to error-handle one-by-one here)
    const reason = this.pushSettings.changeReason.trim();
    let completed = 0;
    let failed = false;

    for (const u of upserts) {
      this.settingsService.upsert({
        groupCode: 'notification',
        keyCode:   u.keyCode,
        scope:     'GLOBAL',
        value:     u.value,
        reason,
      }).subscribe({
        next: (saved) => {
          completed++;
          if (u.keyCode === 'push.provider') {
            this.pushSettings.savedAt  = saved.updatedAt ?? null;
            this.pushSettings.savedBy  = saved.updatedBy ?? null;
          }
          if (completed === upserts.length && !failed) {
            this.pushSettings.saving       = false;
            this.pushSettings.changeReason = '';
            this.notify.success('Push provider settings saved. Change takes effect immediately.');
          }
        },
        error: (err) => {
          failed = true;
          this.pushSettings.saving = false;
          this.notify.error(`Failed to save ${u.keyCode}: ${err?.message ?? 'Unknown error'}`);
        },
      });
    }
  }
}
