package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleActorsUpdateRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowAssignDispatchRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowPublishRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowResolutionDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowSimulationRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowSimulationResponse;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleReorderRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowRuleUpsertRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateVersionDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchFlowTemplateUpsertRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofEventDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofReviewDecisionRequest;
import com.svtrucking.logistics.dto.dispatchflow.DispatchProofStateDto;
import com.svtrucking.logistics.dto.dispatchflow.DispatchWorkflowBindingDto;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.DispatchFlowAdminService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/dispatch-flow")
@RequiredArgsConstructor
public class DispatchFlowAdminController {

  private final DispatchFlowAdminService dispatchFlowAdminService;

  @GetMapping("/templates")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchFlowTemplateDto>>> listTemplates() {
    return ResponseEntity.ok(new ApiResponse<>(true, "Templates fetched", dispatchFlowAdminService.listTemplates()));
  }

  @PostMapping("/templates")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowTemplateDto>> createTemplate(
      @Valid @RequestBody DispatchFlowTemplateUpsertRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Template created", dispatchFlowAdminService.createTemplate(request)));
  }

  @PutMapping("/templates/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowTemplateDto>> updateTemplate(
      @PathVariable Long id,
      @Valid @RequestBody DispatchFlowTemplateUpsertRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Template updated", dispatchFlowAdminService.updateTemplate(id, request)));
  }

  @GetMapping("/templates/{id}/versions")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchFlowTemplateVersionDto>>> listVersions(@PathVariable Long id) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Template versions fetched", dispatchFlowAdminService.listVersions(id)));
  }

  @PostMapping("/templates/{id}/versions/publish")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowTemplateVersionDto>> publishVersion(
      @PathVariable Long id,
      @RequestBody(required = false) DispatchFlowPublishRequest request) {
    DispatchFlowPublishRequest payload = request == null ? new DispatchFlowPublishRequest() : request;
    return ResponseEntity.ok(new ApiResponse<>(
        true, "Template version published", dispatchFlowAdminService.publishTemplateVersion(id, payload)));
  }

  @PostMapping("/versions/{versionId}/rollback")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowTemplateVersionDto>> rollbackVersion(
      @PathVariable Long versionId,
      @RequestBody(required = false) DispatchFlowPublishRequest request) {
    DispatchFlowPublishRequest payload = request == null ? new DispatchFlowPublishRequest() : request;
    return ResponseEntity.ok(new ApiResponse<>(
        true, "Template version rolled back", dispatchFlowAdminService.rollbackVersion(versionId, payload)));
  }

  @DeleteMapping("/templates/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<Void>> deleteTemplate(@PathVariable Long id) {
    dispatchFlowAdminService.deleteTemplate(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Template deleted", null));
  }

  @GetMapping("/templates/{id}/rules")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchFlowRuleDto>>> listRules(@PathVariable Long id) {
    return ResponseEntity.ok(new ApiResponse<>(true, "Rules fetched", dispatchFlowAdminService.listRules(id)));
  }

  @GetMapping("/resolve/{dispatchId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowResolutionDto>> resolveDispatchFlow(@PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch flow resolved", dispatchFlowAdminService.resolveDispatchFlow(dispatchId)));
  }

  @PostMapping("/simulate")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowSimulationResponse>> simulate(
      @Valid @RequestBody DispatchFlowSimulationRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch flow simulated", dispatchFlowAdminService.simulate(request)));
  }

  @GetMapping("/proof-state/{dispatchId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchProofStateDto>> getProofState(@PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch proof state fetched", dispatchFlowAdminService.getProofState(dispatchId)));
  }

  @GetMapping("/binding/{dispatchId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchWorkflowBindingDto>> getWorkflowBinding(@PathVariable Long dispatchId) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch workflow binding fetched", dispatchFlowAdminService.getWorkflowBinding(dispatchId)));
  }

  @PostMapping("/assign-dispatches")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchWorkflowBindingDto>>> assignDispatches(
      @Valid @RequestBody DispatchFlowAssignDispatchRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Dispatch workflows assigned", dispatchFlowAdminService.assignDispatchTemplates(request)));
  }

  @GetMapping("/proof-review")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchProofEventDto>>> listPendingProofReview() {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Pending proof reviews fetched", dispatchFlowAdminService.listPendingProofReview()));
  }

  @PostMapping("/proof-review/{eventId}/decision")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchProofEventDto>> reviewProofEvent(
      @PathVariable Long eventId,
      @Valid @RequestBody DispatchProofReviewDecisionRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Proof review updated", dispatchFlowAdminService.reviewProofEvent(eventId, request)));
  }

  @PostMapping("/templates/{id}/rules")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowRuleDto>> createRule(
      @PathVariable Long id,
      @Valid @RequestBody DispatchFlowRuleUpsertRequest request) {
    return ResponseEntity.ok(new ApiResponse<>(true, "Rule created", dispatchFlowAdminService.createRule(id, request)));
  }

  @PutMapping("/templates/{id}/rules/reorder")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<List<DispatchFlowRuleDto>>> reorderRules(
      @PathVariable Long id,
      @Valid @RequestBody DispatchFlowRuleReorderRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Rules reordered", dispatchFlowAdminService.reorderRules(id, request)));
  }

  @PutMapping("/rules/{ruleId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowRuleDto>> updateRule(
      @PathVariable Long ruleId,
      @Valid @RequestBody DispatchFlowRuleUpsertRequest request) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Rule updated", dispatchFlowAdminService.updateRule(ruleId, request)));
  }

  @PutMapping("/rules/{ruleId}/actors")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<DispatchFlowRuleDto>> updateRuleActors(
      @PathVariable Long ruleId,
      @Valid @RequestBody DispatchFlowRuleActorsUpdateRequest request) {
    return ResponseEntity.ok(new ApiResponse<>(
        true,
        "Rule actors updated",
        dispatchFlowAdminService.updateRuleActors(ruleId, request)));
  }

  @DeleteMapping("/rules/{ruleId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.DISPATCH_FLOW_MANAGE + "')")
  public ResponseEntity<ApiResponse<Void>> deleteRule(@PathVariable Long ruleId) {
    dispatchFlowAdminService.deleteRule(ruleId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Rule deleted", null));
  }
}
