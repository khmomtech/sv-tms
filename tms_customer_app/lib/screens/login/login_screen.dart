import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Updated email validator to avoid overly strict/incorrect pattern
  String? _validateEmail2(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'emailRequired'.tr();
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'emailInvalid'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'passwordRequired'.tr();
    }
    if (value.length < 6) {
      return 'passwordTooShort'.tr();
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Call real login API
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // If login returned a customerId, set it on the UserProvider so
        // other parts of the app (orders, notifications) can use it.
        final user = authProvider.currentUser;
        if (user != null && user.customerId != null) {
          final up = Provider.of<dynamic>(context, listen: false);
          try {
            // Provider type is `UserProvider` but avoid import cycle in this file
            // by using dynamic lookup and calling `setCustomerId` if available.
            (up as dynamic).setCustomerId(user.customerId);
          } catch (_) {}
        }

        // Login successful - navigate to home
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Show user-friendly error message
          if (e.toString().contains('NETWORK_ERROR')) {
            _errorMessage = 'networkError'.tr();
          } else if (e.toString().contains('Invalid username or password')) {
            _errorMessage = 'invalidCredentials'.tr();
          } else {
            _errorMessage = e.toString();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Unused variable removed
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary,
                AppColors.primary,
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Language Switcher Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Toggle between English and Khmer
                        if (context.locale.languageCode == 'km') {
                          context.setLocale(const Locale('en'));
                        } else {
                          context.setLocale(const Locale('km'));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.locale.languageCode == 'km'
                                  ? 'EN'
                                  : 'ខ្មែរ',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Main Content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: keyboardVisible ? 16.0 : 32.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                              elevation: 12,
                              shadowColor: Colors.black.withOpacity(0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(28.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Logo with Title
                                      Hero(
                                        tag: 'app_logo',
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Logo
                                            Image.asset(
                                              'assets/images/logo.png',
                                              height: 80,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(height: 16),
                                            // Title
                                            Text(
                                              'companyName'.tr(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Subtitle
                                            Text(
                                              'portalName'.tr(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 32),
                                      TextFormField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        enabled: !_isLoading,
                                        validator: _validateEmail2,
                                        onFieldSubmitted: (_) =>
                                            _passwordFocusNode.requestFocus(),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          labelText: 'email'.tr(),
                                          hintText: 'emailHint'.tr(),
                                          hintStyle: const TextStyle(
                                              color: AppColors.textLight),
                                          prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              color: AppColors.primary,
                                              size: 22),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.border,
                                                width: 1.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                                color: AppColors.border
                                                    .withOpacity(0.5),
                                                width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2.5),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.danger,
                                                width: 1.5),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.danger,
                                                width: 2.5),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        enabled: !_isLoading,
                                        validator: _validatePassword,
                                        onFieldSubmitted: (_) => _handleLogin(),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          labelText: 'password'.tr(),
                                          hintText: 'passwordHint'.tr(),
                                          hintStyle: const TextStyle(
                                              color: AppColors.textLight),
                                          prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppColors.primary,
                                              size: 22),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: AppColors.textSecondary,
                                              size: 22,
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    setState(() =>
                                                        _obscurePassword =
                                                            !_obscurePassword);
                                                  },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.border,
                                                width: 1.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                                color: AppColors.border
                                                    .withOpacity(0.5),
                                                width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 2.5),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.danger,
                                                width: 1.5),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                                color: AppColors.danger,
                                                width: 2.5),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: _isLoading
                                                ? null
                                                : () => setState(() =>
                                                    _rememberMe = !_rememberMe),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: _isLoading
                                                          ? null
                                                          : (v) => setState(() =>
                                                              _rememberMe =
                                                                  v ?? false),
                                                      activeColor:
                                                          AppColors.primary,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5)),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('rememberMe'.tr(),
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    Navigator.pushNamed(
                                                        context,
                                                        AppRoutes
                                                            .forgotPassword);
                                                  },
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8)),
                                            child: Text('forgotPassword'.tr(),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (_errorMessage != null &&
                                          _errorMessage!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          margin:
                                              const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: AppColors.danger
                                                    .withOpacity(0.4),
                                                width: 1.5),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: AppColors.danger,
                                                  size: 24),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Text(_errorMessage!,
                                                      style: const TextStyle(
                                                          color:
                                                              AppColors.danger,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.4))),
                                            ],
                                          ),
                                        ),
                                      SizedBox(
                                        height: 56,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _isLoading
                                                  ? [
                                                      AppColors.primary
                                                          .withOpacity(0.7),
                                                      AppColors.secondary
                                                          .withOpacity(0.7)
                                                    ]
                                                  : [
                                                      AppColors.primary,
                                                      AppColors.secondary
                                                    ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: _isLoading
                                                ? []
                                                : [
                                                    BoxShadow(
                                                        color: AppColors.primary
                                                            .withOpacity(0.4),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 6),
                                                        spreadRadius: -2)
                                                  ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                              elevation: 0,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white)))
                                                : Text('login'.tr(),
                                                    style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('noAccount'.tr(),
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500)),
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    Navigator.pushNamed(context,
                                                        AppRoutes.register);
                                                  },
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8)),
                                            child: Text('signUp'.tr(),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
