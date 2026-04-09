package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@Builder
public class ImportError {
  private final int row; // 1-based Excel row index
  private final String groupKey; // e.g. 14.08.2025_C1000023_CA7_3
  private final String field; // e.g. itemCode
  private final String value; // e.g. CPD000103
  private final String message; // e.g. Item not found
}
