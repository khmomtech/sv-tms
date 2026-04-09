enum ActionType {
  progress,
  arrival,
  operation,
  completion,
  revert,
  destructive,
  administrative,
}

class DispatchActionMetadata {
  final String targetStatus;
  final String actionLabel;
  final ActionType actionType;
  final String iconName;
  final String buttonColor;
  final bool requiresConfirmation;
  final bool requiresAdminApproval;
  final bool driverInitiated;
  final bool requiresInput;
  final String? validationMessage;
  final List<String> allowedActorTypes;
  final bool allowedForCurrentUser;
  final String? blockedReason;
  final String? blockedCode;
  final String requiredInput;
  final String? inputRouteHint;
  final String? templateCode;
  final int? ruleId;
  final List<String> proofSubmissionAllowedStatuses;
  final String? proofSubmissionMode;
  final bool proofReviewRequired;
  final bool allowLateProofRecovery;
  final String? autoAdvanceStatusAfterProof;
  final int? workflowVersionId;
  final int priority;
  final bool isDestructive;

  DispatchActionMetadata({
    required this.targetStatus,
    required this.actionLabel,
    required this.actionType,
    required this.iconName,
    required this.buttonColor,
    required this.requiresConfirmation,
    required this.requiresAdminApproval,
    required this.driverInitiated,
    required this.requiresInput,
    this.validationMessage,
    this.allowedActorTypes = const [],
    this.allowedForCurrentUser = true,
    this.blockedReason,
    this.blockedCode,
    this.requiredInput = 'NONE',
    this.inputRouteHint,
    this.templateCode,
    this.ruleId,
    this.proofSubmissionAllowedStatuses = const [],
    this.proofSubmissionMode,
    this.proofReviewRequired = false,
    this.allowLateProofRecovery = false,
    this.autoAdvanceStatusAfterProof,
    this.workflowVersionId,
    required this.priority,
    required this.isDestructive,
  });

  factory DispatchActionMetadata.fromJson(Map<String, dynamic> json) {
    return DispatchActionMetadata(
      targetStatus: json['targetStatus'] as String,
      actionLabel: json['actionLabel'] as String,
      actionType: _parseActionType(json['actionType'] as String?),
      iconName: json['iconName'] as String? ?? 'arrow_forward',
      buttonColor: json['buttonColor'] as String? ?? '#2196F3',
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      requiresAdminApproval: json['requiresAdminApproval'] as bool? ?? false,
      driverInitiated: json['driverInitiated'] as bool? ?? true,
      requiresInput: json['requiresInput'] as bool? ?? false,
      validationMessage: json['validationMessage'] as String?,
      allowedActorTypes:
          (json['allowedActorTypes'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      allowedForCurrentUser: json['allowedForCurrentUser'] as bool? ?? true,
      blockedReason: json['blockedReason'] as String?,
      blockedCode: json['blockedCode'] as String?,
      requiredInput: (json['requiredInput'] as String? ?? 'NONE').toUpperCase(),
      inputRouteHint: json['inputRouteHint'] as String?,
      templateCode: json['templateCode'] as String?,
      ruleId: json['ruleId'] as int?,
      proofSubmissionAllowedStatuses:
          (json['proofSubmissionAllowedStatuses'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      proofSubmissionMode: json['proofSubmissionMode'] as String?,
      proofReviewRequired: json['proofReviewRequired'] as bool? ?? false,
      allowLateProofRecovery: json['allowLateProofRecovery'] as bool? ?? false,
      autoAdvanceStatusAfterProof:
          json['autoAdvanceStatusAfterProof'] as String?,
      workflowVersionId: json['workflowVersionId'] as int?,
      priority: json['priority'] as int? ?? 50,
      isDestructive: json['isDestructive'] as bool? ?? false,
    );
  }

  static ActionType _parseActionType(String? type) {
    if (type == null) return ActionType.progress;
    switch (type.toUpperCase()) {
      case 'PROGRESS':
        return ActionType.progress;
      case 'ARRIVAL':
        return ActionType.arrival;
      case 'OPERATION':
        return ActionType.operation;
      case 'COMPLETION':
        return ActionType.completion;
      case 'REVERT':
        return ActionType.revert;
      case 'DESTRUCTIVE':
        return ActionType.destructive;
      case 'ADMINISTRATIVE':
        return ActionType.administrative;
      default:
        return ActionType.progress;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'targetStatus': targetStatus,
      'actionLabel': actionLabel,
      'actionType': actionType.name.toUpperCase(),
      'iconName': iconName,
      'buttonColor': buttonColor,
      'requiresConfirmation': requiresConfirmation,
      'requiresAdminApproval': requiresAdminApproval,
      'driverInitiated': driverInitiated,
      'requiresInput': requiresInput,
      'validationMessage': validationMessage,
      'allowedActorTypes': allowedActorTypes,
      'allowedForCurrentUser': allowedForCurrentUser,
      'blockedReason': blockedReason,
      'blockedCode': blockedCode,
      'requiredInput': requiredInput,
      'inputRouteHint': inputRouteHint,
      'templateCode': templateCode,
      'ruleId': ruleId,
      'proofSubmissionAllowedStatuses': proofSubmissionAllowedStatuses,
      'proofSubmissionMode': proofSubmissionMode,
      'proofReviewRequired': proofReviewRequired,
      'allowLateProofRecovery': allowLateProofRecovery,
      'autoAdvanceStatusAfterProof': autoAdvanceStatusAfterProof,
      'workflowVersionId': workflowVersionId,
      'priority': priority,
      'isDestructive': isDestructive,
    };
  }

  @override
  String toString() {
    return 'DispatchActionMetadata(targetStatus: $targetStatus, label: $actionLabel, priority: $priority)';
  }
}

/// Response model for available actions API
class DispatchActionsResponse {
  final int dispatchId;
  final String currentStatus;
  final String? previousStatus;
  final bool isTerminal;
  final DateTime? updatedAt;
  final bool canPerformActions;
  final String? actionRestrictionMessage;
  final String? loadingTypeCode;
  final String? loadingTypeName;
  final int? workflowVersionId;
  final int? resolvedWorkflowVersionId;

  /// Rich action metadata (NEW in Phase 4)
  final List<DispatchActionMetadata> availableActions;

  /// Legacy field for backward compatibility
  final List<String> availableNextStates;

  DispatchActionsResponse({
    required this.dispatchId,
    required this.currentStatus,
    this.previousStatus,
    required this.isTerminal,
    this.updatedAt,
    required this.canPerformActions,
    this.actionRestrictionMessage,
    this.loadingTypeCode,
    this.loadingTypeName,
    this.workflowVersionId,
    this.resolvedWorkflowVersionId,
    required this.availableActions,
    required this.availableNextStates,
  });

  factory DispatchActionsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> actionsJson =
        json['availableActions'] as List<dynamic>? ?? [];
    final List<dynamic> statesJson =
        json['availableNextStates'] as List<dynamic>? ?? [];

    return DispatchActionsResponse(
      dispatchId: json['dispatchId'] as int,
      currentStatus: json['currentStatus'] as String,
      previousStatus: json['previousStatus'] as String?,
      isTerminal: json['isTerminal'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      canPerformActions: json['canPerformActions'] as bool? ?? true,
      actionRestrictionMessage: json['actionRestrictionMessage'] as String?,
      loadingTypeCode: json['loadingTypeCode'] as String?,
      loadingTypeName: json['loadingTypeName'] as String?,
      workflowVersionId: json['workflowVersionId'] as int?,
      resolvedWorkflowVersionId: json['resolvedWorkflowVersionId'] as int?,
      availableActions: actionsJson
          .map(
              (a) => DispatchActionMetadata.fromJson(a as Map<String, dynamic>))
          .toList(),
      availableNextStates: statesJson.map((s) => s.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispatchId': dispatchId,
      'currentStatus': currentStatus,
      'previousStatus': previousStatus,
      'isTerminal': isTerminal,
      'updatedAt': updatedAt?.toIso8601String(),
      'canPerformActions': canPerformActions,
      'actionRestrictionMessage': actionRestrictionMessage,
      'loadingTypeCode': loadingTypeCode,
      'loadingTypeName': loadingTypeName,
      'workflowVersionId': workflowVersionId,
      'resolvedWorkflowVersionId': resolvedWorkflowVersionId,
      'availableActions': availableActions.map((a) => a.toJson()).toList(),
      'availableNextStates': availableNextStates,
    };
  }

  /// Check if any driver-initiated actions are available
  bool get hasDriverActions {
    return canPerformActions &&
        availableActions.any(
            (action) => action.driverInitiated && action.allowedForCurrentUser);
  }

  /// Get only driver-initiated actions (filter out admin-only)
  List<DispatchActionMetadata> get driverActions {
    return availableActions
        .where(
            (action) => action.driverInitiated && action.allowedForCurrentUser)
        .toList();
  }

  @override
  String toString() {
    return 'DispatchActionsResponse(dispatchId: $dispatchId, currentStatus: $currentStatus, actions: ${availableActions.length}, canPerform: $canPerformActions)';
  }
}
