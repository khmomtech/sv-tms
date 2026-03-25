import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

import '../models/contact.dart';

class ContactProvider with ChangeNotifier {
  List<Contact> _contacts = <Contact>[]; // Explicitly typed for clarity
  List<Contact> _filteredContacts = <Contact>[];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Contact> get contacts => _contacts;
  List<Contact> get filteredContacts =>
      _filteredContacts.isNotEmpty ? _filteredContacts : _contacts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fetch contacts from the API
  Future<void> fetchContacts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final apiBaseUrl = prefs.getString('apiUrl') ?? ApiConstants.baseUrl;

      if (accessToken == null || accessToken.isEmpty) {
        _errorMessage = 'User not authenticated. Please log in.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(
        Uri.parse('$apiBaseUrl/employees/contacts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Decode with UTF-8 to handle Khmer script correctly
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data.isEmpty) {
          _errorMessage = 'No contacts found.';
          _contacts = [];
        } else {
          _contacts = data
              .where((json) =>
                  json['employeeId'] != null &&
                  json['fullName'] != null &&
                  json['fullName'].toString().isNotEmpty)
              .map((json) => Contact.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        _filteredContacts = [];
      } else if (response.statusCode == 401) {
        // Handle unauthorized errors (e.g., accessToken expired)
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        debugPrint('Error Response Body: ${utf8.decode(response.bodyBytes)}');
        _errorMessage = 'Failed to fetch contacts: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Error Response: $e');
      _errorMessage = 'An error occurred while fetching contacts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter contacts based on search input
  void filterContacts(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredContacts = [];
    } else {
      _filteredContacts = _contacts.where((contact) {
        final fullName = contact.fullName.toLowerCase();
        final mobile = (contact.mobile ?? '').toLowerCase();
        return fullName.contains(query) || mobile.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  // Group contacts by the first letter of their name
  Map<String, List<Contact>> groupContacts() {
    final Map<String, List<Contact>> groupedContacts = {};

    for (var contact in filteredContacts) {
      final firstLetter =
          contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '#';
      groupedContacts.putIfAbsent(firstLetter, () => []).add(contact);
    }

    // Sort keys alphabetically
    final sortedKeys = groupedContacts.keys.toList()..sort();
    return {for (var key in sortedKeys) key: groupedContacts[key]!};
  }
}
