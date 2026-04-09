import 'package:flutter/material.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const shipments = '/shipments';
  static const incidents = '/incidents';
  static const bookings = '/bookings';
  static const notifications = '/notifications';
  static const orders = '/orders';
  static const tracking = '/tracking';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';
  static const about = '/about';
  static const account = '/account';
  static const articles = '/articles';
  static const contact = '/contact';
  static const settings = '/settings';
  static const bookingCreate = '/bookings/create';
  static const bookingDetail = '/bookings/detail';
  static const bookingDrafts = '/bookings/drafts';
  static const adminOrders = '/admin/orders';
  static const createOrder = '/orders/create';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Add custom route handling here if needed.
    return null;
  }
}
