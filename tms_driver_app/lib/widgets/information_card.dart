import 'package:flutter/material.dart';

/// A compact, reusable Key–Value card (ideal for driver, vehicle, docs, etc.)
class InformationCard extends StatelessWidget {
  final String title;

  /// Map<label, value>. Null/empty values will render as “-”.
  final Map<String, String?> items;
  final EdgeInsetsGeometry margin;

  const InformationCard({
    super.key,
    required this.title,
    required this.items,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ...items.entries.map((e) => _InfoTile(label: e.key, value: e.value)),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoTile({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
