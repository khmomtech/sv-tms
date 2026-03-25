package com.svtrucking.logistics.support.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.service.AuditRecordService;
import java.util.Arrays;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class AuditAspect {

  private final AuditRecordService auditRecordService;
  private final ObjectMapper mapper = new ObjectMapper();

  public AuditAspect(AuditRecordService auditRecordService) {
    this.auditRecordService = auditRecordService;
  }

  @Around("@annotation(com.svtrucking.logistics.support.audit.AuditedAction)")
  public Object aroundAudited(ProceedingJoinPoint pjp) throws Throwable {
    MethodSignature ms = (MethodSignature) pjp.getSignature();
    AuditedAction ann = ms.getMethod().getAnnotation(AuditedAction.class);
    String action = ann.value();
    Object[] args = pjp.getArgs();
    String before = null;
    try {
      if (args != null && args.length > 0) {
        before = mapper.writeValueAsString(Arrays.asList(args));
      }
    } catch (Exception e) {
      before = null;
    }

    Object result = pjp.proceed();

    String after = null;
    try {
      after = mapper.writeValueAsString(result);
    } catch (Exception e) {
      after = null;
    }

    // best-effort: if action starts with driver. or vehicle. route accordingly
    if (action.startsWith("driver.")) {
      auditRecordService.recordDriverAudit(null, action, before, after, "system");
    } else if (action.startsWith("vehicle.")) {
      // Try to extract vehicleId from arguments (first Long or long value)
      Long vehicleId = null;
      if (args != null) {
        for (Object arg : args) {
          if (arg instanceof Long) {
            vehicleId = (Long) arg;
            break;
          } else if (arg != null && arg.getClass().getName().equals("long")) {
            vehicleId = (Long) arg;
            break;
          }
        }
      }
      if (vehicleId != null) {
        auditRecordService.recordVehicleAudit(vehicleId, action, before, after, "system");
      } // else skip audit if no vehicleId found
    }

    return result;
  }
}
