package com.svtrucking.logistics.dto.attendance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Request body for bulk permission (ON_LEAVE / OFF_DUTY) creation across a date range.
 * Dates are inclusive and formatted as yyyy-MM-dd.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class BulkPermissionRequest {
  private String fromDate; // yyyy-MM-dd
  private String toDate;   // yyyy-MM-dd
  private String status;   // ON_LEAVE or OFF_DUTY
  private String notes;    // optional

  public String getFromDate() { return fromDate; }
  public void setFromDate(String fromDate) { this.fromDate = fromDate; }
  public String getToDate() { return toDate; }
  public void setToDate(String toDate) { this.toDate = toDate; }
  public String getStatus() { return status; }
  public void setStatus(String status) { this.status = status; }
  public String getNotes() { return notes; }
  public void setNotes(String notes) { this.notes = notes; }
}
