package com.svtrucking.logistics.modules.reports.controller;

import com.svtrucking.logistics.modules.reports.dto.DispatchDayReportRow;
import com.svtrucking.logistics.modules.reports.repository.ReportRepository;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/reports")
public class ReportsController {

  private static final ZoneId PP_TZ = ZoneId.of("Asia/Phnom_Penh");
  private static final DateTimeFormatter DF_DATE = DateTimeFormatter.ofPattern("dd-MM-yyyy");
  private static final DateTimeFormatter DF_DATIME =
      DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm").withZone(PP_TZ);

  private final ReportRepository repo;

  public ReportsController(ReportRepository repo) {
    this.repo = repo;
  }

  // ===== Helpers =====
  private static LocalTime parseTimeOrNull(String t) {
    if (t == null || t.isBlank()) return null;
    String s = t.trim();
    // Accept "HH:mm" or "HH:mm:ss"
    return (s.length() == 5)
        ? LocalTime.parse(s, DateTimeFormatter.ofPattern("HH:mm"))
        : LocalTime.parse(s);
  }

  private static Instant buildInstant(LocalDate d, LocalTime t, ZoneId tz) {
    return d.atTime(t).atZone(tz).toInstant();
  }

  // ===== JSON =====
  @GetMapping("/dispatch/day")
  public List<DispatchDayReportRow> dispatchDay(
      @RequestParam LocalDate planFrom,
      @RequestParam LocalDate planTo,
      @RequestParam(required = false) String fromTime, // "HH:mm" or "HH:mm:ss"
      @RequestParam(required = false) String toTime, // "HH:mm" or "HH:mm:ss"
      @RequestParam(required = false) Integer toExtraDays // default 2 when toTime not provided
      ) {
    // Normalize date order if user flips them
    if (planTo.isBefore(planFrom)) {
      var tmp = planFrom;
      planFrom = planTo;
      planTo = tmp;
    }

    // If times provided, use them; otherwise pass null and let SQL defaults apply
    Instant fromTs = null;
    Instant toTs = null;

    LocalTime ft = parseTimeOrNull(fromTime);
    if (ft != null) {
      fromTs = buildInstant(planFrom, ft, PP_TZ);
    }

    LocalTime tt = parseTimeOrNull(toTime);
    if (tt != null) {
      toTs = buildInstant(planTo, tt, PP_TZ);
    }

    return repo.getDispatchDayReport(
        planFrom,
        planTo,
        fromTs, // may be null -> SQL COALESCE defaults to planFrom 00:00:00
        toTs, // may be null -> SQL COALESCE defaults to planTo 00:00:00 + :to_extra_days
        (toExtraDays == null ? 2 : toExtraDays));
  }

  // ===== CSV =====
  @GetMapping(value = "/dispatch/day/export", produces = "text/csv")
  public void exportCsv(
      @RequestParam LocalDate planFrom,
      @RequestParam LocalDate planTo,
      @RequestParam(required = false) String fromTime,
      @RequestParam(required = false) String toTime,
      @RequestParam(required = false) Integer toExtraDays,
      HttpServletResponse resp)
      throws IOException {

    var rows = dispatchDay(planFrom, planTo, fromTime, toTime, toExtraDays);

    resp.setCharacterEncoding(StandardCharsets.UTF_8.name());
    resp.setContentType("text/csv");
    resp.setHeader("Content-Disposition", "attachment; filename=dispatch-day-report.csv");

    try (PrintWriter w =
        new PrintWriter(new OutputStreamWriter(resp.getOutputStream(), StandardCharsets.UTF_8))) {
      w.println(
          "No,Plan Date,Truck No.,To Depot,Number of Pallets,Truck Type,Factory Departure,Depot Arrival,Planned Depot Arrival,Unloading Completed,Final Destination");

      int i = 1;
      for (var r : rows) {
        w.printf(
            "%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s%n",
            i++,
            r.planDate() != null ? r.planDate().format(DF_DATE) : "",
            safe(r.truckNo()),
            safe(r.depot()),
            r.numberOfPallets() != null ? r.numberOfPallets() : "",
            safe(r.truckType()),
            fmt(DF_DATIME, r.factoryDeparture()),
            fmt(DF_DATIME, r.depotArrival()),
            fmt(DF_DATIME, r.plannedDepotArrival()),
            fmt(DF_DATIME, r.unloadingComplete()),
            safe(r.finalDestinationText()));
      }
    }
  }

  // ===== Excel (XLSX) =====
  @GetMapping(
      value = "/dispatch/day/export.xlsx",
      produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  public void exportExcel(
      @RequestParam LocalDate planFrom,
      @RequestParam LocalDate planTo,
      @RequestParam(required = false) String fromTime,
      @RequestParam(required = false) String toTime,
      @RequestParam(required = false) Integer toExtraDays,
      HttpServletResponse resp)
      throws IOException {

    var rows = dispatchDay(planFrom, planTo, fromTime, toTime, toExtraDays);

    resp.setCharacterEncoding(StandardCharsets.UTF_8.name());
    resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    resp.setHeader("Content-Disposition", "attachment; filename=dispatch-day-report.xlsx");

    try (var wb = new org.apache.poi.xssf.usermodel.XSSFWorkbook();
        var out = resp.getOutputStream()) {

      var sheet = wb.createSheet("Dispatch Day");
      var createHelper = wb.getCreationHelper();

      var headerStyle = wb.createCellStyle();
      var bold = wb.createFont();
      bold.setBold(true);
      headerStyle.setFont(bold);

      var dateStyle = wb.createCellStyle();
      dateStyle.setDataFormat(createHelper.createDataFormat().getFormat("dd-mm-yyyy"));

      var dtStyle = wb.createCellStyle();
      dtStyle.setDataFormat(createHelper.createDataFormat().getFormat("dd-mm-yyyy hh:mm"));

      int r = 0;
      var header = sheet.createRow(r++);
      String[] cols = {
        "No",
        "Plan Date",
        "Truck No.",
        "To Depot",
        "Number of Pallets",
        "Truck Type",
        "Factory Departure",
        "Depot Arrival",
        "Planned Depot Arrival",
        "Unloading Completed",
        "Final Destination"
      };
      for (int c = 0; c < cols.length; c++) {
        var cell = header.createCell(c);
        cell.setCellValue(cols[c]);
        cell.setCellStyle(headerStyle);
      }

      int i = 1;
      for (var row : rows) {
        var x = sheet.createRow(r++);
        int c = 0;

        x.createCell(c++).setCellValue(i++);

        var planCell = x.createCell(c++);
        if (row.planDate() != null) {
          planCell.setCellValue(java.sql.Date.valueOf(row.planDate()));
          planCell.setCellStyle(dateStyle);
        } else planCell.setBlank();

        x.createCell(c++).setCellValue(safe(row.truckNo()));
        x.createCell(c++).setCellValue(safe(row.depot()));

        var palletsCell = x.createCell(c++);
        if (row.numberOfPallets() != null)
          palletsCell.setCellValue(row.numberOfPallets().doubleValue());
        else palletsCell.setBlank();

        x.createCell(c++).setCellValue(safe(row.truckType()));

        c = setInstantCell(x, c, row.factoryDeparture(), PP_TZ, dtStyle);
        c = setInstantCell(x, c, row.depotArrival(), PP_TZ, dtStyle);
        c = setInstantCell(x, c, row.plannedDepotArrival(), PP_TZ, dtStyle);
        c = setInstantCell(x, c, row.unloadingComplete(), PP_TZ, dtStyle);

        x.createCell(c).setCellValue(safe(row.finalDestinationText()));
      }

      for (int c = 0; c < cols.length; c++) sheet.autoSizeColumn(c);

      wb.write(out);
      out.flush();
    }
  }

  // ===== private helpers =====
  private static int setInstantCell(
      org.apache.poi.ss.usermodel.Row x,
      int c,
      Instant val,
      ZoneId tz,
      org.apache.poi.ss.usermodel.CellStyle style) {
    var cell = x.createCell(c++);
    if (val != null) {
      var zdt = java.time.ZonedDateTime.ofInstant(val, tz);
      var date = java.util.Date.from(zdt.toInstant());
      cell.setCellValue(date);
      cell.setCellStyle(style);
    } else {
      cell.setBlank();
    }
    return c;
  }

  private static String fmt(DateTimeFormatter f, Instant t) {
    return t == null ? "" : f.format(t);
  }

  private static String safe(String s) {
    return s == null ? "" : s.replace(",", " ");
  }
}
