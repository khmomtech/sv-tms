import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/safety_check_model.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/safety_provider.dart';

class DriverSafetyCheckScreen extends StatefulWidget {
  const DriverSafetyCheckScreen({super.key});

  @override
  State<DriverSafetyCheckScreen> createState() =>
      _DriverSafetyCheckScreenState();
}

class _DriverSafetyCheckScreenState extends State<DriverSafetyCheckScreen> {
  int _currentStep = 0;
  bool _confirm = false;
  bool _isOnline = true;
  bool _isPicking = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final connected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOnline = connected);
      }
    });
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      final connected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      setState(() => _isOnline = connected);
    });
  }

  Future<void> _load() async {
    final driverProvider = context.read<DriverProvider>();
    final safetyProvider = context.read<SafetyProvider>();
    final vehicleId = _vehicleIdFromDriver(driverProvider);
    if (vehicleId != null) {
      await safetyProvider.loadTodaySafety(vehicleId);
    }
  }

  int? _vehicleIdFromDriver(DriverProvider provider) {
    final vehicle = provider.effectiveVehicle ?? provider.vehicleCardData;
    if (vehicle == null) return null;
    final raw = vehicle['id'] ?? vehicle['vehicleId'] ?? vehicle['vehicle_id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ពិនិត្យសុវត្ថិភាពប្រចាំថ្ងៃ'),
        actions: [
          Consumer<SafetyProvider>(
            builder: (context, sp, _) {
              if (!sp.canEdit) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await sp.saveDraft();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានរក្សាទុកសេចក្ដីព្រាង')),
                  );
                },
                child: const Text('រក្សាទុកសេចក្ដីព្រាង',
                    style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Consumer3<SafetyProvider, DispatchProvider, DriverProvider>(
        builder:
            (context, safetyProvider, dispatchProvider, driverProvider, _) {
          if (safetyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasTrip = dispatchProvider.pendingDispatches.isNotEmpty;
          final steps = _buildSteps(safetyProvider, hasTrip);
          final requiredItems = _requiredItems(safetyProvider, hasTrip);
          final missingItems = _missingItems(safetyProvider, hasTrip);
          final completedRequired = requiredItems.length - missingItems.length;
          final totalRequired = requiredItems.length;
          final progress =
              totalRequired == 0 ? 0.0 : completedRequired / totalRequired;

          final status = safetyProvider.status ?? 'NOT_STARTED';
          final readOnly = !safetyProvider.canEdit;
          final apiError = safetyProvider.errorMessage;
          final risk = safetyProvider.calculateRiskLevel();

          return Column(
            children: [
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange.shade50,
                  child: const Text(
                    'អុហ្វឡាញ៖ ទិន្នន័យនឹងរក្សាទុកក្នុងទូរស័ព្ទ ហើយផ្ញើពេលអនឡាញ',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              if (_isOnline && apiError != null && apiError.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.red.shade50,
                  child: Text(
                    _apiErrorMessage(apiError),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (status == 'REJECTED')
                _buildRejectBanner(safetyProvider.today?.rejectReason),
              _buildTopSummary(
                status: status,
                risk: risk,
                completedRequired: completedRequired,
                totalRequired: totalRequired,
                progress: progress,
              ),
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep.clamp(0, steps.length - 1),
                  onStepTapped: (index) {
                    setState(() => _currentStep = index);
                  },
                  onStepContinue: () {
                    if (_currentStep < steps.length - 1) {
                      setState(() => _currentStep += 1);
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isLast = _currentStep == steps.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          if (!isLast)
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              child: const Text('បន្ត'),
                            ),
                          if (!isLast) const SizedBox(width: 12),
                          if (_currentStep > 0 && !isLast)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('ថយក្រោយ'),
                            ),
                          if (isLast)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (!readOnly && _confirm)
                                    ? () async {
                                        final missing = _missingItems(
                                            safetyProvider, hasTrip);
                                        if (missing.isNotEmpty) {
                                          if (!mounted) return;
                                          _showMissingDialog(missing);
                                          return;
                                        }
                                        await safetyProvider
                                            .submitSafetyCheck();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('បានដាក់ស្នើសុំអនុម័ត')),
                                        );
                                      }
                                    : null,
                                child: const Text('ដាក់ស្នើសុំអនុម័ត'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  physics: const ClampingScrollPhysics(),
                  stepIconBuilder: (stepIndex, stepState) {
                    final done = stepState == StepState.complete;
                    if (done) {
                      return const Icon(Icons.check,
                          color: Colors.white, size: 16);
                    }
                    return Text(
                      '${stepIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                  steps: steps,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Step> _buildSteps(SafetyProvider provider, bool hasTrip) {
    final steps = <Step>[];
    int stepIndex = 0;

    steps.add(_buildStep(
      index: stepIndex++,
      title: '១. ពិនិត្យយានយន្ត',
      subtitle: 'ធាតុចាំបាច់',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildVehicleSections(provider),
      ),
      provider: provider,
      hasTrip: hasTrip,
    ));

    steps.add(_buildStep(
      index: stepIndex++,
      title: '២. សុខភាពអ្នកបើកបរ',
      subtitle: 'ធាតុចាំបាច់',
      content: _buildCategorySection(provider, _driverHealthCategory) ??
          const Text('មិនមានទិន្នន័យ'),
      provider: provider,
      hasTrip: hasTrip,
    ));

    steps.add(_buildStep(
      index: stepIndex++,
      title: '៣. ឧបករណ៍សុវត្ថិភាព',
      subtitle: 'ធាតុចាំបាច់',
      content: _buildCategorySection(provider, _safetyEquipmentCategory) ??
          const Text('មិនមានទិន្នន័យ'),
      provider: provider,
      hasTrip: hasTrip,
    ));

    if (hasTrip) {
      steps.add(_buildStep(
        index: stepIndex++,
        title: '៤. ទំនិញ (ជម្រើស)',
        subtitle: 'ជម្រើស',
        content: _buildCategorySection(provider, _loadCategory) ??
            const Text('មិនមានទិន្នន័យ'),
        provider: provider,
        hasTrip: hasTrip,
      ));
    }

    steps.add(_buildStep(
      index: stepIndex++,
      title: hasTrip ? '៥. បរិស្ថាន' : '៤. បរិស្ថាន',
      subtitle: 'ធាតុចាំបាច់',
      content: _buildEnvironmentStep(provider),
      provider: provider,
      hasTrip: hasTrip,
    ));

    steps.add(_buildStep(
      index: stepIndex++,
      title: hasTrip ? '៦. ពិនិត្យឡើងវិញ' : '៥. ពិនិត្យឡើងវិញ',
      subtitle: 'ដាក់ស្នើ',
      content: _buildReviewStep(provider),
      provider: provider,
      hasTrip: hasTrip,
    ));

    return steps;
  }

  Step _buildStep({
    required int index,
    required String title,
    required Widget content,
    required SafetyProvider provider,
    required bool hasTrip,
    String? subtitle,
  }) {
    return Step(
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 12)),
      content: content,
      isActive: _currentStep >= index,
      state: _stepState(index, provider, hasTrip),
    );
  }

  StepState _stepState(int index, SafetyProvider provider, bool hasTrip) {
    if (_isStepComplete(index, provider, hasTrip)) {
      return StepState.complete;
    }
    if (_currentStep == index) {
      return StepState.editing;
    }
    return StepState.indexed;
  }

  bool _isStepComplete(int index, SafetyProvider provider, bool hasTrip) {
    final environmentIndex = hasTrip ? 4 : 3;
    final reviewIndex = hasTrip ? 5 : 4;
    if (index == 0) {
      return _vehicleCategories.every(
          (c) => _isCategoryComplete(provider, c.code, optionalIfEmpty: true));
    }
    if (index == 1) {
      return _isCategoryComplete(provider, _driverHealthCategory.code,
          optionalIfEmpty: true);
    }
    if (index == 2) {
      return _isCategoryComplete(provider, _safetyEquipmentCategory.code,
          optionalIfEmpty: true);
    }
    if (hasTrip && index == 3) {
      return _isCategoryComplete(provider, _loadCategory.code,
          optionalIfEmpty: true);
    }
    if (index == environmentIndex) {
      return _isCategoryComplete(provider, _environmentCategory.code,
          optionalIfEmpty: true);
    }
    if (index == reviewIndex) {
      return _confirm;
    }
    return false;
  }

  bool _isCategoryComplete(
    SafetyProvider provider,
    String category, {
    required bool optionalIfEmpty,
  }) {
    final items = _itemsForCategory(provider, category);
    if (items.isEmpty) return optionalIfEmpty;
    return items.every((item) => (item.result ?? '').trim().isNotEmpty);
  }

  List<SafetyCheckItem> _requiredItems(SafetyProvider provider, bool hasTrip) {
    final items = provider.today?.items ?? [];
    return items.where((item) {
      if (!hasTrip && item.category == _loadCategory.code) return false;
      return true;
    }).toList();
  }

  Widget _buildTopSummary({
    required String status,
    required String risk,
    required int completedRequired,
    required int totalRequired,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ស្ថានភាព: ${_statusKh(status)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              _riskPill(risk),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ជម្រើស (អាចរំលង)',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 6),
          Text(
            'បានបំពេញ $completedRequired / $totalRequired ធាតុចាំបាច់',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _riskPill(String risk) {
    final level = risk.toUpperCase();
    Color bg;
    if (level == 'HIGH') {
      bg = Colors.red;
    } else if (level == 'MEDIUM') {
      bg = Colors.orange;
    } else {
      bg = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusKh(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'កំពុងបំពេញ';
      case 'WAITING_APPROVAL':
        return 'រង់ចាំអនុម័ត';
      case 'APPROVED':
        return 'បានអនុម័ត';
      case 'REJECTED':
        return 'ត្រូវបានបដិសេធ';
      default:
        return 'មិនទាន់ចាប់ផ្តើម';
    }
  }

  Widget _buildRejectBanner(String? reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ត្រូវបានបដិសេធ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          if (reason != null && reason.isNotEmpty) Text('មូលហេតុ៖ $reason'),
          const SizedBox(height: 4),
          const Text('សូមជួសជុល និងធ្វើការត្រួតពិនិត្យម្ដងទៀត។'),
        ],
      ),
    );
  }

  List<Widget> _buildVehicleSections(SafetyProvider provider) {
    final widgets = <Widget>[];
    for (final category in _vehicleCategories) {
      final section = _buildCategorySection(provider, category);
      if (section != null) {
        widgets.add(section);
        widgets.add(const SizedBox(height: 12));
      }
    }
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets.isEmpty ? [const Text('មិនមានទិន្នន័យ')] : widgets;
  }

  Widget? _buildCategorySection(
      SafetyProvider provider, _CategoryConfig category) {
    final items = _itemsForCategory(provider, category.code);
    if (items.isEmpty) return null;
    final title = items.first.categoryLabelKm ?? category.labelKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        ...items.map((item) => _buildItemCard(provider, item)),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildItemCard(SafetyProvider provider, SafetyCheckItem item) {
    final readOnly = !provider.canEdit;
    final result = (item.result ?? '').toUpperCase();
    final attachments = _attachmentsForItem(provider, item);
    final showDetail = result.isNotEmpty && result != 'OK';
    final showAttachments = showDetail || attachments.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.itemLabelKm ?? item.itemKey,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _resultOptions.map((opt) {
                final selected = result == opt.value;
                return ChoiceChip(
                  label: Text(opt.labelKm),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: readOnly
                      ? null
                      : (_) {
                          provider.updateItem(
                            item.category,
                            item.itemKey,
                            opt.value,
                            opt.value == 'OK'
                                ? 'LOW'
                                : (item.severity ?? 'MEDIUM'),
                            item.remark,
                            labelKm: item.itemLabelKm,
                          );
                        },
                );
              }).toList(),
            ),
            if (showDetail)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextFormField(
                  key: ValueKey('${item.category}-${item.itemKey}-$result'),
                  initialValue: item.remark ?? '',
                  enabled: !readOnly,
                  decoration: const InputDecoration(
                    labelText: 'សេចក្ដីពន្យល់',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    provider.updateItem(
                      item.category,
                      item.itemKey,
                      result,
                      item.severity ?? 'MEDIUM',
                      val,
                      labelKm: item.itemLabelKm,
                    );
                  },
                ),
              ),
            if (showAttachments) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('រូបភាព៖'),
                  const SizedBox(width: 8),
                  if (!readOnly)
                    TextButton.icon(
                      onPressed: () => _showAttachmentPicker(provider, item),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('បន្ថែម'),
                    ),
                ],
              ),
              if (attachments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('មិនមានរូបភាព',
                      style: TextStyle(color: Colors.black54)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attachments.map((att) {
                    final url = ApiConstants.image(att.fileUrl ?? '');
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(url,
                          width: 72, height: 72, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentStep(SafetyProvider provider) {
    final weatherItem = _itemByKeyOrLabel(
        provider, _environmentCategory.code, 'weather', 'អាកាសធាតុ');
    final roadItem = _itemByKeyOrLabel(
        provider, _environmentCategory.code, 'road', 'ស្ថានភាពផ្លូវ');
    final readOnly = !provider.canEdit;

    final weatherValue = weatherItem?.remark ?? 'Sunny';
    final roadValue = roadItem?.remark ?? 'Good';
    final weatherKey = weatherItem?.itemKey ?? 'weather';
    final roadKey = roadItem?.itemKey ?? 'road';
    final weatherLabel = weatherItem?.itemLabelKm ?? 'អាកាសធាតុ';
    final roadLabel = roadItem?.itemLabelKm ?? 'ស្ថានភាពផ្លូវ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('អាកាសធាតុ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _weatherOptions.map((opt) {
            final selected = weatherValue == opt.value;
            return ChoiceChip(
              label: Text(opt.labelKm),
              selected: selected,
              onSelected: readOnly
                  ? null
                  : (_) {
                      provider.updateItem(
                        _environmentCategory.code,
                        weatherKey,
                        opt.risk ? 'YES_RISK' : 'OK',
                        opt.risk ? 'MEDIUM' : 'LOW',
                        opt.value,
                        labelKm: weatherLabel,
                      );
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('ស្ថានភាពផ្លូវ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _roadOptions.map((opt) {
            final selected = roadValue == opt.value;
            return ChoiceChip(
              label: Text(opt.labelKm),
              selected: selected,
              onSelected: readOnly
                  ? null
                  : (_) {
                      provider.updateItem(
                        _environmentCategory.code,
                        roadKey,
                        opt.risk ? 'YES_RISK' : 'OK',
                        opt.risk ? 'MEDIUM' : 'LOW',
                        opt.value,
                        labelKm: roadLabel,
                      );
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewStep(SafetyProvider provider) {
    final risk = provider.calculateRiskLevel();
    final issues = provider.issues();
    final readOnly = !provider.canEdit;
    final allItems = provider.today?.items ?? [];
    final notes = provider.today?.notes ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('កម្រិតហានិភ័យសរុប: $risk',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('សង្ខេបការត្រួតពិនិត្យ:'),
        const SizedBox(height: 6),
        if (allItems.isEmpty)
          const Text('មិនមានទិន្នន័យ')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              return ListTile(
                dense: true,
                title: Text(item.itemLabelKm ?? item.itemKey),
                subtitle: Text(
                    'លទ្ធផល: ${item.result ?? '-'} | កម្រិត: ${item.severity ?? '-'}'),
              );
            },
          ),
        const SizedBox(height: 12),
        const Text('បញ្ហាដែលរកឃើញ:'),
        const SizedBox(height: 6),
        if (issues.isEmpty)
          const Text('គ្មានបញ្ហា')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final item = issues[index];
              return ListTile(
                dense: true,
                title: Text(item.itemLabelKm ?? item.itemKey),
                subtitle: Text(
                    'លទ្ធផល: ${item.result} | កម្រិត: ${item.severity ?? 'LOW'}'),
              );
            },
          ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('safety-notes-${notes.hashCode}'),
          initialValue: notes,
          enabled: !readOnly,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'កំណត់សម្គាល់សុវត្ថិភាពប្រចាំថ្ងៃ',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: provider.updateNotes,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _confirm,
          onChanged: readOnly
              ? null
              : (val) {
                  setState(() => _confirm = val ?? false);
                },
          title: const Text('ខ្ញុំបញ្ជាក់ថាព័ត៌មាននេះត្រឹមត្រូវ'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  List<SafetyCheckItem> _itemsForCategory(
      SafetyProvider provider, String category) {
    return (provider.today?.items ?? [])
        .where((item) => item.category == category)
        .toList();
  }

  SafetyCheckItem? _itemByKey(
      SafetyProvider provider, String category, String key) {
    final items = provider.today?.items ?? [];
    try {
      return items.firstWhere(
          (item) => item.category == category && item.itemKey == key);
    } catch (_) {
      return null;
    }
  }

  List<SafetyCheckAttachment> _attachmentsForItem(
      SafetyProvider provider, SafetyCheckItem item) {
    final list = provider.today?.attachments ?? [];
    if (item.id == null) return [];
    return list.where((att) => att.itemId == item.id).toList();
  }

  SafetyCheckItem? _itemByKeyOrLabel(
    SafetyProvider provider,
    String category,
    String key,
    String labelKm,
  ) {
    final byKey = _itemByKey(provider, category, key);
    if (byKey != null) return byKey;
    final items = provider.today?.items ?? [];
    final normalizedLabel = _normalizeLabel(labelKm);
    for (final item in items) {
      if (item.category != category) continue;
      final itemLabel = _normalizeLabel(item.itemLabelKm ?? '');
      if (itemLabel.isNotEmpty && itemLabel == normalizedLabel) {
        return item;
      }
    }
    return null;
  }

  String _normalizeLabel(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), '').trim();
  }

  String _apiErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('timed out')) {
      return 'មិនអាចភ្ជាប់ទៅ API បានទេ។ សូមពិនិត្យ URL ឬ Backend។\nAPI: ${ApiConstants.baseUrl}';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'សិទ្ធិមិនត្រឹមត្រូវ (Unauthorized)។ សូមចូលគណនីម្តងទៀត។';
    }
    if (lower.contains('not assigned to a driver') ||
        lower.contains('driver not found')) {
      return 'គណនីនេះមិនបានភ្ជាប់ជាមួយអ្នកបើកបរ។ សូមអោយ Admin បង្កើត/ភ្ជាប់ Driver Account ម្តងទៀត។';
    }
    return 'បញ្ហាក្នុងការភ្ជាប់ API: $raw';
  }

  List<SafetyCheckItem> _missingItems(SafetyProvider provider, bool hasTrip) {
    final items = provider.today?.items ?? [];
    return items.where((item) {
      if (!hasTrip && item.category == _loadCategory.code) {
        return false;
      }
      final result = (item.result ?? '').trim();
      return result.isEmpty;
    }).toList();
  }

  void _showMissingDialog(List<SafetyCheckItem> missing) {
    final preview =
        missing.take(5).map((e) => e.itemLabelKm ?? e.itemKey).join('\n');
    final more =
        missing.length > 5 ? '\n... និង ${missing.length - 5} ផ្សេងទៀត' : '';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ព័ត៌មានមិនគ្រប់គ្រាន់'),
        content: Text('សូមបំពេញធាតុទាំងអស់មុនដាក់ស្នើ។\n\n$preview$more'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('យល់ព្រម'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttachmentPicker(
      SafetyProvider provider, SafetyCheckItem item) async {
    if (_isPicking) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('ថតរូប'),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment(provider, item, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ជ្រើសពីGallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment(provider, item, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment(
    SafetyProvider provider,
    SafetyCheckItem item,
    ImageSource source,
  ) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      if (item.id == null || provider.today?.id == null) {
        await provider.saveDraft();
      }

      final latestItem =
          _itemByKey(provider, item.category, item.itemKey) ?? item;

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;
      final file = File(picked.path);
      await provider.addAttachment(file, itemId: latestItem.id);
      if (!mounted) return;
      final msg =
          _isOnline ? 'បានបន្ថែមរូបភាព' : 'បានរក្សាទុករូបភាព (នឹងផ្ញើពេលអនឡាញ)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('បញ្ហា៖ $e')));
    } finally {
      _isPicking = false;
    }
  }
}

class _CategoryConfig {
  final String code;
  final String labelKm;
  const _CategoryConfig(this.code, this.labelKm);
}

class _ResultOption {
  final String value;
  final String labelKm;
  const _ResultOption(this.value, this.labelKm);
}

class _EnvironmentOption {
  final String value;
  final String labelKm;
  final bool risk;
  const _EnvironmentOption(this.value, this.labelKm, {this.risk = false});
}

const _vehicleCategories = [
  _CategoryConfig('ENGINE', 'ផ្នែកម៉ាស៊ីន'),
  _CategoryConfig('UNDERBODY', 'ផ្នែកគ្រឿងក្រោម'),
  _CategoryConfig('LIGHTS', 'ផ្នែកភ្លើង'),
  _CategoryConfig('VEHICLE_EQUIPMENT', 'សម្ភារះបំពាក់លើរថយន្ត'),
  _CategoryConfig('APPEARANCE', 'សោភ័ណ្ឌភាពរថយន្ត'),
];

const _driverHealthCategory =
    _CategoryConfig('DRIVER_HEALTH', 'សុខភាពអ្នកបើកបរ');
const _safetyEquipmentCategory =
    _CategoryConfig('SAFETY_EQUIPMENT', 'ឧបករណ៍សុវត្ថិភាព');
const _loadCategory = _CategoryConfig('LOAD', 'ទំនិញ');
const _environmentCategory = _CategoryConfig('ENVIRONMENT', 'បរិស្ថាន');

const _resultOptions = [
  _ResultOption('OK', 'ល្អ'),
  _ResultOption('NOT_OK', 'មិនល្អ'),
];

const _weatherOptions = [
  _EnvironmentOption('Sunny', 'ថ្ងៃភ្លឺ'),
  _EnvironmentOption('Rain', 'ភ្លៀង', risk: true),
  _EnvironmentOption('Fog', 'អ័ព្ទ', risk: true),
  _EnvironmentOption('Night', 'យប់', risk: true),
];

const _roadOptions = [
  _EnvironmentOption('Good', 'ល្អ'),
  _EnvironmentOption('Rough', 'ខូចខាត', risk: true),
  _EnvironmentOption('Flood', 'លិចទឹក', risk: true),
  _EnvironmentOption('Construction', 'សំណង់', risk: true),
];
