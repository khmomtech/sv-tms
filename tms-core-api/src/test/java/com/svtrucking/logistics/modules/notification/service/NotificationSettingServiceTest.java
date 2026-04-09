package com.svtrucking.logistics.modules.notification.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.modules.notification.model.NotificationChannel;
import com.svtrucking.logistics.modules.notification.model.NotificationSetting;
import com.svtrucking.logistics.modules.notification.repository.NotificationSettingRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class NotificationSettingServiceTest {

  private NotificationSettingRepository repository;
  private NotificationSettingService service;

  @BeforeEach
  void setUp() {
    repository = mock(NotificationSettingRepository.class);
    service = new NotificationSettingService(repository);
  }

  @Test
  void listAll_returnsRepositoryResults() {
    NotificationSetting setting = NotificationSetting.builder()
        .id(1L)
        .channel(NotificationChannel.EMAIL)
        .enabled(true)
        .thresholdDays(1)
        .thresholdKm(10)
        .recipientsJson("[\"a@b.com\"]")
        .build();

    when(repository.findAll()).thenReturn(List.of(setting));

    List<NotificationSetting> result = service.listAll();

    assertThat(result).hasSize(1);
    assertThat(result.get(0).getChannel()).isEqualTo(NotificationChannel.EMAIL);
  }

  @Test
  void updateByChannel_updatesExistingSetting() {
    NotificationSetting existing = NotificationSetting.builder()
        .id(1L)
        .channel(NotificationChannel.IN_APP)
        .enabled(false)
        .thresholdDays(2)
        .thresholdKm(20)
        .recipientsJson("[]")
        .build();

    NotificationSetting payload = NotificationSetting.builder()
        .enabled(true)
        .thresholdDays(3)
        .thresholdKm(30)
        .recipientsJson("[\"+123456789\"]")
        .build();

    when(repository.findByChannel(NotificationChannel.IN_APP)).thenReturn(Optional.of(existing));
    when(repository.save(any(NotificationSetting.class))).thenAnswer(invocation -> invocation.getArgument(0));

    NotificationSetting updated = service.updateByChannel(NotificationChannel.IN_APP, payload);

    assertThat(updated).isNotNull();
    assertThat(updated.isEnabled()).isTrue();
    assertThat(updated.getThresholdDays()).isEqualTo(3);
    assertThat(updated.getThresholdKm()).isEqualTo(30);
    assertThat(updated.getRecipientsJson()).isEqualTo("[\"+123456789\"]");

    verify(repository).findByChannel(NotificationChannel.IN_APP);
    verify(repository).save(eq(updated));
  }

  @Test
  void updateByChannel_createsNewSettingWhenNotFound() {
    NotificationSetting payload = NotificationSetting.builder()
        .enabled(true)
        .thresholdDays(5)
        .thresholdKm(50)
        .recipientsJson("[\"+987654321\"]")
        .build();

    when(repository.findByChannel(NotificationChannel.TELEGRAM)).thenReturn(Optional.empty());
    when(repository.save(any(NotificationSetting.class))).thenAnswer(invocation -> invocation.getArgument(0));

    NotificationSetting updated = service.updateByChannel(NotificationChannel.TELEGRAM, payload);

    assertThat(updated).isNotNull();
    assertThat(updated.getChannel()).isEqualTo(NotificationChannel.TELEGRAM);
    assertThat(updated.isEnabled()).isTrue();
    assertThat(updated.getThresholdDays()).isEqualTo(5);
    assertThat(updated.getThresholdKm()).isEqualTo(50);

    verify(repository).findByChannel(NotificationChannel.TELEGRAM);
    verify(repository).save(eq(updated));
  }
}
