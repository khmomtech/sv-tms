// ignore_for_file: unused_element_parameter, prefer_const_constructors, unused_element
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

// intl symbols are provided by easy_localization import used in the project
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common/index.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      drawer: AppDrawer(user: user),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text('app_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'notifications'.tr(),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${notificationProvider.unreadCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              try {
                Navigator.pushNamed(context, AppRoutes.notifications);
              } catch (_) {
                // If route is not defined, fall back to showing a list via provider
                // (no-op here) — we keep this safe to avoid crashes.
              }
            },
          ),
          IconButton(
            tooltip: 'logout'.tr(),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authProvider.logout();
              if (!mounted) return;
              navigator.pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 12.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showSupportActions(context),
          icon: const Icon(Icons.headset_mic),
          label: Text('support'.tr()),
          backgroundColor: theme.colorScheme.primary,
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      // Use SafeArea so content is not covered by system UI (notch, home bar)
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh logic here
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Builder(builder: (ctx) {
            final List<Widget> contentChildren = [];
            if (_selectedIndex != 0) {
              contentChildren.add(_buildTabPlaceholder(_selectedIndex));
            } else {
              contentChildren.addAll([
                const SizedBox(height: 12),
                _PromoCarousel(),
                const SectionHeader(title: 'Quick Actions'),
                _QuickActionsPanel(),
                const SectionHeader(title: 'Services & Pricing'),
                _ServicesPricingSection(),
              ]);
            }

            return ListView(
              key: ValueKey<int>(_selectedIndex),
              // ensure space at bottom so floating home indicators don't overlap content
              padding: const EdgeInsets.only(bottom: 32.0),
              children: contentChildren,
            );
          }),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          switch (i) {
            case 1:
              Navigator.pushNamed(context, AppRoutes.orders);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.tracking);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.incidents);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber),
            label: 'Incidents',
          ),
        ],
      ),
    );
  }

  void _showSupportActions(BuildContext context) async {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text('call_support'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  final tel = Uri.parse('tel:+85512345678');
                  await _safeLaunch(tel, 'could_not_open_dialer');
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text('email_support'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  final mail = Uri.parse('mailto:support@svapp.com');
                  await _safeLaunch(mail, 'could_not_open_mail_client');
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('close'.tr()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _safeLaunch(Uri uri, String failureKey) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureKey.tr())));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureKey.tr())));
    }
  }

  Widget _buildTabPlaceholder(int index) {
    final theme = Theme.of(context);
    const labels = ['home', 'orders', 'tracking', 'incidents'];
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(labels[index].tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('coming_soon'.tr(), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('active_shipments'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text('no_orders_title'.tr(),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'no_orders_message'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  final dynamic user;
  const _HomeHeader({this.user});

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final userName = user?.username ?? user?.email ?? 'Guest';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.04 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Semantics(
              label: 'profile_avatar'.tr(),
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(48),
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Builder(builder: (_) {
                    final uname = user?.username ?? user?.email ?? '';
                    if (uname.isEmpty) {
                      return Icon(Icons.person,
                          size: 36, color: theme.colorScheme.onPrimary);
                    }
                    final parts = uname.split(RegExp(r"\s+|@"));
                    final initials = parts
                        .where((p) => p.isNotEmpty)
                        .map((p) => p[0])
                        .take(2)
                        .join()
                        .toUpperCase();
                    return Text(initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700));
                  }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('member_since'.tr(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  int _page = 0;

  @override
  void initState() {
    super.initState();
  }

  bool _didPrefetch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefetch commonly used image after the element is mounted and
    // MediaQuery/Theme are available.
    if (!_didPrefetch) {
      _didPrefetch = true;
      precacheImage(
          const AssetImage('assets/images/icons/prod_icon.png'), context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: 4,
              itemBuilder: (context, i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image (cover)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                  'assets/images/icons/prod_icon.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Stronger gradient overlay for better contrast
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha((0.62 * 255).round()),
                              ],
                              stops: const [0.0, 0.9],
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('promo_title'.tr(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              shadows: [
                                            Shadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(0, 2))
                                          ])),
                                  const SizedBox(height: 8),
                                  Text('promo_subtitle'.tr(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: Colors.white70,
                                              shadows: [
                                            Shadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 1))
                                          ])),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
              left: 0,
              child: IconButton(
                  onPressed: () {
                    _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                  icon: CircleAvatar(
                      backgroundColor:
                          Colors.black.withAlpha((0.12 * 255).round()),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.white)))),
          Positioned(
              right: 0,
              child: IconButton(
                  onPressed: () {
                    _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                  icon: CircleAvatar(
                      backgroundColor:
                          Colors.black.withAlpha((0.12 * 255).round()),
                      child: const Icon(Icons.chevron_right,
                          color: Colors.white)))),
          Positioned(
            bottom: 8,
            child: Row(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? colors.primary
                        : colors.onSurface.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      {
        'icon': Icons.add_shopping_cart_outlined,
        'label': 'book',
        'route': AppRoutes.bookings,
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'tracking',
        'route': AppRoutes.tracking,
      },
      {
        'icon': Icons.warning_amber_outlined,
        'label': 'incidents',
        'route': AppRoutes.incidents,
      },
      {
        'icon': Icons.person_outline,
        'label': 'profile',
        'route': AppRoutes.profile,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.02 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 4,
          childAspectRatio: 0.78,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: items.map((it) {
            final icon = it['icon'] as IconData;
            final label = (it['label'] as String).tr();
            final route = it['route'] as String?;
            return Semantics(
              label: label,
              button: true,
              child: InkWell(
                onTap: route != null
                    ? () => Navigator.pushNamed(context, route)
                    : null,
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(label,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ServicesPricingSection extends StatefulWidget {
  @override
  State<_ServicesPricingSection> createState() =>
      _ServicesPricingSectionState();
}

class _ServicesPricingSectionState extends State<_ServicesPricingSection> {
  int _selectedTab = 0; // 0=All,1=Medium,2=Heavy (we'll treat 0 as all)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final vehicles = [
      {'title': 'TATA LPT 710', 'capacity': '30 Tons', 'price': 1.5, 'type': 0},
      {
        'title': 'Blazo X 35 BS6',
        'capacity': '25 Tons',
        'price': 3.0,
        'type': 1
      },
      {'title': 'Hino 700', 'capacity': '40 Tons', 'price': 4.5, 'type': 2},
    ];

    final displayed = vehicles
        .where((v) => _selectedTab == 0 || v['type'] == _selectedTab)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(3, (i) {
                final selected = _selectedTab == i;
                final labelKey = i == 0
                    ? 'vehicle_small'
                    : i == 1
                        ? 'vehicle_medium'
                        : 'vehicle_large';
                return Semantics(
                  label: labelKey.tr(),
                  button: true,
                  selected: selected,
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = i),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 18),
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: selected
                                ? colors.primary
                                : colors.onSurface.withAlpha(80)),
                      ),
                      child: Text(
                        labelKey.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                selected ? colors.onPrimary : colors.onSurface),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: displayed.map((v) {
              final price = v['price'] as double;
              final priceText = '${price.toStringAsFixed(2)}Riel';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.04 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/icons/prod_icon.png'),
                                fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['title'] as String,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('${'capacity'.tr()}: ${v['capacity']}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(priceText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Icon(Icons.chevron_right, color: colors.outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Removed unused _QuickAction helper (replaced by _QuickActionsPanel)

class _StatusSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookings = Provider.of<BookingsProvider>(context).bookings;
    final active =
        bookings.where((b) => !b.isDraft && b.status != 'completed').length;
    final pendingQuotes = bookings.where((b) => b.status == 'pending').length;
    final completed = bookings.where((b) => b.status == 'completed').length;

    Widget card(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha((0.02 * 255).round()),
                  blurRadius: 6,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(label.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140))),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          card('active_orders', active.toString()),
          const SizedBox(width: 8),
          card('pending_quotes', pendingQuotes.toString()),
          const SizedBox(width: 8),
          card('completed', completed.toString()),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<BookingsProvider>(context);
    final activeList =
        provider.bookings.where((b) => !b.isDraft && b.status != 'completed');
    final active = activeList.isNotEmpty ? activeList.first : null;

    if (active == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12)),
          child: Text('no_active_orders'.tr()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: theme.colorScheme.outline.withAlpha(32)),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900, fontSize: 22)),
                      const SizedBox(height: 8),
                      Text('${active.pickupAddress} → ${active.dropoffAddress}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(200),
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      // Info rows
                      // Info rows (service/cargo and right summary)
                      Builder(builder: (ctx) {
                        final service = active.serviceType ?? '-';
                        final cargo = active.cargoType ?? '-';
                        final rightTop = active.containerNo != null ||
                                (active.vehicleType != null &&
                                    active.vehicleType!.isNotEmpty)
                            ? (active.containerNo != null
                                ? 'Container'
                                : (active.vehicleType ?? 'FTL'))
                            : 'FTL';
                        final rightBottom = active.palletCount != null
                            ? '${active.palletCount} pallets'
                            : (active.totalWeightTons != null
                                ? '${active.totalWeightTons?.toStringAsFixed(0)}T'
                                : '-');

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service,
                                      style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  Text(cargo,
                                      style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            // right summary (type & size)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(rightTop,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text(rightBottom,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  children: [
                    // Buttons layout depends on status
                    if (active.status.toLowerCase() == 'dispatched') ...[
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.bookingDetail,
                              arguments: active),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.description,
                                    color: Colors.white),
                              ),
                              Text('detail'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.tracking,
                                arguments: active);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child:
                                    Text('🌍', style: TextStyle(fontSize: 18)),
                              ),
                              Text('track'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.bookingDetail,
                              arguments: active),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.description,
                                    color: Colors.black54),
                              ),
                              Text('detail'.tr(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(active.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900, color: Colors.deepOrange)),
            ),
          ),
        ],
      ),
    );
  }
}
