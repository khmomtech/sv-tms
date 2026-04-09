package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * DTO for creating driver documents.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DriverDocumentCreateDto {

    private String name;
    private String category;
    private LocalDate expiryDate;
    private String description;
    private Boolean isRequired;
    private String fileUrl;
}