package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.svtrucking.logistics.model.AppVersion;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AppVersionDto {

    @JsonProperty("id")
    Long id;

    // --- Global ---
    @JsonProperty("latestVersion")
    String latestVersion;

    @JsonProperty("mandatoryUpdate")
    boolean mandatoryUpdate;

    @JsonProperty("playstoreUrl")
    String playstoreUrl;

    @JsonProperty("appstoreUrl")
    String appstoreUrl;

    @JsonProperty("releaseNoteEn")
    String releaseNoteEn;

    @JsonProperty("releaseNoteKm")
    String releaseNoteKm;

    @JsonProperty("lastUpdated")
    String lastUpdatedIso; // ISO-8601 with offset, e.g. 2025-09-16T14:00:00+07:00

    // --- Android ---
    @JsonProperty("androidLatestVersion")
    String androidLatestVersion;

    @JsonProperty("androidMandatoryUpdate")
    boolean androidMandatoryUpdate;

    @JsonProperty("androidReleaseNoteEn")
    String androidReleaseNoteEn;

    @JsonProperty("androidReleaseNoteKm")
    String androidReleaseNoteKm;

    // --- iOS ---
    @JsonProperty("iosLatestVersion")
    String iosLatestVersion;

    @JsonProperty("iosMandatoryUpdate")
    boolean iosMandatoryUpdate;

    @JsonProperty("iosReleaseNoteEn")
    String iosReleaseNoteEn;

    @JsonProperty("iosReleaseNoteKm")
    String iosReleaseNoteKm;

    // --- Maintenance ---
    @JsonProperty("maintenanceActive")
    boolean maintenanceActive;

    @JsonProperty("maintenanceMessageEn")
    String maintenanceMessageEn;

    @JsonProperty("maintenanceMessageKm")
    String maintenanceMessageKm;

    @JsonProperty("maintenanceUntil")
    String maintenanceUntilIso; // ISO-8601 with offset, e.g. 2025-09-16T14:00:00+07:00

    // --- Info strip ---
    @JsonProperty("infoEn")
    String infoEn;

    @JsonProperty("infoKm")
    String infoKm;

    /**
     * Map entity -> DTO. Choose a zone (e.g. ZoneId.of("UTC") or server default).
     * If you want a
     * trailing 'Z', pass ZoneId.of("UTC").
     */
    public static AppVersionDto fromEntity(AppVersion e, ZoneId zone) {
        final DateTimeFormatter fmt = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

        String lastUpdated = e.getLastUpdated() == null ? null : e.getLastUpdated().atZone(zone).format(fmt);

        String maintenanceUntil = e.getMaintenanceUntil() == null ? null
                : e.getMaintenanceUntil().atZone(zone).format(fmt);

        return AppVersionDto.builder()
                .id(e.getId())
                .latestVersion(e.getLatestVersion())
                .mandatoryUpdate(e.isMandatoryUpdate())
                .playstoreUrl(e.getPlaystoreUrl())
                .appstoreUrl(e.getAppstoreUrl())
                .releaseNoteEn(nz(e.getReleaseNoteEn()))
                .releaseNoteKm(nz(e.getReleaseNoteKm()))
                .lastUpdatedIso(lastUpdated)
                .androidLatestVersion(nz(e.getAndroidLatestVersion()))
                .androidMandatoryUpdate(e.isAndroidMandatoryUpdate())
                .androidReleaseNoteEn(nz(e.getAndroidReleaseNoteEn()))
                .androidReleaseNoteKm(nz(e.getAndroidReleaseNoteKm()))
                .iosLatestVersion(nz(e.getIosLatestVersion()))
                .iosMandatoryUpdate(e.isIosMandatoryUpdate())
                .iosReleaseNoteEn(nz(e.getIosReleaseNoteEn()))
                .iosReleaseNoteKm(nz(e.getIosReleaseNoteKm()))
                .maintenanceActive(e.isMaintenanceActive())
                .maintenanceMessageEn(nz(e.getMaintenanceMessageEn()))
                .maintenanceMessageKm(nz(e.getMaintenanceMessageKm()))
                .maintenanceUntilIso(maintenanceUntil)
                .infoEn(nz(e.getInfoEn()))
                .infoKm(nz(e.getInfoKm()))
                .build();
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }
}
