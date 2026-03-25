package com.svtrucking.logistics.config.mongo;

import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.MongoException;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import java.util.concurrent.TimeUnit;
import org.bson.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.env.Environment;
import org.springframework.core.type.AnnotatedTypeMetadata;

class LocationMongoAvailabilityCondition implements Condition {

    private static final Logger LOG =
      LoggerFactory.getLogger(LocationMongoAvailabilityCondition.class);
  private static final int SERVER_SELECTION_TIMEOUT_MS = 2_000;

  @Override
  public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
    Environment env = context.getEnvironment();
    boolean enabled = Boolean.parseBoolean(env.getProperty("location.mongo.enabled", "false"));
    if (!enabled) {
      LOG.debug("Mongo dual-write disabled because location.mongo.enabled=false");
      return false;
    }
    String uri = env.getProperty("location.mongo.uri");
    if (uri == null || uri.isBlank()) {
      LOG.warn(
          "Mongo dual-write is enabled but location.mongo.uri is not configured; skipping Mongo support");
      return false;
    }

    try (MongoClient sanityClient =
        MongoClients.create(
            MongoClientSettings.builder()
                .applyConnectionString(new ConnectionString(uri))
                .applyToClusterSettings(
                    builder ->
                        builder.serverSelectionTimeout(
                            SERVER_SELECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS))
                .build())) {
      sanityClient.getDatabase("admin").runCommand(new Document("ping", 1));
      LOG.info("Mongo dual-write connection validated for {}", uri);
      return true;
    } catch (MongoException ex) {
      LOG.warn(
          "Mongo dual-write skipped ({}): {}; disable location.mongo.enabled or start Mongo at {}",
          uri,
          ex.getMessage(),
          uri);
      return false;
    }
  }
}
