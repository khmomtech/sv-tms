package com.svtrucking.logistics.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ItemFilterDto {
    public String q;
    public Long ownerId;
    public String status;
    public LocalDate from;
    public LocalDate to;
    public String sort;
}
