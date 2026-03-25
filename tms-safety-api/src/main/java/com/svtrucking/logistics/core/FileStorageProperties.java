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

  /** Disk base directory. Can be relative ("uploads/") or absolute ("/opt/sv-tms/uploads"). */
  @Value("${file.upload.base-dir:uploads/}")
  private String baseDir;

  /** Public URL prefix that maps to baseDir via a ResourceHandler (e.g. "/uploads/"). */
  @Value("${file.upload.public-prefix:/uploads/}")
  private String publicPrefix;

  /** Subfolders (kept configurable). */
  @Value("${file.upload.dir.licenses:licenses/}")
  private String licensesDir;

  @Value("${file.upload.dir.profiles:profiles/}")
  private String profilesDir;

  @Value("${file.upload.dir.documents:documents/}")
  private String documentsDir;

  @Value("${file.upload.dir.thumbnails:thumbnails/}")
  private String thumbnailsDir; // stored under documents/thumbnails logically

  /** Configurable max width for generated thumbnails */
  @Value("${file.thumbnail.max-width:300}")
  private int thumbnailMaxWidth;

  /** Normalized base path on disk. */
  public Path getBasePath() {
    return Paths.get(baseDir).toAbsolutePath().normalize();
  }

  /** Resolve a subfolder safely under base. */
  public Path resolveSubdir(String subFolder) {
    String clean = subFolder == null ? "" : subFolder.replace("\\", "/");
    while (clean.startsWith("/")) clean = clean.substring(1);
    return getBasePath().resolve(clean).normalize();
  }

  /** Convenience resolvers. */
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
    // thumbnails live within documents/ for simpler public URL mapping
    return documentsPath().resolve(thumbnailsDir).normalize();
  }

  public int getThumbnailMaxWidth() {
    return thumbnailMaxWidth;
  }

  /** Build a public URL like /uploads/profiles/filename.jpg */
  public String publicUrl(String subFolder, String filename) {
    String prefix = ensureTrailingSlash(publicPrefix);
    String folder = ensureTrailingSlash(stripLeadingSlash(subFolder));
    return prefix + folder + filename;
  }

  @PostConstruct
  void ensureFoldersExist() {
    try {
      // Try to create directories, but don't fail if they already exist or we can't create them
      // (this handles Docker volume mounting scenarios)
      Files.createDirectories(profilesPath());
      Files.createDirectories(licensesPath());
      Files.createDirectories(documentsPath());
      Files.createDirectories(documentsThumbnailsPath());
    } catch (Exception e) {
      // Log the issue but don't fail startup - directories might be mounted via Docker volume
      System.err.println("Warning: Could not initialize upload folders: " + e.getMessage());
      System.err.println("This may be normal if using Docker volumes. Upload functionality will be checked at runtime.");
    }
  }

  // helpers
  private static String stripLeadingSlash(String s) {
    if (s == null) return "";
    while (s.startsWith("/")) s = s.substring(1);
    return s;
  }

  private static String ensureTrailingSlash(String s) {
    if (s == null || s.isEmpty()) return "/";
    return s.endsWith("/") ? s : (s + "/");
  }
}
