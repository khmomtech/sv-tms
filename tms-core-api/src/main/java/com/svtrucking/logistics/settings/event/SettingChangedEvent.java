package com.svtrucking.logistics.settings.event;

import org.springframework.context.ApplicationEvent;

public class SettingChangedEvent extends ApplicationEvent {
  public final String groupCode;
  public final String keyCode;
  public final String scope;
  public final String scopeRef;

  public SettingChangedEvent(
      Object src, String groupCode, String keyCode, String scope, String scopeRef) {
    super(src);
    this.groupCode = groupCode;
    this.keyCode = keyCode;
    this.scope = scope;
    this.scopeRef = scopeRef;
  }
}
