import 'package:flutter_test/flutter_test.dart';
import 'package:tms_customer_app/models/booking.dart';
import 'package:tms_customer_app/models/package.dart';

void main() {
  test('PackageItem JSON roundtrip', () {
    final p = PackageItem(itemType: 'BOX', qty: 3, weightKg: 12.5, cod: 15.0);
    final json = p.toJson();
    final restored = PackageItem.fromJson(json);
    expect(restored.itemType, equals(p.itemType));
    expect(restored.qty, equals(p.qty));
    expect(restored.weightKg, equals(p.weightKg));
    expect(restored.cod, equals(p.cod));
  });

  test('Booking JSON roundtrip with packages', () {
    final now = DateTime.now();
    final booking = Booking(
      id: 'b1',
      title: 'Test',
      pickupAddress: 'A',
      dropoffAddress: 'B',
      createdAt: now,
      packages: [PackageItem(itemType: 'BOX', qty: 2, weightKg: 5.0, cod: 0.0)],
      serviceType: 'FTL',
      truckType: '6-Wheel',
      pickupCompany: 'Warehouse A',
      destinationCompany: 'Warehouse B',
      cargoType: 'General Goods',
      totalWeightTons: 0.01,
      totalVolumeCbm: 0.5,
      palletCount: 1,
      containerNo: null,
      specialHandlingNotes: 'None',
      receiverName: 'Receiver',
      receiverPhone: '+85512345678',
    );

    final json = booking.toJson();
    final restored = Booking.fromJson({
      ...json,
      // ensure createdAt and pickupDateTime are strings
      'createdAt': booking.createdAt.toIso8601String(),
      'pickupDateTime': booking.pickupDateTime?.toIso8601String(),
    });

    expect(restored.id, equals(booking.id));
    expect(restored.title, equals(booking.title));
    expect(restored.packages?.length, equals(1));
    expect(restored.serviceType, equals(booking.serviceType));
    expect(restored.truckType, equals(booking.truckType));
    expect(restored.pickupCompany, equals(booking.pickupCompany));
    expect(restored.receiverPhone, equals(booking.receiverPhone));
  });
}
