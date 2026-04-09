package com.svtrucking.logistics.service;

import com.svtrucking.logistics.config.FeatureToggleConfig;
import com.svtrucking.logistics.dto.PreEntrySafetyCheckDto;
import com.svtrucking.logistics.dto.request.PreEntrySafetyCheckSubmitRequest;
import com.svtrucking.logistics.dto.request.SafetyConditionalOverrideRequest;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.LoadingQueueStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.enums.WarehouseCode;
import com.svtrucking.logistics.exception.InvalidDispatchDataException;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.LoadingQueue;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.PreEntrySafetyCheck;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.LoadingQueueRepository;
import com.svtrucking.logistics.repository.PreEntryCheckMasterItemRepository;
import com.svtrucking.logistics.repository.PreEntrySafetyCheckRepository;
import com.svtrucking.logistics.repository.PreEntrySafetyItemRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockMultipartFile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PreEntrySafetyCheckServiceTest {

  private PreEntrySafetyCheckService service;
  private PreEntrySafetyCheckRepository safetyCheckRepository;
  private PreEntryCheckMasterItemRepository preEntryCheckMasterItemRepository;
  private PreEntrySafetyItemRepository safetyItemRepository;
  private DispatchRepository dispatchRepository;
  private VehicleRepository vehicleRepository;
  private DriverRepository driverRepository;
  private LoadingQueueRepository loadingQueueRepository;
  private LoadingWorkflowService loadingWorkflowService;
  private DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
  private FileStorageService fileStorageService;
  private AuthenticatedUserUtil authenticatedUserUtil;
  private FeatureToggleConfig featureToggleConfig;

  @BeforeEach
  void setup() {
    safetyCheckRepository = Mockito.mock(PreEntrySafetyCheckRepository.class);
    preEntryCheckMasterItemRepository = Mockito.mock(PreEntryCheckMasterItemRepository.class);
    safetyItemRepository = Mockito.mock(PreEntrySafetyItemRepository.class);
    dispatchRepository = Mockito.mock(DispatchRepository.class);
    vehicleRepository = Mockito.mock(VehicleRepository.class);
    driverRepository = Mockito.mock(DriverRepository.class);
    loadingQueueRepository = Mockito.mock(LoadingQueueRepository.class);
    loadingWorkflowService = Mockito.mock(LoadingWorkflowService.class);
    dispatchStatusHistoryRepository = Mockito.mock(DispatchStatusHistoryRepository.class);
    fileStorageService = Mockito.mock(FileStorageService.class);
    authenticatedUserUtil = Mockito.mock(AuthenticatedUserUtil.class);
    featureToggleConfig = Mockito.mock(FeatureToggleConfig.class);

    when(preEntryCheckMasterItemRepository.findActiveCategoryCodesWithActiveItems())
        .thenReturn(List.of("LOAD", "DOCUMENTS", "WINDSHIELD"));

    service =
        new PreEntrySafetyCheckService(
            safetyCheckRepository,
            preEntryCheckMasterItemRepository,
            safetyItemRepository,
            dispatchRepository,
            vehicleRepository,
            driverRepository,
            loadingQueueRepository,
            loadingWorkflowService,
            dispatchStatusHistoryRepository,
            fileStorageService,
            authenticatedUserUtil,
            featureToggleConfig);
  }

  @Test
  void submitSafetyCheck_setsFailedWhenAnyItemFailed() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    vehicle.setLicensePlate("2A-1234");

    Driver driver = new Driver();
    driver.setId(300L);
    driver.setFirstName("Dara");
    driver.setLastName("Kim");

    User checker = checkerUser(900L, "checker.user");

    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(dispatchRepository.findById(100L)).thenReturn(Optional.of(dispatch));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(safetyCheckRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checker);
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("FAILED");

    PreEntrySafetyCheckDto result = service.submitSafetyCheck(request);

    assertEquals("FAILED", result.getStatus());
    assertEquals("IN_QUEUE", result.getDispatchStatusAfterCheck());
    assertEquals(Boolean.FALSE, result.getAutoTransitionApplied());
    verify(safetyItemRepository, times(1)).saveAll(any());
    verify(dispatchRepository, times(1)).save(any(Dispatch.class));
    verify(safetyCheckRepository, times(2)).save(any(PreEntrySafetyCheck.class));
  }

  @Test
  void submitSafetyCheck_rejectsWhenDispatchAlreadyHasCheck() {
    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(dispatchRepository.findById(100L)).thenReturn(Optional.of(new Dispatch()));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(new Vehicle()));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(new Driver()));
    when(safetyCheckRepository.findByDispatchId(100L))
        .thenReturn(Optional.of(PreEntrySafetyCheck.builder().id(1L).build()));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("OK");

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.submitSafetyCheck(request));

    assertEquals("dispatchId", ex.getField());
  }

  @Test
  void submitSafetyCheck_passedInQueueKhb_autoTransitionsToLoading() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);
    Dispatch dispatchAfter = new Dispatch();
    dispatchAfter.setId(100L);
    dispatchAfter.setStatus(DispatchStatus.LOADING);

    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    vehicle.setLicensePlate("2A-1234");

    Driver driver = new Driver();
    driver.setId(300L);
    driver.setFirstName("Dara");
    driver.setLastName("Kim");

    User checker = checkerUser(900L, "checker.user");
    LoadingQueue queue = LoadingQueue.builder()
        .id(7L)
        .dispatch(dispatch)
        .status(LoadingQueueStatus.WAITING)
        .warehouseCode(WarehouseCode.KHB)
        .build();

    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(featureToggleConfig.getPreEntrySafetyRequiredWarehouses()).thenReturn(Set.of("KHB"));
    when(dispatchRepository.findById(100L))
        .thenReturn(Optional.of(dispatch))
        .thenReturn(Optional.of(dispatchAfter));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(safetyCheckRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checker);
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));
    when(loadingQueueRepository.findByDispatchId(100L)).thenReturn(Optional.of(queue));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("OK");

    PreEntrySafetyCheckDto result = service.submitSafetyCheck(request);

    assertEquals("PASSED", result.getStatus());
    assertEquals("LOADING", result.getDispatchStatusAfterCheck());
    assertEquals(Boolean.TRUE, result.getAutoTransitionApplied());
    verify(loadingWorkflowService).callToBay(7L, null, "Auto-called after pre-entry PASS");
    verify(loadingWorkflowService).startLoading(any());
    verify(dispatchStatusHistoryRepository).save(any());
  }

  @Test
  void submitSafetyCheck_passedWithoutQueue_throwsConflictMessage() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    Driver driver = new Driver();
    driver.setId(300L);

    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(featureToggleConfig.getPreEntrySafetyRequiredWarehouses()).thenReturn(Set.of("KHB"));
    when(dispatchRepository.findById(100L)).thenReturn(Optional.of(dispatch));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(safetyCheckRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checkerUser(900L, "checker.user"));
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));
    when(loadingQueueRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("OK");

    IllegalStateException ex = assertThrows(IllegalStateException.class, () -> service.submitSafetyCheck(request));
    assertEquals("Queue entry required before pre-entry PASS can transition to loading.", ex.getMessage());
    verify(loadingWorkflowService, times(0)).startLoading(any());
  }

  @Test
  void approveConditionalOverride_updatesToPassed() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(777L);

    Role role = new Role();
    role.setName(RoleType.ADMIN);

    User checker = checkerUser(901L, "checker2");
    User approver = new User();
    approver.setId(902L);
    approver.setUsername("admin.user");
    approver.setEmail("admin@test.local");
    approver.setRoles(Set.of(role));

    Vehicle vehicle = new Vehicle();
    vehicle.setId(400L);
    vehicle.setLicensePlate("2B-8888");

    Driver driver = new Driver();
    driver.setId(500L);
    driver.setFirstName("Sok");
    driver.setLastName("Nim");

    PreEntrySafetyCheck safetyCheck = PreEntrySafetyCheck.builder()
        .id(55L)
        .dispatch(dispatch)
        .vehicle(vehicle)
        .driver(driver)
        .status(PreEntrySafetyStatus.CONDITIONAL)
        .checkedBy(checker)
        .build();

    when(safetyCheckRepository.findById(55L)).thenReturn(Optional.of(safetyCheck));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(approver);
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));

    SafetyConditionalOverrideRequest request = SafetyConditionalOverrideRequest.builder()
        .safetyCheckId(55L)
        .decision("APPROVED")
        .remarks("Minor issue accepted by supervisor")
        .build();

    PreEntrySafetyCheckDto result = service.approveConditionalOverride(request);

    assertEquals("PASSED", result.getStatus());
    verify(dispatchRepository).save(dispatch);
  }

  @Test
  void approveConditionalOverride_rejectsWhenStatusIsPassedAlready() {
    PreEntrySafetyCheck safetyCheck = PreEntrySafetyCheck.builder()
        .id(56L)
        .status(PreEntrySafetyStatus.PASSED)
        .build();

    when(safetyCheckRepository.findById(56L)).thenReturn(Optional.of(safetyCheck));

    SafetyConditionalOverrideRequest request = SafetyConditionalOverrideRequest.builder()
        .safetyCheckId(56L)
        .decision("APPROVED")
        .remarks("not used")
        .build();

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.approveConditionalOverride(request));

    assertEquals("status", ex.getField());
  }

  @Test
  void approveConditionalOverride_requiresRemarks() {
    PreEntrySafetyCheck safetyCheck = PreEntrySafetyCheck.builder()
        .id(57L)
        .status(PreEntrySafetyStatus.FAILED)
        .build();

    when(safetyCheckRepository.findById(57L)).thenReturn(Optional.of(safetyCheck));

    SafetyConditionalOverrideRequest request = SafetyConditionalOverrideRequest.builder()
        .safetyCheckId(57L)
        .decision("APPROVED")
        .remarks("   ")
        .build();

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.approveConditionalOverride(request));

    assertEquals("remarks", ex.getField());
  }

  @Test
  void getById_returnsCheck() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);

    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    vehicle.setLicensePlate("2A-1234");

    Driver driver = new Driver();
    driver.setId(300L);
    driver.setFirstName("Dara");
    driver.setLastName("Kim");

    PreEntrySafetyCheck check = PreEntrySafetyCheck.builder()
        .id(77L)
        .dispatch(dispatch)
        .vehicle(vehicle)
        .driver(driver)
        .status(PreEntrySafetyStatus.PASSED)
        .build();

    when(safetyCheckRepository.findById(77L)).thenReturn(Optional.of(check));

    PreEntrySafetyCheckDto result = service.getById(77L);
    assertEquals(77L, result.getId());
    assertEquals("PASSED", result.getStatus());
  }

  @Test
  void updateSafetyCheck_replacesItemsAndUpdatesDispatchStatus() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);

    Vehicle oldVehicle = new Vehicle();
    oldVehicle.setId(150L);
    Driver oldDriver = new Driver();
    oldDriver.setId(250L);

    PreEntrySafetyCheck check = PreEntrySafetyCheck.builder()
        .id(90L)
        .dispatch(dispatch)
        .vehicle(oldVehicle)
        .driver(oldDriver)
        .status(PreEntrySafetyStatus.FAILED)
        .build();

    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    Driver driver = new Driver();
    driver.setId(300L);
    User checker = checkerUser(901L, "checker.new");

    when(safetyCheckRepository.findById(90L)).thenReturn(Optional.of(check));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checker);
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));
    when(dispatchRepository.save(any(Dispatch.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("OK");
    PreEntrySafetyCheckDto result = service.updateSafetyCheck(90L, request);

    assertEquals("PASSED", result.getStatus());
    verify(safetyItemRepository).deleteBySafetyCheckId(90L);
    verify(safetyItemRepository).saveAll(any());
    verify(dispatchRepository).save(dispatch);
  }

  @Test
  void updateSafetyCheck_rejectsDispatchMismatch() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);

    PreEntrySafetyCheck check = PreEntrySafetyCheck.builder()
        .id(91L)
        .dispatch(dispatch)
        .build();

    when(safetyCheckRepository.findById(91L)).thenReturn(Optional.of(check));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequest("OK");
    request.setDispatchId(999L);

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.updateSafetyCheck(91L, request));
    assertEquals("dispatchId", ex.getField());
  }

  @Test
  void deleteSafetyCheck_resetsDispatchStatus() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setPreEntrySafetyStatus(PreEntrySafetyStatus.PASSED);
    dispatch.setStatus(DispatchStatus.IN_QUEUE);

    PreEntrySafetyCheck check = PreEntrySafetyCheck.builder()
        .id(92L)
        .dispatch(dispatch)
        .status(PreEntrySafetyStatus.PASSED)
        .build();

    when(safetyCheckRepository.findById(92L)).thenReturn(Optional.of(check));

    service.deleteSafetyCheck(92L);

    verify(safetyItemRepository).deleteBySafetyCheckId(92L);
    verify(safetyCheckRepository).delete(check);
    verify(dispatchRepository).save(dispatch);
    assertEquals(PreEntrySafetyStatus.NOT_STARTED, dispatch.getPreEntrySafetyStatus());
  }

  @Test
  void deleteSafetyCheck_throwsWhenMissing() {
    when(safetyCheckRepository.findById(93L)).thenReturn(Optional.empty());
    assertThrows(ResourceNotFoundException.class, () -> service.deleteSafetyCheck(93L));
  }

  @Test
  void deleteSafetyCheck_rejectsWhenDispatchAlreadyLoading() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    dispatch.setStatus(DispatchStatus.LOADING);

    PreEntrySafetyCheck check = PreEntrySafetyCheck.builder()
        .id(94L)
        .dispatch(dispatch)
        .status(PreEntrySafetyStatus.PASSED)
        .build();

    when(safetyCheckRepository.findById(94L)).thenReturn(Optional.of(check));

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.deleteSafetyCheck(94L));
    assertEquals("status", ex.getField());
  }

  @Test
  void listSafetyChecks_appliesStatusAndWarehouseFilters() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(1L);
    Vehicle vehicle = new Vehicle();
    vehicle.setId(2L);
    Driver driver = new Driver();
    driver.setId(3L);

    PreEntrySafetyCheck passedKHB = PreEntrySafetyCheck.builder()
        .id(100L)
        .dispatch(dispatch)
        .vehicle(vehicle)
        .driver(driver)
        .warehouseCode("KHB")
        .checkDate(java.time.LocalDate.of(2026, 3, 3))
        .status(PreEntrySafetyStatus.PASSED)
        .build();
    PreEntrySafetyCheck failedBTB = PreEntrySafetyCheck.builder()
        .id(101L)
        .dispatch(dispatch)
        .vehicle(vehicle)
        .driver(driver)
        .warehouseCode("BTB")
        .checkDate(java.time.LocalDate.of(2026, 3, 3))
        .status(PreEntrySafetyStatus.FAILED)
        .build();

    when(safetyCheckRepository.findForList(
        PreEntrySafetyStatus.PASSED,
        "khb",
        java.time.LocalDate.of(2026, 3, 1),
        java.time.LocalDate.of(2026, 3, 31))).thenReturn(List.of(passedKHB));

    List<PreEntrySafetyCheckDto> results = service.listSafetyChecks(
        PreEntrySafetyStatus.PASSED,
        "khb",
        java.time.LocalDate.of(2026, 3, 1),
        java.time.LocalDate.of(2026, 3, 31),
        null);

    assertEquals(1, results.size());
    assertEquals(100L, results.get(0).getId());
  }

  @Test
  void submitSafetyCheck_rejectsWhenRequiredCategoryMissing() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    Driver driver = new Driver();
    driver.setId(300L);

    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(dispatchRepository.findById(100L)).thenReturn(Optional.of(dispatch));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(safetyCheckRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checkerUser(900L, "checker.user"));
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequestWithItems(
        List.of(
            PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
                .category("TIRES")
                .itemName("Front left tire")
                .status("OK")
                .build()));

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.submitSafetyCheck(request));
    assertEquals("items", ex.getField());
  }

  @Test
  void submitSafetyCheck_requiresRemarksForFailedOrConditional() {
    Dispatch dispatch = new Dispatch();
    dispatch.setId(100L);
    Vehicle vehicle = new Vehicle();
    vehicle.setId(200L);
    Driver driver = new Driver();
    driver.setId(300L);

    when(featureToggleConfig.isSafetyCheckBlockingEnabled()).thenReturn(true);
    when(dispatchRepository.findById(100L)).thenReturn(Optional.of(dispatch));
    when(vehicleRepository.findById(200L)).thenReturn(Optional.of(vehicle));
    when(driverRepository.findById(300L)).thenReturn(Optional.of(driver));
    when(safetyCheckRepository.findByDispatchId(100L)).thenReturn(Optional.empty());
    when(authenticatedUserUtil.getCurrentUser()).thenReturn(checkerUser(900L, "checker.user"));
    when(safetyCheckRepository.save(any(PreEntrySafetyCheck.class))).thenAnswer(inv -> inv.getArgument(0));

    PreEntrySafetyCheckSubmitRequest request = buildSubmitRequestWithItems(List.of(
        PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
            .category("TIRES")
            .itemName("Front left tire")
            .status("FAILED")
            .remarks("   ")
            .build(),
        safetyItem("LIGHTS", "Front lights", "OK"),
        safetyItem("LOAD", "Load securement", "OK"),
        safetyItem("DOCUMENTS", "Documents", "OK"),
        safetyItem("WEIGHT", "Axle weight", "OK"),
        safetyItem("BRAKES", "Brake response", "OK"),
        safetyItem("WINDSHIELD", "Windshield visibility", "OK")));

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.submitSafetyCheck(request));
    assertEquals("items[0].remarks", ex.getField());
  }

  @Test
  void uploadInspectionPhoto_returnsStoredUrlWhenValidImage() {
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "proof.jpg",
        "image/jpeg",
        "binary-data".getBytes());

    when(fileStorageService.storeFileInSubfolder(any(), Mockito.eq("pre-entry-safety")))
        .thenReturn("/uploads/pre-entry-safety/proof.jpg");

    String url = service.uploadInspectionPhoto(file);
    assertEquals("/uploads/pre-entry-safety/proof.jpg", url);
    verify(fileStorageService).storeFileInSubfolder(any(), Mockito.eq("pre-entry-safety"));
  }

  @Test
  void uploadInspectionPhoto_rejectsUnsupportedMimeType() {
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "proof.txt",
        "text/plain",
        "not-an-image".getBytes());

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.uploadInspectionPhoto(file));
    assertEquals("file", ex.getField());
  }

  @Test
  void uploadInspectionPhoto_rejectsOversizedImage() {
    byte[] oversized = new byte[5 * 1024 * 1024 + 1];
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "big.png",
        "image/png",
        oversized);

    InvalidDispatchDataException ex =
        assertThrows(InvalidDispatchDataException.class, () -> service.uploadInspectionPhoto(file));
    assertEquals("file", ex.getField());
  }

  private PreEntrySafetyCheckSubmitRequest buildSubmitRequest(String itemStatus) {
    return buildSubmitRequestWithItems(List.of(
        safetyItem("TIRES", "Front left tire", itemStatus),
        safetyItem("LIGHTS", "Front lights", "OK"),
        safetyItem("LOAD", "Load securement", "OK"),
        safetyItem("DOCUMENTS", "Documents", "OK"),
        safetyItem("WEIGHT", "Axle weight", "OK"),
        safetyItem("BRAKES", "Brake response", "OK"),
        safetyItem("WINDSHIELD", "Windshield visibility", "OK")));
  }

  private PreEntrySafetyCheckSubmitRequest buildSubmitRequestWithItems(
      List<PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit> items) {
    return PreEntrySafetyCheckSubmitRequest.builder()
        .dispatchId(100L)
        .vehicleId(200L)
        .driverId(300L)
        .warehouseCode("W1")
        .remarks("Gate inspection")
        .items(items)
        .inspectionPhotoUrls(List.of("/uploads/overall.jpg"))
        .checkerSignatureUrl("/uploads/signature.png")
        .build();
  }

  private PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit safetyItem(
      String category,
      String itemName,
      String status) {
    return PreEntrySafetyCheckSubmitRequest.SafetyItemSubmit.builder()
        .category(category)
        .itemName(itemName)
        .status(status)
        .remarks("checked")
        .photoUrl("/uploads/" + category.toLowerCase() + ".jpg")
        .build();
  }

  private User checkerUser(Long id, String username) {
    Role role = new Role();
    role.setName(RoleType.SAFETY);

    User user = new User();
    user.setId(id);
    user.setUsername(username);
    user.setEmail(username + "@test.local");
    user.setRoles(Set.of(role));
    return user;
  }
}
