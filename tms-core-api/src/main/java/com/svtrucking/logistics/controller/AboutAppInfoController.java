package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.AboutAppInfo;
import com.svtrucking.logistics.service.AboutAppInfoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
public class AboutAppInfoController {

  private final AboutAppInfoService aboutAppInfoService;

  public AboutAppInfoController(AboutAppInfoService aboutAppInfoService) {
    this.aboutAppInfoService = aboutAppInfoService;
  }

  @GetMapping("/about-app")
  public ResponseEntity<AboutAppInfo> getAboutInfo() {
    return ResponseEntity.ok(aboutAppInfoService.getInfo());
  }

  @PostMapping("/about-app")
  public ResponseEntity<AboutAppInfo> saveAboutInfo(@RequestBody AboutAppInfo info) {
    return ResponseEntity.ok(aboutAppInfoService.saveInfo(info));
  }
}
