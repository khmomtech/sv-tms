package com.svtrucking.logistics.dto;

class ImportIssue {
  private int row;
  private String column; // e.g., "B12"
  private String field; // e.g., "deliveryDate"
  private String value; // offending value
  private String message; // friendly message
  private String code; // e.g., INVALID_DATE, NOT_FOUND
  private String groupKey; // optional composite key

  ImportIssue(
      int row,
      String column,
      String field,
      String value,
      String message,
      String code,
      String groupKey) {
    this.row = row;
    this.column = column;
    this.field = field;
    this.value = value;
    this.message = message;
    this.code = code;
    this.groupKey = groupKey;
  }

  public int getRow() {
    return row;
  }

  public String getColumn() {
    return column;
  }

  public String getField() {
    return field;
  }

  public String getValue() {
    return value;
  }

  public String getMessage() {
    return message;
  }

  public String getCode() {
    return code;
  }

  public String getGroupKey() {
    return groupKey;
  }
}
