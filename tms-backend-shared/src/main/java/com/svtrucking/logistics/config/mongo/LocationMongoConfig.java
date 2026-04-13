package com.svtrucking.logistics.config.mongo;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.svtrucking.logistics.mongo.document.DriverLocationHistoryDocument;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.MongoTransactionManager;
import org.springframework.data.mongodb.config.AbstractMongoClientConfiguration;
import org.springframework.data.mongodb.core.MongoOperations;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.data.mongodb.core.index.IndexOperations;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@Slf4j
@Configuration
@EnableConfigurationProperties(LocationMongoProperties.class)
@ConditionalOnProperty(name = "location.mongo.enabled", havingValue = "true")
@Conditional(LocationMongoAvailabilityCondition.class)
@EnableMongoRepositories(
    basePackages = "com.svtrucking.logistics.mongo.repository",
    mongoTemplateRef = "locationMongoTemplate")
public class LocationMongoConfig extends AbstractMongoClientConfiguration {

  private final LocationMongoProperties props;

  public LocationMongoConfig(LocationMongoProperties props) {
    this.props = props;
  }

  @Override
  protected String getDatabaseName() {
    return props.getDatabase();
  }

  @Override
  public MongoClient mongoClient() {
    if (props.getUri() == null || props.getUri().isBlank()) {
      throw new IllegalStateException(
          "location.mongo.enabled=true but no location.mongo.uri provided");
    }
    log.info(
        "Mongo dual-write enabled -> connecting to MongoDB database={} uri={}",
        props.getDatabase(),
        props.getUri());
    return MongoClients.create(props.getUri());
  }

  @Bean(name = "locationMongoTemplate")
  public MongoTemplate mongoTemplate() {
    MongoTemplate template = new MongoTemplate(mongoClient(), getDatabaseName());
    ensureIndexes(template);
    return template;
  }

  @Bean(name = "locationMongoTransactionManager")
  public MongoTransactionManager locationMongoTransactionManager(MongoDatabaseFactory dbFactory) {
    return new MongoTransactionManager(dbFactory);
  }

  private void ensureIndexes(MongoOperations operations) {
    IndexOperations indexOps = operations.indexOps(DriverLocationHistoryDocument.COLLECTION);
    indexOps.ensureIndex(
        new Index()
            .on("driverId", org.springframework.data.domain.Sort.Direction.ASC)
            .on("eventTime", org.springframework.data.domain.Sort.Direction.DESC)
            .background());
    indexOps.ensureIndex(
        new Index()
            .on("dispatchId", org.springframework.data.domain.Sort.Direction.ASC)
            .on("eventTime", org.springframework.data.domain.Sort.Direction.DESC)
            .background());

    if (props.getTtlDays() > 0) {
      long seconds = props.getTtlDays() * 24L * 3600L;
      indexOps.ensureIndex(
          new Index()
              .on("createdAt", org.springframework.data.domain.Sort.Direction.DESC)
              .expire(seconds)
              .background());
      log.info("TTL index enabled on Mongo driver history: {} days", props.getTtlDays());
    } else {
      log.info("TTL index disabled for Mongo driver history (ttlDays <= 0)");
    }
  }
}
