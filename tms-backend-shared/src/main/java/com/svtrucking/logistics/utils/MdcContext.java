package com.svtrucking.logistics.utils;

import org.slf4j.MDC;

public final class MdcContext {

  private MdcContext() {}

  public static void setDispatch(Long dispatchId, String routeCode) {
    if (dispatchId != null) {
      MDC.put("dispatchId", dispatchId.toString());
    }
    if (routeCode != null && !routeCode.isBlank()) {
      MDC.put("routeCode", routeCode);
    }
  }

  public static void setDriver(Long driverId) {
    if (driverId != null) {
      MDC.put("driverId", driverId.toString());
    }
  }

  public static void clear() {
    MDC.remove("dispatchId");
    MDC.remove("routeCode");
    MDC.remove("driverId");
  }
}
