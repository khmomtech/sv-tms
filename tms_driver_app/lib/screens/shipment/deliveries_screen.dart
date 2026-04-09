// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/delivery_provider.dart';

// class DeliveriesScreen extends StatelessWidget {
//   const DeliveriesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final deliveryProvider = Provider.of<DeliveryProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title:
//             const Text("ការដឹកជញ្ជូន", style: TextStyle(color: Colors.white)),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: deliveryProvider.deliveries.isEmpty
//           ? const Center(child: Text("មិនមានការដឹកជញ្ជូន!"))
//           : ListView.builder(
//               itemCount: deliveryProvider.deliveries.length,
//               itemBuilder: (context, index) {
//                 final delivery = deliveryProvider.deliveries[index];

//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   child: ListTile(
//                     leading: Icon(Icons.local_shipping,
//                         color: Theme.of(context).primaryColor),
//                     title: Text("TASK ID: ${delivery['taskId']}"),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Pickup: ${delivery['pickup']}"),
//                         Text("Drop-off: ${delivery['dropoff']}"),
//                         Text("Status: ${delivery['status']}",
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: delivery['status'] == 'Delivered'
//                                     ? Colors.green
//                                     : Colors.orange)),
//                       ],
//                     ),
//                     trailing: PopupMenuButton<String>(
//                       onSelected: (value) {
//                         if (value == 'update') {
//                           deliveryProvider.updateDeliveryStatus(
//                               delivery['taskId'], 'On the way');
//                         } else if (value == 'delivered') {
//                           deliveryProvider.updateDeliveryStatus(
//                               delivery['taskId'], 'Delivered');
//                         }
//                       },
//                       itemBuilder: (context) => [
//                         const PopupMenuItem(
//                             value: 'update', child: Text("ជើងដឹកការ")),
//                         const PopupMenuItem(
//                             value: 'delivered', child: Text("បានដឹកជូន")),
//                       ],
//                       child: const Icon(Icons.more_vert),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => GoogleMapScreen(
//                             pickupLocation: delivery['pickupCoordinates'],
//                             dropoffLocation: delivery['dropoffCoordinates'],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
