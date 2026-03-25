package com.svtrucking.logistics.infrastructure.files;

import com.svtrucking.logistics.core.FileStorageProperties;
import java.io.IOException;
import java.nio.file.*;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class FileStorageService {

  private final FileStorageProperties
      fileStorageProperties; //  Fix: `@Autowired` not needed with Lombok's @RequiredArgsConstructor

  /** Store a file in the root uploads directory. */
  public String storeFile(MultipartFile file) {
    return storeFileInSubfolder(file, "");
  }

  /** Store a file inside a specific subfolder (e.g., "profiles", "licenses", etc.). */
  public String storeFileInSubfolder(MultipartFile file, String subFolder) {
    String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
    String fileName = UUID.randomUUID() + "_" + originalFileName;

    try {
      if (fileName.contains("..")) {
        throw new RuntimeException("Invalid path sequence in filename: " + fileName);
      }

      // Use the proper base path from FileStorageProperties
      Path basePath = fileStorageProperties.getBasePath();
      Path uploadDir = fileStorageProperties.resolveSubdir(subFolder);

      Files.createDirectories(uploadDir);

      // Target file location
      Path targetLocation = uploadDir.resolve(fileName);
      Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

      // Return path for client use
      return fileStorageProperties.publicUrl(subFolder, fileName);

    } catch (IOException ex) {
      throw new RuntimeException("Could not store file: " + fileName, ex);
    }
  }
}
