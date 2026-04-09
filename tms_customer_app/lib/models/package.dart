class PackageItem {
  final String itemType;
  final int qty;
  final double? weightKg;
  final double cod;

  PackageItem({
    required this.itemType,
    this.qty = 1,
    this.weightKg,
    this.cod = 0.0,
  });

  PackageItem copyWith(
      {String? itemType, int? qty, double? weightKg, double? cod}) {
    return PackageItem(
      itemType: itemType ?? this.itemType,
      qty: qty ?? this.qty,
      weightKg: weightKg ?? this.weightKg,
      cod: cod ?? this.cod,
    );
  }

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      itemType: json['itemType'] as String? ?? 'PARCEL',
      qty: json['qty'] is int
          ? json['qty'] as int
          : (json['qty'] != null
              ? int.tryParse(json['qty'].toString()) ?? 1
              : 1),
      weightKg: json['weightKg'] != null
          ? double.tryParse(json['weightKg'].toString())
          : null,
      cod: json['cod'] is num
          ? (json['cod'] as num).toDouble()
          : (json['cod'] != null
              ? double.tryParse(json['cod'].toString()) ?? 0.0
              : 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType,
      'qty': qty,
      'weightKg': weightKg,
      'cod': cod,
    };
  }

  @override
  String toString() => 'Package($itemType x$qty cod=$cod)';
}
