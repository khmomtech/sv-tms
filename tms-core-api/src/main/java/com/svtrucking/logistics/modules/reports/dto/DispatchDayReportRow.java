package com.svtrucking.logistics.modules.reports.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public record DispatchDayReportRow(
    Long dispatchId,
    LocalDate planDate,
    String truckNo,
    String truckTrip,
    String depot,
    BigDecimal numberOfPallets,
    String truckType,
    Instant factoryDeparture,
    Instant depotArrival,
    Instant plannedDepotArrival,
    Instant unloadingComplete,
    String finalDestinationText) {}
