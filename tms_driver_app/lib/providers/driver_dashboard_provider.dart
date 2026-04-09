// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../providers/driver_provider.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   GoogleMapController? _mapController;

//   @override
//   void initState() {
//     super.initState();
//     Provider.of<DriverProvider>(context, listen: false)
//         .initializeDriverSession();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final driverProvider = Provider.of<DriverProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Driver Dashboard"),
//         backgroundColor: Colors.blue,
//         actions: [
//           Switch(
//             value: driverProvider.isOnline,
//             onChanged: (value) {
//               driverProvider.isOnline = value;
//             },
//             activeColor: Colors.green,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: driverProvider.currentPosition != null
//                   ? LatLng(driverProvider.currentPosition!.latitude,
//                       driverProvider.currentPosition!.longitude)
//                   : LatLng(11.5564, 104.9282),
//               zoom: 14,
//             ),
//             markers: {
//               if (driverProvider.currentPosition != null)
//                 Marker(
//                   markerId: MarkerId("driver"),
//                   position: LatLng(driverProvider.currentPosition!.latitude,
//                       driverProvider.currentPosition!.longitude),
//                   infoWindow: InfoWindow(title: "Your Location"),
//                   icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueBlue),
//                 ),
//             },
//             onMapCreated: (controller) => _mapController = controller,
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             child: FloatingActionButton(
//               onPressed: () {
//                 driverProvider.updateDriverLocation();
//               },
//               child: Icon(Icons.my_location),
//               backgroundColor: Colors.green,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
