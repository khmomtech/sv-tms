package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import org.springframework.stereotype.Component;

/**
 * Guards workflow transitions for queue and loading actions.
 */
@Component
public class DispatchWorkflowValidator {

  public boolean canEnterQueue(Dispatch dispatch) {
    requireDispatch(dispatch);
    return dispatch.getStatus() == DispatchStatus.ARRIVED_LOADING
      || dispatch.getStatus() == DispatchStatus.SAFETY_PASSED
      || dispatch.getStatus() == DispatchStatus.IN_QUEUE
      || dispatch.getStatus() == DispatchStatus.LOADING
      || dispatch.getStatus() == DispatchStatus.LOADED;
  }

  public void ensureCanEnterQueue(Dispatch dispatch) {
    requireDispatch(dispatch);
    if (!canEnterQueue(dispatch)) {
      throw new IllegalStateException("Dispatch must be SAFETY_PASSED before entering the loading queue.");
    }
  }

  public boolean canStartLoading(Dispatch dispatch) {
    requireDispatch(dispatch);
    return dispatch.getStatus() == DispatchStatus.IN_QUEUE
      || dispatch.getStatus() == DispatchStatus.LOADING;
  }

  public void ensureCanStartLoading(Dispatch dispatch) {
    requireDispatch(dispatch);
    if (!canStartLoading(dispatch)) {
      throw new IllegalStateException(
          "Loading can start only after queue entry (status IN_QUEUE) and pre-entry safety pass.");
    }
  }

  private void requireDispatch(Dispatch dispatch) {
    if (dispatch == null) {
      throw new IllegalArgumentException("Dispatch cannot be null");
    }
  }
}
