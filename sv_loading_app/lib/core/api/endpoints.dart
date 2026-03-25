class Endpoints {
  static const login = '/api/auth/login';
  static const adminDispatches = '/api/admin/dispatches';
  static const adminDispatchesFilter = '/api/admin/dispatches/filter';
  static String adminDispatchActions(int dispatchId) =>
      '/api/admin/dispatches/$dispatchId/available-actions';
  static String adminDispatchStatus(int dispatchId) =>
      '/api/admin/dispatches/$dispatchId/status';

  static const loadingQueue = '/api/loading-ops/queue';
  static String loadingQueueCall(int queueId) =>
      '/api/loading-ops/queue/$queueId/call';
  static String loadingQueueGate(int queueId) =>
      '/api/loading-ops/queue/$queueId/gate';
  static String loadingQueueByDispatch(int dispatchId) =>
      '/api/loading-ops/queue/dispatch/$dispatchId';

  static const loadingSessionStart = '/api/loading-ops/sessions/start';
  static const loadingSessionComplete = '/api/loading-ops/sessions/complete';
  static String loadingSessionByDispatch(int dispatchId) =>
      '/api/loading-ops/sessions/dispatch/$dispatchId';
  static String loadingSessionUploadDocument(int sessionId) =>
      '/api/loading-ops/sessions/$sessionId/documents';

  static String loadingDispatchDetail(int dispatchId) =>
      '/api/loading-ops/dispatch/$dispatchId/detail';

  static const preEntrySafetySubmit = '/api/admin/pre-entry-safety/submit';
  static String preEntrySafetyByDispatch(int dispatchId) =>
      '/api/admin/pre-entry-safety/dispatch/$dispatchId';
  static String preEntrySafetyOverride(int checkId) =>
      '/api/admin/pre-entry-safety/$checkId/override';
  static const preEntrySafetyList = '/api/admin/pre-entry-safety';
  static const preEntrySafetyUploadPhoto =
      '/api/admin/pre-entry-safety/photos/upload';

  static String tripTimeline(String tripId) => '/api/trips/$tripId/timeline';
}
