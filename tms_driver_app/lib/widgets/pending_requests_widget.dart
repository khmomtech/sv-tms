import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pending_requests_provider.dart';

class PendingRequestsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fetch requests when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PendingRequestsProvider>(context, listen: false)
          .fetchPendingRequests();
    });

    return Consumer<PendingRequestsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage.isNotEmpty) {
          return Center(
            child: Text(provider.errorMessage,
                style: const TextStyle(color: Colors.red)),
          );
        }

        if (provider.pendingRequests.isEmpty) {
          return Center(
            child: Text('No pending requests found.'),
          );
        }

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: provider.pendingRequests.map((request) {
              return ListTile(
                leading: const Icon(Icons.pending, color: Colors.orange),
                title: Text(request['type'] ?? 'Unknown'),
                subtitle: Text("Status: ${request["status"] ?? "Pending"}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Start: ${request["startDate"] ?? "--"}"),
                    Text("End: ${request["endDate"] ?? "--"}"),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
