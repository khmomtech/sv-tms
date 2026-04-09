package com.svtrucking.logistics.modules.notification.queue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.ListOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class NotificationQueueServiceTest {

  private RedisTemplate<String, Object> redisTemplate;
  private ListOperations<String, Object> listOperations;
  private NotificationQueueService service;
  private com.fasterxml.jackson.databind.ObjectMapper objectMapper;

  @BeforeEach
  void setUp() {
    redisTemplate = mock(RedisTemplate.class);
    listOperations = mock(ListOperations.class);
    when(redisTemplate.opsForList()).thenReturn(listOperations);

    objectMapper = mock(com.fasterxml.jackson.databind.ObjectMapper.class);

    service = new NotificationQueueService(redisTemplate, objectMapper);
    ReflectionTestUtils.setField(service, "cachedQueueEnabled", true);
    ReflectionTestUtils.setField(service, "queueKey", "notifications:test");
  }

  @Test
  void enqueue_whenEnabled_pushesPayloadToRedisAndReturnsTrue() {
    NotificationPayload payload = new NotificationPayload();
    boolean result = service.enqueue(payload);

    assertThat(result).isTrue();
    verify(listOperations).leftPush(eq("notifications:test"), eq(payload));
    assertThat(payload.getCreatedAt()).isNotNull();
  }

  @Test
  void enqueue_whenDisabledReturnsFalseAndDoesNotCallRedis() {
    ReflectionTestUtils.setField(service, "cachedQueueEnabled", false);
    NotificationPayload payload = new NotificationPayload();

    boolean result = service.enqueue(payload);

    assertThat(result).isFalse();
  }

  @Test
  void poll_whenPayloadIsPresent_returnsPayload() {
    NotificationPayload payload = NotificationPayload.builder().message("hi").build();
    when(listOperations.rightPop("notifications:test")).thenReturn(payload);

    NotificationPayload result = service.poll();

    assertThat(result).isEqualTo(payload);
  }

  @Test
  void poll_whenPayloadIsWrongType_returnsNull() {
    when(listOperations.rightPop("notifications:test")).thenReturn("not_a_payload");

    NotificationPayload result = service.poll();

    assertThat(result).isNull();
  }

  @Test
  void queueDepth_whenRedisThrows_returnsNegativeOne() {
    when(listOperations.size("notifications:test")).thenThrow(new RuntimeException("boom"));

    long depth = service.queueDepth();

    assertThat(depth).isEqualTo(-1);
  }

  @Test
  void purgeAll_whenKeyExists_deletesAndReturnsSize() {
    when(listOperations.size("notifications:test")).thenReturn(5L);

    long removed = service.purgeAll();

    assertThat(removed).isEqualTo(5);
    verify(redisTemplate).delete("notifications:test");
  }

  @Test
  void purgeAll_whenRedisThrows_returnsNegativeOne() {
    doThrow(new RuntimeException("boom")).when(redisTemplate).delete(any(String.class));

    long removed = service.purgeAll();

    assertThat(removed).isEqualTo(-1);
  }
}
