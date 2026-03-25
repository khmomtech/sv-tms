import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/screens/shipment/home/home_state.dart';

class CurrentTripSection extends StatelessWidget {
  const CurrentTripSection({
    required this.trip,
    super.key,
  });

  final HomeCurrentTripVm? trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8DFEB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.local_shipping,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('home.trip.title'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (trip == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  context.tr('home.trip.empty'),
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            else
              _TripBody(trip: trip!),
          ],
        ),
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.trip});

  final HomeCurrentTripVm trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/images/map_placeholder.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          trip.loadNumber.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.routeLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        context.tr('home.trip.eta'),
                        style: const TextStyle(color: Colors.black45),
                      ),
                      Text(
                        trip.etaLabel,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: trip.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: const Color(0xFFE8ECF4),
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                trip.progressLabel,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
