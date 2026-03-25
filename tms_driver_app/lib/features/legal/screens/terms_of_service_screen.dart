// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';

// /// Terms of Service Screen
// /// 
// /// Displays comprehensive terms of service with:
// /// - Age verification (18+)
// /// - Professional driver agreement
// /// - Liability disclaimers
// /// - Acceptance tracking
// class TermsOfServiceScreen extends StatefulWidget {
//   final VoidCallback? onAccepted;
//   final bool requireAcceptance;

//   const TermsOfServiceScreen({
//     super.key,
//     this.onAccepted,
//     this.requireAcceptance = false,
//   });

//   @override
//   State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
// }

// class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
//   bool _isAgeVerified = false;
//   bool _hasReadTerms = false;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_checkScrollPosition);
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _checkScrollPosition() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 50) {
//       if (!_hasReadTerms) {
//         setState(() => _hasReadTerms = true);
//       }
//     }
//   }

//   void _acceptTerms() {
//     if (!_isAgeVerified) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please confirm you are 18 years or older'),
//           backgroundColor: const Color(0xFF2563eb),
//         ),
//       );
//       return;
//     }

//     if (!_hasReadTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please read the complete terms by scrolling to the bottom'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     if (widget.onAccepted != null) {
//       widget.onAccepted!();
//     } else {
//       Navigator.pop(context, true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Terms of Service'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSection(
//                     title: 'Terms of Service',
//                     content: '''
// Last Updated: December 2, 2025
// Version: 1.0

// Welcome to Smart Truck Driverr, a professional logistics and delivery management application ("App"). By accessing or using this App, you agree to be bound by these Terms of Service ("Terms").
// ''',
//                   ),

//                   _buildSection(
//                     title: '1. Age Requirement & Eligibility',
//                     content: '''
// **18+ YEARS REQUIRED**

// This App is exclusively designed for professional commercial drivers. By using this App, you represent and warrant that:

// • You are at least 18 years of age
// • You possess a valid commercial driver's license (CDL) or equivalent
// • You are legally authorized to operate commercial vehicles in your jurisdiction
// • You are not using this App on behalf of minors

// **Parental Consent:** This App is NOT intended for use by individuals under 18 years of age. No parental consent mechanism is provided as the App is restricted to adults only.

// **Age Verification:** We may request proof of age and commercial driver credentials at any time. Failure to provide verification may result in account suspension or termination.
// ''',
//                   ),

//                   _buildSection(
//                     title: '2. Account Registration',
//                     content: '''
// To use this App, you must:

// • Provide accurate, current, and complete registration information
// • Maintain and update your information to keep it accurate
// • Maintain the security of your account credentials
// • Notify us immediately of any unauthorized access
// • Accept responsibility for all activities under your account

// We reserve the right to suspend or terminate accounts that provide false information or violate these Terms.
// ''',
//                   ),

//                   _buildSection(
//                     title: '3. Professional Use',
//                     content: '''
// This App is intended solely for:

// • Professional delivery and logistics operations
// • Commercial trucking and transportation services
// • Business-to-business (B2B) freight services
// • Authorized company drivers and contractors

// **NOT for personal or consumer delivery services.**

// By using this App, you acknowledge this is a professional tool for commercial operations.
// ''',
//                   ),

//                   _buildSection(
//                     title: '4. Location Tracking',
//                     content: '''
// **Required for Service:**

// This App collects your precise location data, including background location tracking, for:

// • Real-time delivery tracking
// • Route optimization and navigation
// • Dispatch assignment and job matching
// • Customer delivery notifications
// • Proof of delivery verification
// • Driver safety monitoring
// • Compliance and audit records

// **Your Consent:**

// By using this App, you explicitly consent to location tracking during active work hours and delivery assignments. You may disable location services, but delivery tracking features will not function.

// **Data Usage:**

// Location data is transmitted to our servers and may be shared with:
// - Your employer/dispatch center
// - Customers (for delivery tracking)
// - Regulatory authorities (for compliance)

// See our Privacy Policy for complete details.
// ''',
//                   ),

//                   _buildSection(
//                     title: '5. Driver Responsibilities',
//                     content: '''
// As a professional driver using this App, you agree to:

// • Operate vehicles safely and in compliance with all traffic laws
// • Never use the App while actively driving (use hands-free only)
// • Maintain valid commercial driver's licenses and insurance
// • Report accidents, incidents, or safety issues immediately
// • Provide accurate delivery confirmations and proofs
// • Treat customers and staff professionally
// • Follow company policies and procedures

// **Safety First:** Do not interact with this App while driving. Pull over safely if you need to use the App.
// ''',
//                   ),

//                   _buildSection(
//                     title: '6. Prohibited Conduct',
//                     content: '''
// You may NOT:

// • Use the App for illegal activities
// • Share your account credentials
// • Manipulate GPS or location data
// • Upload false delivery proofs
// • Harass or threaten customers or staff
// • Reverse engineer or hack the App
// • Violate any applicable laws or regulations
// • Use the App under the influence of drugs/alcohol
// • Transport prohibited or illegal goods
// ''',
//                   ),

//                   _buildSection(
//                     title: '7. Liability & Disclaimers',
//                     content: '''
// **APP PROVIDED "AS IS":**

// The App is provided on an "as is" and "as available" basis without warranties of any kind.

// **LIMITATION OF LIABILITY:**

// To the maximum extent permitted by law, SV Trucking shall not be liable for:

// • Accidents, injuries, or property damage during deliveries
// • Lost income or business opportunities
// • GPS navigation errors or routing mistakes
// • Service interruptions or downtime
// • Data loss or corruption
// • Third-party claims or disputes

// **ASSUMPTION OF RISK:**

// You acknowledge that commercial driving involves inherent risks and assume full responsibility for your safety and the safety of others.

// **INSURANCE:**

// This App does not provide insurance coverage. You are responsible for maintaining adequate commercial vehicle insurance.
// ''',
//                   ),

//                   _buildSection(
//                     title: '8. Privacy & Data Protection',
//                     content: '''
// Your privacy is important to us. Please review our Privacy Policy for detailed information about:

// • Data we collect (location, photos, personal info)
// • How we use your data
// • Third-party data sharing (Firebase, Google Maps)
// • Your rights under GDPR and CCPA
// • Data retention and deletion

// **GDPR Compliance:** If you are in the EU, you have rights to access, rectify, erase, and export your data. See Privacy Settings in the App.

// **CCPA Compliance:** California residents have rights to know, delete, and opt-out of data sales (we do not sell personal data).
// ''',
//                   ),

//                   _buildSection(
//                     title: '9. Intellectual Property',
//                     content: '''
// All content, trademarks, logos, and intellectual property in this App are owned by SV Trucking or our licensors. You may not:

// • Copy, modify, or distribute App content
// • Use our trademarks without permission
// • Create derivative works
// • Remove copyright notices
// ''',
//                   ),

//                   _buildSection(
//                     title: '10. Termination',
//                     content: '''
// We may suspend or terminate your account at any time for:

// • Violation of these Terms
// • Fraudulent or illegal activity
// • Safety violations
// • Employment termination
// • Inactivity (90 days)

// Upon termination, you must cease all use of the App and delete it from your device.
// ''',
//                   ),

//                   _buildSection(
//                     title: '11. Updates & Modifications',
//                     content: '''
// We reserve the right to modify these Terms at any time. Changes will be effective upon posting in the App. Continued use after changes constitutes acceptance of the new Terms.

// You will be notified of material changes and may be required to re-accept Terms.
// ''',
//                   ),

//                   _buildSection(
//                     title: '12. Governing Law',
//                     content: '''
// These Terms are governed by the laws of [Your Jurisdiction]. Any disputes shall be resolved in the courts of [Your Jurisdiction].

// **Arbitration:** You agree to resolve disputes through binding arbitration rather than court litigation, except where prohibited by law.
// ''',
//                   ),

//                   _buildSection(
//                     title: '13. Contact Information',
//                     content: '''
// For questions about these Terms:

// **SV Trucking**  
// Email: legal@svtrucking.com  
// Address: [Company Address]  
// Phone: [Company Phone]

// **Support:**  
// Email: support@svtrucking.com
// ''',
//                   ),

//                   const SizedBox(height: 32),

//                   // Age Rating Information
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[50],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.blue),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Row(
//                           children: [
//                             Icon(Icons.warning_amber, color: Colors.blue),
//                             SizedBox(width: 8),
//                             Text(
//                               'App Store Age Rating',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'This app is rated 18+ for the following reasons:',
//                           style: TextStyle(fontWeight: FontWeight.w600),
//                         ),
//                         const SizedBox(height: 8),
//                         _buildBulletPoint('Professional commercial driver application'),
//                         _buildBulletPoint('Requires valid commercial driver\'s license (CDL)'),
//                         _buildBulletPoint('Real-time GPS tracking and location monitoring'),
//                         _buildBulletPoint('Business-to-business (B2B) commercial use'),
//                         _buildBulletPoint('Workplace safety and compliance requirements'),
//                         _buildBulletPoint('Employment-related functionality'),
//                         const SizedBox(height: 8),
//                         RichText(
//                           text: TextSpan(
//                             style: Theme.of(context).textTheme.bodySmall,
//                             children: [
//                               const TextSpan(
//                                 text: 'Apple App Store Category: ',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               const TextSpan(text: 'Navigation & Business\n'),
//                               const TextSpan(
//                                 text: 'Age Rating: ',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               const TextSpan(text: '18+ (Adult Users Only)\n'),
//                               const TextSpan(
//                                 text: 'Content Rating: ',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               const TextSpan(
//                                 text: 'Frequent/Intense Realistic Violence: None\n'
//                                     'Alcohol, Tobacco, or Drug Use: None\n'
//                                     'Mature/Suggestive Themes: None\n'
//                                     'Horror/Fear Themes: None\n'
//                                     'Medical/Treatment Information: None\n'
//                                     'Gambling: None',
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 32),

//                   if (!_hasReadTerms)
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.orange),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Please scroll to the bottom to read all terms before accepting',
//                               style: TextStyle(color: Colors.orange),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           if (widget.requireAcceptance)
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 4,
//                     offset: const Offset(0, -2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   CheckboxListTile(
//                     value: _isAgeVerified,
//                     onChanged: (v) => setState(() => _isAgeVerified = v ?? false),
//                     title: const Text(
//                       'I confirm that I am 18 years or older',
//                       style: TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     controlAffinity: ListTileControlAffinity.leading,
//                   ),
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _hasReadTerms && _isAgeVerified
//                           ? _acceptTerms
//                           : null,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       child: const Text('I Accept the Terms of Service'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSection({required String title, required String content}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             content.trim(),
//             style: const TextStyle(
//               fontSize: 14,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBulletPoint(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 16, bottom: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('• ', style: TextStyle(fontSize: 16)),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }
// }
