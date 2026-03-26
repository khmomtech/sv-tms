//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:openapi/api.dart';
import 'package:test/test.dart';


/// tests for DispatchAdminControllerApi
void main() {
  // final instance = DispatchAdminControllerApi();

  group('tests for DispatchAdminControllerApi', () {
    //Future<ApiResponseDispatchDto> acceptDispatch1(int id) async
    test('test acceptDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignDispatch1(int id, int driverId, int vehicleId) async
    test('test assignDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignDriverOnly1(int id, int driverId) async
    test('test assignDriverOnly1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignTruckOnly1(int id, int vehicleId) async
    test('test assignTruckOnly1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> changeDriver1(int id, int driverId) async
    test('test changeDriver1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> changeTruck1(int id, int vehicleId) async
    test('test changeTruck1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> createDispatch1(DispatchDto dispatchDto) async
    test('test createDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseVoid> deleteDispatch1(int id) async
    test('test deleteDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseLoadProofDto> driverSubmitLoadProof1(int dispatchId, List<MultipartFile> images, { String remarks, MultipartFile signature }) async
    test('test driverSubmitLoadProof1', () async {
      // TODO
    });

    //Future<ApiResponsePageDispatchDto> filterDispatches1(Pageable pageable, { int driverId, int vehicleId, String status, String driverName, String routeCode, String q, String customerName, String destinationTo, String truckPlate, String tripNo, DateTime start, DateTime end }) async
    test('test filterDispatches1', () async {
      // TODO
    });

    //Future<ApiResponsePageDispatchDto> getAllDispatches1(Pageable pageable) async
    test('test getAllDispatches1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> getDispatchById1(int id) async
    test('test getDispatchById1', () async {
      // TODO
    });

    //Future<ApiResponseListDispatchStatusHistoryDto> getDispatchStatusHistory1(int id) async
    test('test getDispatchStatusHistory1', () async {
      // TODO
    });

    //Future<PageDispatchDto> getDispatchesByDriverWithDateRange1(int driverId, Pageable pageable, { DateTime from, DateTime to }) async
    test('test getDispatchesByDriverWithDateRange1', () async {
      // TODO
    });

    //Future<PageDispatchDto> getDispatchesByDriverWithStatusFilter1(int driverId, Pageable pageable, { String status }) async
    test('test getDispatchesByDriverWithStatusFilter1', () async {
      // TODO
    });

    //Future<ApiResponseListLoadProofDto> getFilteredLoadProofs1({ String search, String driver, String route, DateTime from, DateTime to }) async
    test('test getFilteredLoadProofs1', () async {
      // TODO
    });

    //Future<ApiResponseString> importBulkDispatches1(MultipartFile file) async
    test('test importBulkDispatches1', () async {
      // TODO
    });

    //Future<Object> markAsUnloaded1(int dispatchId, { String remarks, String address, double latitude, double longitude, MarkAsUnloadedRequest markAsUnloadedRequest }) async
    test('test markAsUnloaded1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> notifyAssignedDriver1(int id) async
    test('test notifyAssignedDriver1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> planTrip1(Map<String, Object> requestBody) async
    test('test planTrip1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> rejectDispatch1(int id, String reason) async
    test('test rejectDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseLoadProofDto> submitLoadProof1(int dispatchId, List<MultipartFile> images, { String remarks, MultipartFile signature }) async
    test('test submitLoadProof1', () async {
      // TODO
    });

    //Future<ApiResponseUnloadProofDto> submitUnloadProof1(int dispatchId, { String remarks, String address, double latitude, double longitude, List<MultipartFile> images, MultipartFile signature }) async
    test('test submitUnloadProof1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> updateDispatch1(int id, DispatchDto dispatchDto) async
    test('test updateDispatch1', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> updateDispatchStatus1(int id, String status) async
    test('test updateDispatchStatus1', () async {
      // TODO
    });

  });
}
