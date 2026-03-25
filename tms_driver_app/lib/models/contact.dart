// Legacy shim to preserve older imports. Re-export new model file.
export 'contact.dart';
class Contact {
  final int employeeId;
  final String fullName;
  final String?
      mobile; // Make mobile nullable since it might be null in the response

  Contact({
    required this.employeeId,
    required this.fullName,
    this.mobile,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      employeeId: json['employeeId'] as int,
      fullName:
          json['fullName'] as String? ?? 'Unknown', // Handle null for fullName
      mobile: json['mobile'] as String?, // Allow mobile to be nullable
    );
  }
}
