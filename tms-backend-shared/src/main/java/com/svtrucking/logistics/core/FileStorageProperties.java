package com.svtrucking.logistics.core;

import jakarta.annotation.PostConstruct;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
@Getter
public class FileStorageProperties {

  @Value("${file.upload.base-dir:uploads/}")
  private String baseDir;

  @Value("${file.upload.public-prefix:/uploads/}")
  private String publicPrefix;

  @Value("${file.upload.dir.licenses:licenses/}")
  private String licensesDir;

  @Value("${file.upload.dir.profiles:profiles/}")
  private String profilesDir;

  @Value("${file.upload.dir.documents:documents/}")
  private String documentsDir;

  @Value("${file.upload.dir.thumbnails:thumbnails/}")
  private String thumbnailsDir;

  @Value("${file.thumbnail.max-width:300}")
  private int thumbnailMaxWidth;

  public Path getBasePath() {
    return Paths.get(baseDir).toAbsolutePath().normalize();
  }

  public Path resolveSubdir(String subFolder) {
    String clean = subFolder == null ? "" : subFolder.replace("\\", "/");
    while (clean.startsWith("/")) {
      clean = clean.substring(1);
    }
    return getBasePath().resolve(clean).normalize();
  }

  public Path profilesPath() {
    return resolveSubdir(profilesDir);
  }

  public Path licensesPath() {
    return resolveSubdir(licensesDir);
  }

  public Path documentsPath() {
    return resolveSubdir(documentsDir);
  }

  public Path documentsThumbnailsPath() {
    return documentsPath().resolve(thumbnailsDir).normalize();
  }

  public int getThumbnailMaxWidth() {
    return thumbnailMaxWidth;
  }

  public String publicUrl(String subFolder, String filename) {
    String prefix = ensureTrailingSlash(publicPrefix);
    String folder = ensureTrailingSlash(stripLeadingSlash(subFolder));
    return prefix + folder + filename;
  }

  @PostConstruct
  void ensureFoldersExist() {
    try {
      Files.createDirectories(profilesPath());
      Files.createDirectories(licensesPath());
      Files.createDirectories(documentsPath());
      Files.createDirectories(documentsThumbnailsPath());
    } catch (Exception e) {
      System.err.println("Warning: Could not initialize upload folders: " + e.getMessage());
      System.err.println(
          "This may be normal if using Docker volumes. Upload functionality will be checked at runtime.");
    }
  }

  private static String stripLeadingSlash(String value) {
    if (value == null) {
      return "";
    }
    while (value.startsWith("/")) {
      value = value.substring(1);
    }
    return value;
  }

  private static String ensureTrailingSlash(String value) {
    if (value == null || value.isEmpty()) {
      return "/";
    }
    return value.endsWith("/") ? value : (value + "/");
  }
}
