import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterV2Screen extends StatefulWidget {
  const HelpCenterV2Screen({super.key});
  @override
  State<HelpCenterV2Screen> createState() => _HelpCenterV2ScreenState();
}

class _HelpCenterV2ScreenState extends State<HelpCenterV2Screen> {
  final _searchCtrl = TextEditingController();
  final _faq = <String, List<Map<String, String>>>{
    'ការងារ & ការដឹកជញ្ជូន': [
      {
        'q': 'ធ្វើដូចម្តេចដើម្បីទទួលការងារ?',
        'a': "ចូលទៅ 'សកម្មភាព' → ចុច 'ទទួល'."
      },
      {
        'q': 'បិទការងារបានប៉ុន្មានជំហាន?',
        'a': 'Update រូបភាព/ហត្ថលេខា → ចុច Complete.'
      },
    ],
    'App & គណនី': [
      {'q': 'ប្ដូរភាសាធ្វើដូចម្តេច?', 'a': 'Menu → Settings → Language.'},
      {'q': 'Login ពិបាក?', 'a': 'ពិនិត្យអ៊ីនធឺណិត + ធ្វើ Update App.'},
    ],
    'Payment / COD': [
      {'q': 'បញ្ចូល COD?', 'a': 'បញ្ជាក់ COD នៅគោលដៅ + រក្សាទុកបង្កាន់ដៃ.'},
    ],
    'GPS / Network': [
      {
        'q': 'GPS មិនរត់?',
        'a': 'បើក Location, High accuracy, បិទ Battery Saver.'
      },
    ],
  };

  final _expanded = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (final k in _faq.keys) {
      _expanded[k] = true;
    }
  }

  Future<void> _launch(String uri) async {
    final ok = await launchUrl(Uri.parse(uri));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('មិនអាចបើកបាន')),
      );
    }
  }

  void _openContactSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ទំនាក់ទំនងជំនួយ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('010 123 456'),
                subtitle: const Text('Hotline (06:00–22:00)'),
                onTap: () => _launch('tel:010123456'),
              ),
              ListTile(
                leading: const Icon(Icons.telegram, color: Colors.blue),
                title: const Text('Telegram Support'),
                onTap: () => _launch('https://t.me/sv_support'),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.deepOrange),
                title: const Text('support@svapp.com'),
                onTap: () => _launch('mailto:support@svapp.com'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('មជ្ឈមណ្ឌលជំនួយ'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openContactSheet,
        icon: const Icon(Icons.support_agent),
        label: const Text('ទាក់ទងភ្លាមៗ'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកសំណួរ…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _QuickActions(
                onReceive: () => _launch('svapp://tasks'),
                onReportIssue: () => _launch('svapp://report'),
                onUploadProof: () => _launch('svapp://upload-proof'),
                onCall: _openContactSheet,
              ),
            ),
          ),

          // Diagnostics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _DiagnosticsCard(
                gpsOn: true,
                networkOk: true,
                batterySaverOn: false,
                notificationOk: true,
                onFixBatterySaver: () =>
                    _launch('svapp://open-battery-optimization'),
                onFixGPS: () => _launch('svapp://open-location-settings'),
              ),
            ),
          ),

          // FAQs Sections
          SliverList.list(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('សំណួរញឹកញាប់',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ..._faq.entries.map((entry) {
              final cat = entry.key;
              final items = entry.value.where((qa) {
                final q = (qa['q'] ?? '').toLowerCase();
                final a = (qa['a'] ?? '').toLowerCase();
                final s = _searchCtrl.text.toLowerCase();
                if (s.isEmpty) return true;
                return q.contains(s) || a.contains(s);
              }).toList();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  child: ExpansionTile(
                    title: Text(cat,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    initiallyExpanded: _expanded[cat] ?? false,
                    onExpansionChanged: (v) =>
                        setState(() => _expanded[cat] = v),
                    children: items.map((qa) {
                      return ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text(qa['q']!),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(qa['a']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ]),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onReceive, onReportIssue, onUploadProof, onCall;
  const _QuickActions({
    required this.onReceive,
    required this.onReportIssue,
    required this.onUploadProof,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ActionTile(
          icon: Icons.playlist_add_check,
          label: 'ទទួលការងារ',
          onTap: onReceive),
      _ActionTile(
          icon: Icons.report, label: 'រាយការណ៍បញ្ហា', onTap: onReportIssue),
      _ActionTile(
          icon: Icons.photo_camera,
          label: 'ឡើងរូបភាពបញ្ជាក់',
          onTap: onUploadProof),
      _ActionTile(icon: Icons.headset_mic, label: 'ទំនាក់ទំនង', onTap: onCall),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: tiles.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 90,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
            color: c.primaryContainer, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 28, color: c.onPrimaryContainer),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: c.onPrimaryContainer,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  final bool gpsOn, networkOk, batterySaverOn, notificationOk;
  final VoidCallback onFixBatterySaver, onFixGPS;
  const _DiagnosticsCard({
    required this.gpsOn,
    required this.networkOk,
    required this.batterySaverOn,
    required this.notificationOk,
    required this.onFixBatterySaver,
    required this.onFixGPS,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool ok) {
      return Chip(
        avatar: Icon(ok ? Icons.check_circle : Icons.error, size: 18),
        label: Text(label),
        backgroundColor:
          ok ? Colors.green.withOpacity(.15) : Colors.orange.withOpacity(.15),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ការពិនិត្យរហ័ស (Diagnostics)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            pill('GPS ${"ON"}', gpsOn),
            pill('Network', networkOk),
            pill('Notifications', notificationOk),
            pill('Battery Saver', !batterySaverOn), // good if false
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (batterySaverOn)
              TextButton.icon(
                  onPressed: onFixBatterySaver,
                  icon: const Icon(Icons.battery_saver),
                  label: const Text('បិទ Battery Saver')),
            const SizedBox(width: 8),
            if (!gpsOn)
              TextButton.icon(
                  onPressed: onFixGPS,
                  icon: const Icon(Icons.location_on),
                  label: const Text('បើក GPS')),
          ]),
        ]),
      ),
    );
  }
}
