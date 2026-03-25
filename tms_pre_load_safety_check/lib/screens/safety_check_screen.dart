import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/dispatch.dart';
import '../models/safety_check.dart';
import '../services/pending_queue_service.dart';
import '../services/safety_service.dart';
import '../services/stats_service.dart';
import '../widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({
    super.key,
    required this.dispatchId,
  });

  final int dispatchId;

  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends State<SafetyCheckScreen> {
  static const _maxPhotos = 5;
  DispatchInfo? dispatch;
  PreLoadingSafetyCheck? latest;
  bool loading = true;
  bool submitting = false;
  String? error;
  final Random _random = Random();

  bool driverPpeOk = true;
  bool fireExtinguisherOk = true;
  bool wheelChockOk = true;
  bool truckLeakageOk = true;
  bool truckCleanOk = true;
  bool truckConditionOk = true;
  SafetyResult selectedResult = SafetyResult.pass;
  final TextEditingController _failReasonController = TextEditingController();

  final List<File> photos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final safetyService = Provider.of<SafetyService>(context, listen: false);
      final fetchedDispatch =
          await safetyService.fetchDispatch(widget.dispatchId);
      PreLoadingSafetyCheck? latestCheck;
      try {
        latestCheck = await safetyService.fetchLatest(widget.dispatchId);
      } catch (_) {
        latestCheck = null;
      }
      setState(() {
        dispatch = fetchedDispatch;
        latest = latestCheck;
        if (latestCheck != null) {
          driverPpeOk = latestCheck.driverPpeOk;
          fireExtinguisherOk = latestCheck.fireExtinguisherOk;
          wheelChockOk = latestCheck.wheelChockOk;
          truckLeakageOk = latestCheck.truckLeakageOk;
          truckCleanOk = latestCheck.truckCleanOk;
          truckConditionOk = latestCheck.truckConditionOk;
          selectedResult = latestCheck.result;
          _failReasonController.text = latestCheck.failReason ?? '';
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _pickPhoto() async {
    if (photos.length >= _maxPhotos) {
      setState(() => error = 'photoLimit'.tr());
      return;
    }
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked != null) {
      setState(() {
        error = null;
        photos.add(File(picked.path));
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?['message'] ?? e.message;
      return [if (code != null) 'HTTP $code', if (msg != null) msg].join(' - ');
    }
    return e.toString();
  }

  bool _shouldQueueOffline(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
        return false;
      case DioExceptionType.unknown:
        return e.error is SocketException;
    }
  }

  String _generateClientUuid() {
    String segment(int length) {
      const chars = '0123456789abcdef';
      return List.generate(length, (_) => chars[_random.nextInt(chars.length)])
          .join();
    }

    return '${segment(8)}-${segment(4)}-4${segment(3)}-'
        '${'89ab'[_random.nextInt(4)]}${segment(3)}-${segment(12)}';
  }

  Future<void> _submit() async {
    if (selectedResult == SafetyResult.fail &&
        (_failReasonController.text.isEmpty)) {
      setState(() => error = 'failReasonRequired'.tr());
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });

    final request = SafetyCheckRequest(
      dispatchId: widget.dispatchId,
      driverPpeOk: driverPpeOk,
      fireExtinguisherOk: fireExtinguisherOk,
      wheelChockOk: wheelChockOk,
      truckLeakageOk: truckLeakageOk,
      truckCleanOk: truckCleanOk,
      truckConditionOk: truckConditionOk,
      result: selectedResult,
      failReason: selectedResult == SafetyResult.fail
          ? _failReasonController.text.trim()
          : null,
      checkedAt: DateTime.now(),
      checkedByUserId: int.tryParse(
          Provider.of<AuthProvider>(context, listen: false).userId ?? ''),
      clientUuid: _generateClientUuid(),
    );

    try {
      final safetyService = Provider.of<SafetyService>(context, listen: false);
      final stats = Provider.of<StatsService>(context, listen: false);
      final saved = await safetyService.submitSafetyCheck(
        request,
        photoPaths: photos.map((p) => p.path).toList(),
      );
      await stats.recordResult(selectedResult);
      setState(() => photos.clear());
      await _load();
      if (!mounted) return;
      final movedToLoading = saved.autoTransitionApplied == true &&
          (saved.dispatchStatusAfterCheck ?? '').toUpperCase() == 'LOADING';
      final isPass = selectedResult == SafetyResult.pass;
      final message = movedToLoading
          ? 'preEntryPassedMovedLoading'.tr()
          : isPass
              ? (saved.transitionMessage ?? 'saved'.tr())
              : 'preEntryFailedBlocked'.tr();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on DioException catch (e) {
      if (_shouldQueueOffline(e)) {
        final pendingQueue =
            Provider.of<PendingQueueService>(context, listen: false);
        await pendingQueue.enqueue(request,
            photoPaths: photos.map((p) => p.path).toList());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('offlineSaved'.tr())),
        );
      } else {
        setState(() => error = _friendlyError(e));
      }
    } catch (e) {
      setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Future<void> _retryPending() async {
    final pendingQueue =
        Provider.of<PendingQueueService>(context, listen: false);
    final safetyService = Provider.of<SafetyService>(context, listen: false);
    final stats = Provider.of<StatsService>(context, listen: false);
    final synced = await pendingQueue.retryPending(safetyService, stats: stats);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced > 0 ? 'retrySuccess'.tr() : 'offlineSaved'.tr(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _failReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('safetyChecklist'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: submitting ? null : _retryPending,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dispatchCard(),
            const SizedBox(height: 12),
            _latestCard(),
            const SizedBox(height: 12),
            _checklistCard(),
            const SizedBox(height: 12),
            _resultCard(),
            const SizedBox(height: 12),
            _photoCard(),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: submitting ? 'saving'.tr() : 'submit'.tr(),
              onPressed: submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dispatchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'dispatchId'.tr()}: ${widget.dispatchId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (dispatch != null) ...[
              const SizedBox(height: 4),
              Text('${'driver'.tr()}: ${dispatch!.driverName ?? '-'}'),
              Text('${'truck'.tr()}: ${dispatch!.licensePlate ?? '-'}'),
              Text('${'routeCode'.tr()}: ${dispatch!.routeCode ?? '-'}'),
              if (dispatch!.status != null)
                Text('${'statusLabel'.tr()}: ${dispatch!.status}'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _infoTile(
                      icon: Icons.factory_outlined,
                      label: 'dispatchLoading'.tr(),
                      value: dispatch!.loadingLocation ?? '-',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoTile(
                      icon: Icons.local_shipping_outlined,
                      label: 'dispatchUnloading'.tr(),
                      value: dispatch!.unloadingLocation ?? '-',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey[700])),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestCard() {
    final latestResult = latest != null
        ? (latest!.result == SafetyResult.pass ? 'pass'.tr() : 'fail'.tr())
        : 'noResult'.tr();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('latestResult'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(latestResult),
            if (latest?.failReason != null) Text(latest!.failReason!),
            if (latest?.checkedByName != null)
              Text(
                  '${'lastUpdated'.tr()}: ${latest!.checkedByName} (${latest!.formattedTimestamp()})'),
          ],
        ),
      ),
    );
  }

  Widget _checklistCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('checklist'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _section(
              title: 'safetySectionPpe'.tr(),
              tiles: [
                _toggleTile(
                  icon: Icons.health_and_safety_outlined,
                  label: 'driverPpeOk'.tr(),
                  value: driverPpeOk,
                  onChanged: (v) => setState(() => driverPpeOk = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _section(
              title: 'safetySectionTools'.tr(),
              tiles: [
                _toggleTile(
                  icon: Icons.local_fire_department_outlined,
                  label: 'fireExtinguisherOk'.tr(),
                  value: fireExtinguisherOk,
                  onChanged: (v) => setState(() => fireExtinguisherOk = v),
                ),
                _toggleTile(
                  icon: Icons.construction_outlined,
                  label: 'wheelChockOk'.tr(),
                  value: wheelChockOk,
                  onChanged: (v) => setState(() => wheelChockOk = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _section(
              title: 'safetySectionVehicle'.tr(),
              tiles: [
                _toggleTile(
                  icon: Icons.oil_barrel_outlined,
                  label: 'truckLeakageOk'.tr(),
                  value: truckLeakageOk,
                  onChanged: (v) => setState(() => truckLeakageOk = v),
                ),
                _toggleTile(
                  icon: Icons.cleaning_services_outlined,
                  label: 'truckCleanOk'.tr(),
                  value: truckCleanOk,
                  onChanged: (v) => setState(() => truckCleanOk = v),
                ),
                _toggleTile(
                  icon: Icons.car_repair_outlined,
                  label: 'truckConditionOk'.tr(),
                  value: truckConditionOk,
                  onChanged: (v) => setState(() => truckConditionOk = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> tiles}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...tiles,
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Colors.green.shade700),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        dense: true,
      ),
    );
  }

  Widget _resultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('result'.tr(), style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: Text('pass'.tr()),
                  selected: selectedResult == SafetyResult.pass,
                  onSelected: (v) =>
                      setState(() => selectedResult = SafetyResult.pass),
                ),
                ChoiceChip(
                  label: Text('fail'.tr()),
                  selected: selectedResult == SafetyResult.fail,
                  onSelected: (v) =>
                      setState(() => selectedResult = SafetyResult.fail),
                ),
              ],
            ),
            if (selectedResult == SafetyResult.fail)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _failReasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'failReason'.tr(),
                    hintText: 'failReasonPlaceholder'.tr(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('photoProof'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: photos.length >= _maxPhotos
                        ? 'maxPhotosReached'.tr()
                        : 'takePhoto'.tr(),
                    onPressed: photos.length >= _maxPhotos ? null : _pickPhoto,
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => photos.clear()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text('removePhoto'.tr()),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'photoLimitNote'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photos
                    .asMap()
                    .entries
                    .map(
                      (entry) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              entry.value,
                              height: 110,
                              width: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() => photos.removeAt(entry.key));
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
