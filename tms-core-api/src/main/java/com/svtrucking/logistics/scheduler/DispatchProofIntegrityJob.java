package com.svtrucking.logistics.scheduler;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.LoadProof;
import com.svtrucking.logistics.model.UnloadProof;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.LoadProofRepository;
import com.svtrucking.logistics.repository.UnloadProofRepository;
import com.svtrucking.logistics.service.FileStorageService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class DispatchProofIntegrityJob {

  private final DispatchRepository dispatchRepository;
  private final LoadProofRepository loadProofRepository;
  private final UnloadProofRepository unloadProofRepository;
  private final FileStorageService fileStorageService;

  @Scheduled(cron = "${dispatch.proof.integrity.cron:0 */10 * * * *}")
  public void verifyProofIntegrity() {
    List<Dispatch> polRequiredStatuses = dispatchRepository.findByStatusIn(
        List.of(DispatchStatus.LOADED, DispatchStatus.IN_TRANSIT, DispatchStatus.ARRIVED_UNLOADING,
            DispatchStatus.UNLOADING, DispatchStatus.UNLOADED, DispatchStatus.DELIVERED, DispatchStatus.COMPLETED));

    for (Dispatch dispatch : polRequiredStatuses) {
      LoadProof loadProof = dispatch.getLoadProof();
      boolean hasPol = loadProof != null
          || Boolean.TRUE.equals(dispatch.getPolSubmitted())
          || loadProofRepository.findByDispatchId(dispatch.getId()).isPresent();
      if (!hasPol) {
        log.error("POL integrity breach: dispatchId={} status={} has no POL row", dispatch.getId(), dispatch.getStatus());
      }
    }

    List<Dispatch> podRequiredStatuses = dispatchRepository.findByStatusIn(
        List.of(DispatchStatus.UNLOADED, DispatchStatus.DELIVERED, DispatchStatus.COMPLETED, DispatchStatus.CLOSED));
    for (Dispatch dispatch : podRequiredStatuses) {
      UnloadProof unloadProof = dispatch.getUnloadProof();
      UnloadProof canonical = unloadProof != null
          ? unloadProof
          : unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatch.getId()).orElse(null);
      if (canonical == null) {
        log.error("POD integrity breach: dispatchId={} status={} has no POD row", dispatch.getId(), dispatch.getStatus());
        continue;
      }
      long existingImages = canonical.getProofImagePaths() == null
          ? 0
          : canonical.getProofImagePaths().stream().filter(fileStorageService::existsPublicPath).count();
      long totalImages = canonical.getProofImagePaths() == null ? 0 : canonical.getProofImagePaths().size();
      if (totalImages > 0 && existingImages != totalImages) {
        log.error(
            "POD integrity breach: dispatchId={} status={} missing files total={} existing={}",
            dispatch.getId(),
            dispatch.getStatus(),
            totalImages,
            existingImages);
      }
    }
  }
}
