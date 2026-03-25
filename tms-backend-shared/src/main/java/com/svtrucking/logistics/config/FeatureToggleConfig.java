package com.svtrucking.logistics.config;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.features")
public class FeatureToggleConfig {
  private boolean polRequired = false;
  private boolean dispatchWorkflowEmergencyBypass = false;
  private boolean safetyCheckBlockingEnabled = false;
  private boolean bayAllocationEnabled = false;
  private boolean queuePositionTrackingEnabled = false;
  private boolean loadingSessionEnabled = false;
  private boolean approvalGateEnabled = false;
  private boolean podPhotoReviewRequired = false;
  private boolean closureSlaTrackingEnabled = false;
  private int closureSlaTargetMinutes = 120;
  private boolean rejectionRemarksRequired = false;
  private boolean podReworkEnabled = false;
  private boolean preEntrySafetyCheckEnabled = false;
  private boolean safetySignatureRequired = false;
  private boolean safetyConditionalOverrideEnabled = false;
  private boolean qrCodeScanningEnabled = false;
  private boolean safetyPhotoCaptureEnabled = false;
  private boolean enforcePreEntrySafetyGate = false;
  private Set<String> preEntrySafetyRequiredWarehouses =
      new LinkedHashSet<>(List.of("KHB", "W1"));
  private boolean closureMonitorDashboardEnabled = false;
  private boolean warehousePortalEnabled = false;
  private boolean fieldCheckerAppEnabled = false;
  private boolean liveQueueTrackingEnabled = false;
  private boolean closurePendingNotificationsEnabled = false;
  private boolean bulkApprovalEnabled = false;
  private boolean financialLockingEnabled = false;
  private boolean detailedAuditTrailEnabled = false;
  private boolean roleBasedApprovalRoutingEnabled = false;
  private boolean managerPreApprovalRequired = false;
  private boolean financialReconciliationReportEnabled = false;
  private boolean customerNotificationsEnabled = false;
  private boolean driverPushNotificationsEnabled = false;
  private boolean whatsappNotificationsEnabled = false;
  private boolean gpsTrackingEnabled = false;
  private boolean geofenceMonitoringEnabled = false;
  private boolean temperatureMonitoringEnabled = false;
  private boolean damageAssessmentEnabled = false;
  private boolean deliveryTimeWindowEnforcementEnabled = false;
}
