package com.svtrucking.logistics.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

@Configuration
public class FirebaseConfig {

  private static final Logger logger = LoggerFactory.getLogger(FirebaseConfig.class);

  @Value("${firebase.config.path:}")
  private String firebaseConfigPath;

  @Bean
  @ConditionalOnExpression(
      "T(org.springframework.util.StringUtils).hasText('${firebase.config.path:}') or "
          + "T(org.springframework.util.StringUtils).hasText('${GOOGLE_APPLICATION_CREDENTIALS:}')")
  FirebaseApp initializeFirebase() {
    try (InputStream serviceAccount = getFirebaseConfigStream()) {
      FirebaseOptions options =
          FirebaseOptions.builder()
              .setCredentials(GoogleCredentials.fromStream(serviceAccount))
              .build();

      logger.info("FirebaseApp initialized successfully.");
      return FirebaseApp.initializeApp(options);
    } catch (IOException e) {
      logger.error("Failed to initialize Firebase: {}", e.getMessage(), e);
      throw new IllegalStateException("Firebase configuration file is missing or invalid.", e);
    }
  }

  private InputStream getFirebaseConfigStream() throws IOException {
    String resolvedPath = resolveConfigPath();
    if (resolvedPath.startsWith("classpath:")) {
      String pathInClasspath = resolvedPath.replace("classpath:", "");
      logger.info("Loading Firebase config from classpath: {}", pathInClasspath);
      Resource resource = new ClassPathResource(pathInClasspath);
      if (!resource.exists()) {
        throw new IOException("File not found in classpath: " + pathInClasspath);
      }
      return resource.getInputStream();
    }

    logger.info("Loading Firebase config from filesystem: {}", resolvedPath);
    if (!Files.exists(Path.of(resolvedPath))) {
      throw new IOException("File not found at path: " + resolvedPath);
    }
    return new FileInputStream(resolvedPath);
  }

  private String resolveConfigPath() throws IOException {
    if (firebaseConfigPath != null && !firebaseConfigPath.isBlank()) {
      return firebaseConfigPath.trim();
    }

    String envPath = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
    if (envPath != null && !envPath.isBlank()) {
      logger.info("Using GOOGLE_APPLICATION_CREDENTIALS env var for Firebase config.");
      return envPath.trim();
    }

    throw new IOException(
        "Firebase configuration path not provided. "
            + "Set FIREBASE_CONFIG_PATH property or GOOGLE_APPLICATION_CREDENTIALS env variable.");
  }
}
