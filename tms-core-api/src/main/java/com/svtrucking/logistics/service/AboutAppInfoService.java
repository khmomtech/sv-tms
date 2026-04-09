package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.AboutAppInfo;
import com.svtrucking.logistics.repository.AboutAppInfoRepository;
import org.springframework.stereotype.Service;

@Service
public class AboutAppInfoService {

  private final AboutAppInfoRepository aboutAppInfoRepository;

  public AboutAppInfoService(AboutAppInfoRepository aboutAppInfoRepository) {
    this.aboutAppInfoRepository = aboutAppInfoRepository;
  }

  public AboutAppInfo getInfo() {
    return aboutAppInfoRepository.findAll().stream().findFirst().orElse(null);
  }

  public AboutAppInfo saveInfo(AboutAppInfo info) {
    if (info.getId() == null && aboutAppInfoRepository.count() > 0) {
      AboutAppInfo existing = aboutAppInfoRepository.findAll().get(0);
      info.setId(existing.getId()); // Make sure update instead of creating new
    }
    return aboutAppInfoRepository.save(info);
  }
}
