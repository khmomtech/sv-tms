package com.svtrucking.logistics.websocket;

import static org.assertj.core.api.Assertions.assertThat;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.socket.sockjs.client.SockJsClient;
import org.springframework.web.socket.sockjs.client.Transport;
import org.springframework.web.socket.sockjs.client.WebSocketTransport;

@EnabledIfSystemProperty(named = "includeWebsocketIT", matches = "true")
@ActiveProfiles("ws-integration")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class DriverLocationWebSocketTest {

  @LocalServerPort private int port;

  @Test
  public void testWebSocketConnection() throws Exception {
    // Create WebSocket client
    List<Transport> transports = new ArrayList<>();
    transports.add(new WebSocketTransport(new StandardWebSocketClient()));
    SockJsClient sockJsClient = new SockJsClient(transports);

    // Create WebSocket handler
    CountDownLatch connectedLatch = new CountDownLatch(1);
    CountDownLatch messageLatch = new CountDownLatch(1);
    TextWebSocketHandler handler =
        new TextWebSocketHandler() {
          @Override
          public void afterConnectionEstablished(
              org.springframework.web.socket.WebSocketSession session) throws Exception {
            connectedLatch.countDown();
            session.sendMessage(
                new TextMessage(
                    "{\"driverId\":1,\"latitude\":11.6268899,\"longitude\":104.8917588}"));
          }

          @Override
          protected void handleTextMessage(
              org.springframework.web.socket.WebSocketSession session, TextMessage message) {
            messageLatch.countDown();
          }
        };

    // Connect to WebSocket
    WebSocketHttpHeaders headers = new WebSocketHttpHeaders();
    URI uri = new URI("ws://localhost:" + port + "/ws");

    ListenableFuture<WebSocketSession> future = sockJsClient.doHandshake(handler, headers, uri);
    WebSocketSession session = future.get(5, TimeUnit.SECONDS);

    assertThat(session.isOpen()).isTrue();
    assertThat(connectedLatch.await(5, TimeUnit.SECONDS)).isTrue();
    // We only assert that the connection stays open long enough to send; handlers may not echo
    session.close();
  }
}
