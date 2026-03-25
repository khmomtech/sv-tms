package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.AppVersion;
import com.svtrucking.logistics.repository.AppVersionRepository;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AppVersionService {

  private final AppVersionRepository appVersionRepository;

  public AppVersionService(AppVersionRepository appVersionRepository) {
    this.appVersionRepository = appVersionRepository;
  }

  public AppVersion getLatestVersion() {
    return appVersionRepository.findTopByOrderByLastUpdatedDesc();
  }

  public List<AppVersion> getAllVersions() {
    return appVersionRepository.findAllByOrderByLastUpdatedDesc();
  }

  public AppVersion saveAppVersion(AppVersion appVersion) {
    appVersion.setLastUpdated(LocalDateTime.now());
    return appVersionRepository.save(appVersion);
  }
}
