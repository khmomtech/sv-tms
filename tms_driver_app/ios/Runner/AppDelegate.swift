import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import AppTrackingTransparency
import AdSupport
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = registrar(forPlugin: "NativeServicePlugin") {
      NativeServicePlugin.register(with: registrar)
    }

    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        #if DEBUG
        print("Notification permission request error: \(error.localizedDescription)")
        #endif
      }
      #if DEBUG
      print("Notification permission granted: \(granted)")
      #endif
    }
    Messaging.messaging().delegate = self
    application.registerForRemoteNotifications()

    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        #if DEBUG
        print("ATT authorization status: \(status.rawValue)")
        #endif
      }
    }

    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

    // Auto-resume native iOS tracking if config already exists (cold start / relaunch).
    IOSBackgroundLocationManager.shared.startIfConfigured()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    IOSBackgroundLocationManager.shared.performBackgroundFetch(completion: completionHandler)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    #if DEBUG
    print("APNs token registered successfully.")
    #endif
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else { return }
    #if DEBUG
    print("FCM registration token: \(token)")
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    #if DEBUG
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    #endif
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
}

private final class NativeServicePlugin: NSObject, FlutterPlugin {
  private let locationManager = IOSBackgroundLocationManager.shared

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sv/native_service", binaryMessenger: registrar.messenger())
    let diagChannel = FlutterMethodChannel(name: "diag", binaryMessenger: registrar.messenger())
    let plugin = NativeServicePlugin()
    registrar.addMethodCallDelegate(plugin, channel: channel)
    diagChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getDiagnostics", "getInfo":
        result(plugin.locationManager.diagnostics())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startService":
      guard let args = call.arguments as? [String: Any] else {
        result(false)
        return
      }
      let token = (args["token"] as? String) ?? ""
      let trackingToken = (args["trackingToken"] as? String) ?? ""
      let trackingSessionId = (args["trackingSessionId"] as? String) ?? ""
      let refreshToken = (args["refreshToken"] as? String) ?? ""
      let driverId = (args["driverId"] as? String) ?? ""
      let baseApiUrl = (args["baseApiUrl"] as? String) ?? ""
      let started = locationManager.start(
        token: token,
        trackingToken: trackingToken,
        trackingSessionId: trackingSessionId,
        refreshToken: refreshToken,
        driverId: driverId,
        baseApiUrl: baseApiUrl
      )
      result(started)

    case "updateToken":
      guard let args = call.arguments as? [String: Any],
            let token = args["token"] as? String else {
        result(false)
        return
      }
      locationManager.updateToken(token)
      result(true)

    case "notifyTokenUpdated":
      let args = call.arguments as? [String: Any]
      if let token = args?["token"] as? String,
         !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        locationManager.updateToken(token)
      } else {
        locationManager.reloadTokenFromDefaults()
      }
      if let refreshToken = args?["refreshToken"] as? String,
         !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        locationManager.updateRefreshToken(refreshToken)
      }
      if let trackingToken = args?["trackingToken"] as? String,
         !trackingToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        locationManager.updateTrackingToken(trackingToken)
      }
      if let trackingSessionId = args?["trackingSessionId"] as? String,
         !trackingSessionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        locationManager.updateTrackingSessionId(trackingSessionId)
      }
      result(true)

    case "stopService":
      locationManager.stop()
      result(true)

    case "isServiceRunning":
      result(locationManager.isRunning)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

private final class IOSBackgroundLocationManager: NSObject, CLLocationManagerDelegate {
  static let shared = IOSBackgroundLocationManager()

  private let manager = CLLocationManager()
  private let defaults = UserDefaults.standard

  private let keyToken = "ios_native_token"
  private let keyTrackingToken = "ios_native_tracking_token"
  private let keyTrackingSessionId = "ios_native_tracking_session_id"
  private let keyRefreshToken = "ios_native_refresh_token"
  private let keyDriverId = "ios_native_driver_id"
  private let keyBaseApiUrl = "ios_native_base_api_url"
  private let keyPendingQueue = "ios_native_pending_queue"

  private var token: String = ""
  private var trackingToken: String = ""
  private var trackingSessionId: String = ""
  private var refreshToken: String = ""
  private var driverId: String = ""
  private var baseApiUrl: String = ""
  private(set) var isRunning: Bool = false

  private var lastSentAt: Date?
  private var lastSentLocation: CLLocation?
  private let minInterval: TimeInterval = 8
  private let minDistanceMeters: CLLocationDistance = 10
  private var pointSeq: Int64 = 0
  private var heartbeatTimer: DispatchSourceTimer?
  private var lastHeartbeatAt: Date?
  private let heartbeatInterval: TimeInterval = 20
  private let heartbeatMinGap: TimeInterval = 12
  private let heartbeatAuthCooldown: TimeInterval = 15
  private let tokenSettleDelay: TimeInterval = 3
  private let maxPendingQueueSize = 5000
  private let maxPendingAgeMs: TimeInterval = 2 * 60 * 60 * 1000 // 2h
  private let queueLock = DispatchQueue(label: "com.svtrucking.svdriverapp.ios.pending-queue")
  private var pendingPayloads: [[String: Any]] = []
  private var heartbeatCooldownUntil: Date?
  private var tokenSettledUntil: Date?

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    manager.distanceFilter = 10
    manager.pausesLocationUpdatesAutomatically = false
    if #available(iOS 9.0, *) {
      manager.allowsBackgroundLocationUpdates = true
    }
  }

  func start(
    token: String,
    trackingToken: String,
    trackingSessionId: String,
    refreshToken: String,
    driverId: String,
    baseApiUrl: String
  ) -> Bool {
    self.token = normalizeToken(token)
    self.trackingToken = normalizeToken(trackingToken)
    self.trackingSessionId = trackingSessionId.trimmingCharacters(in: .whitespacesAndNewlines)
    self.refreshToken = normalizeToken(refreshToken)
    self.driverId = driverId.trimmingCharacters(in: .whitespacesAndNewlines)
    self.baseApiUrl = baseApiUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    persistConfig()
    noteTokenMaterialUpdated(scheduleHeartbeat: false)
    return startIfConfigured()
  }

  func startIfConfigured() -> Bool {
    loadConfig()
    loadPendingQueue()
    guard hasConfig else { return false }
    requestPermissionIfNeeded()
    startUpdates()
    flushPendingQueue()
    return true
  }

  /// Called by iOS background fetch to attempt flushing the pending queue.
  /// This is best-effort and returns immediately (iOS expects a quick completion).
  func performBackgroundFetch(completion: @escaping (UIBackgroundFetchResult) -> Void) {
    loadConfig()
    loadPendingQueue()

    queueLock.sync {
      if pendingPayloads.isEmpty {
        completion(.noData)
        return
      }
    }

    // Attempt to flush queued points and report the result to iOS.
    flushPendingQueue { result in
      completion(result)
    }
  }

  func stop() {
    manager.stopUpdatingLocation()
    manager.stopMonitoringSignificantLocationChanges()
    clearConfig()
    isRunning = false
  }

  func updateToken(_ token: String) {
    self.token = normalizeToken(token)
    defaults.set(self.token, forKey: keyToken)
    noteTokenMaterialUpdated()
  }

  func updateTrackingToken(_ token: String) {
    self.trackingToken = normalizeToken(token)
    defaults.set(self.trackingToken, forKey: keyTrackingToken)
    noteTokenMaterialUpdated()
  }

  func updateTrackingSessionId(_ sessionId: String) {
    self.trackingSessionId = sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
    defaults.set(self.trackingSessionId, forKey: keyTrackingSessionId)
    noteTokenMaterialUpdated()
  }

  func updateRefreshToken(_ refreshToken: String) {
    self.refreshToken = normalizeToken(refreshToken)
    defaults.set(self.refreshToken, forKey: keyRefreshToken)
    noteTokenMaterialUpdated()
  }

  func reloadTokenFromDefaults() {
    token = normalizeToken(defaults.string(forKey: keyToken) ?? "")
    trackingToken = normalizeToken(defaults.string(forKey: keyTrackingToken) ?? "")
    trackingSessionId = (defaults.string(forKey: keyTrackingSessionId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    refreshToken = normalizeToken(defaults.string(forKey: keyRefreshToken) ?? "")
    noteTokenMaterialUpdated()
  }

  private var hasConfig: Bool {
    return !heartbeatAuthToken().isEmpty && !driverId.isEmpty && !baseApiUrl.isEmpty
  }

  private func persistConfig() {
    defaults.set(token, forKey: keyToken)
    defaults.set(trackingToken, forKey: keyTrackingToken)
    defaults.set(trackingSessionId, forKey: keyTrackingSessionId)
    defaults.set(refreshToken, forKey: keyRefreshToken)
    defaults.set(driverId, forKey: keyDriverId)
    defaults.set(baseApiUrl, forKey: keyBaseApiUrl)
  }

  private func loadConfig() {
    token = normalizeToken(defaults.string(forKey: keyToken) ?? "")
    trackingToken = normalizeToken(defaults.string(forKey: keyTrackingToken) ?? "")
    trackingSessionId = (defaults.string(forKey: keyTrackingSessionId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    refreshToken = normalizeToken(defaults.string(forKey: keyRefreshToken) ?? "")
    driverId = (defaults.string(forKey: keyDriverId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    baseApiUrl = (defaults.string(forKey: keyBaseApiUrl) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func loadPendingQueue() {
    queueLock.sync {
      pendingPayloads = (defaults.array(forKey: keyPendingQueue) as? [[String: Any]]) ?? []

      // Drop stale entries (avoid replaying very old points)
      pendingPayloads.removeAll { isPendingPayloadStale($0) }

      if pendingPayloads.count > maxPendingQueueSize {
        pendingPayloads = Array(pendingPayloads.suffix(maxPendingQueueSize))
        persistPendingQueueLocked()
      }
    }
  }

  private func isPendingPayloadStale(_ payload: [String: Any]) -> Bool {
    guard let clientTime = payload["clientTime"] as? Int else { return false }
    let ageMs = Date().timeIntervalSince1970 * 1000 - Double(clientTime)
    return ageMs > maxPendingAgeMs
  }

  private func requestPermissionIfNeeded() {
    let status = currentAuthorizationStatus()
    if status == .notDetermined {
      manager.requestAlwaysAuthorization()
    }
  }

  private func startUpdates() {
    manager.startUpdatingLocation()
    manager.startMonitoringSignificantLocationChanges()
    isRunning = true
    noteTokenMaterialUpdated(scheduleHeartbeat: false)
    startHeartbeatLoop()
    scheduleHeartbeatKick(reason: "service-start", delay: tokenSettleDelay)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = currentAuthorizationStatus()
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      startUpdates()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let loc = locations.last else { return }
    let shouldUploadLocation = shouldSend(loc)
    if shouldUploadLocation {
      lastSentAt = Date()
      lastSentLocation = loc
      sendToBackend(location: loc)
    }
    // Keep online presence fresh even when location is deduped.
    sendPresenceHeartbeat(reason: shouldUploadLocation ? "location-update" : "location-dedup")
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    #if DEBUG
    print("iOS location update failed: \(error.localizedDescription)")
    #endif
  }

  private func shouldSend(_ loc: CLLocation) -> Bool {
    if let t = lastSentAt, Date().timeIntervalSince(t) < minInterval {
      return false
    }
    if let prev = lastSentLocation, loc.distance(from: prev) < minDistanceMeters {
      return false
    }
    if loc.horizontalAccuracy < 0 || loc.horizontalAccuracy > 100 {
      return false
    }
    return true
  }

  private func sendToBackend(location: CLLocation) {
    let speed = location.speed >= 0 ? location.speed : 0
    let heading = location.course >= 0 ? location.course : 0
    pointSeq += 1
    let clientTimeMs = Int(Date().timeIntervalSince1970 * 1000)
    var payload: [String: Any] = [
      "driverId": Int(driverId) ?? 0,
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "speed": speed,
      "heading": heading,
      "accuracyMeters": location.horizontalAccuracy,
      "source": "IOS_NATIVE",
      "locationSource": "gps",
      "clientTime": clientTimeMs,
      "seq": pointSeq,
      "pointId": "\(driverId)-\(clientTimeMs)-\(pointSeq)"
    ]

    sendLocationPayload(payload: payload, allowRetryOnUnauthorized: true, fromQueue: false)
  }

  private func sendLocationPayload(
    payload: [String: Any],
    allowRetryOnUnauthorized: Bool,
    fromQueue: Bool,
    completion: ((Bool) -> Void)? = nil
  ) {
    guard hasConfig else {
      if !fromQueue {
        enqueuePendingPayload(payload)
      }
      completion?(false)
      return
    }
    guard let authToken = locationWriteAuthToken() else {
      if !fromQueue {
        enqueuePendingPayload(payload)
      }
      completion?(false)
      return
    }
    guard let url = URL(string: "\(baseApiUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/driver/location/update") else {
      completion?(false)
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      #if DEBUG
      print("iOS payload serialization failed: \(error.localizedDescription)")
      #endif
      completion?(false)
      return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        #if DEBUG
        print("iOS location upload failed: \(error.localizedDescription)")
        #endif
        if !fromQueue {
          self.enqueuePendingPayload(payload)
        }
        completion?(false)
        return
      }

      guard let http = response as? HTTPURLResponse else {
        #if DEBUG
        print("iOS location upload failed: missing HTTP response")
        #endif
        if !fromQueue {
          self.enqueuePendingPayload(payload)
        }
        completion?(false)
        return
      }

      let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
      if (200..<300).contains(http.statusCode) {
        if fromQueue {
          self.dequeuePendingPayload()
        }
        self.flushPendingQueue()
        completion?(true)
        return
      }

      #if DEBUG
      print("iOS location upload non-2xx status=\(http.statusCode) body=\(body)")
      #endif

      // On 403: the tracking session is stale or mismatched — a token refresh
      // won't fix it. Clear the tracking session so the next upload forces a
      // fresh startTrackingSession call instead of looping forever.
      if http.statusCode == 403 {
        self.clearTrackingSession()
        if !fromQueue {
          self.enqueuePendingPayload(payload)
        }
        completion?(false)
        return
      }

      guard http.statusCode == 401, allowRetryOnUnauthorized else {
        if !fromQueue {
          self.enqueuePendingPayload(payload)
        }
        completion?(false)
        return
      }

      let refreshed = self.refreshLocationAuth()
      guard refreshed else {
        #if DEBUG
        print("iOS location upload retry aborted: refresh failed")
        #endif
        if !fromQueue {
          self.enqueuePendingPayload(payload)
        }
        completion?(false)
        return
      }
      self.sendLocationPayload(
        payload: payload,
        allowRetryOnUnauthorized: false,
        fromQueue: fromQueue,
        completion: completion
      )
    }.resume()
  }

  private func normalizeToken(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("bearer ") {
      return String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return trimmed
  }

  private func locationWriteAuthToken() -> String? {
    if !trackingSessionId.isEmpty {
      return trackingToken.isEmpty ? nil : trackingToken
    }
    if !trackingToken.isEmpty { return trackingToken }
    return token.isEmpty ? nil : token
  }

  private func heartbeatAuthToken() -> String {
    if !trackingToken.isEmpty { return trackingToken }
    return token
  }

  private func refreshLocationAuth() -> Bool {
    if !trackingSessionId.isEmpty {
      return refreshTrackingToken()
    }
    return refreshTrackingToken() || refreshAccessToken()
  }

  /// Clears the stale tracking session from memory and persistent storage.
  /// Called on 403 so the next location upload triggers a fresh startTrackingSession.
  private func clearTrackingSession() {
    trackingToken = ""
    trackingSessionId = ""
    defaults.removeObject(forKey: keyTrackingToken)
    defaults.removeObject(forKey: keyTrackingSessionId)
  }

  private func enqueuePendingPayload(_ payload: [String: Any]) {
    queueLock.sync {
      // Drop stale items before adding new one.
      pendingPayloads.removeAll { isPendingPayloadStale($0) }

      if pendingPayloads.count >= maxPendingQueueSize {
        pendingPayloads.removeFirst()
      }
      pendingPayloads.append(payload)
      persistPendingQueueLocked()
    }
  }

  private func dequeuePendingPayload() {
    queueLock.sync {
      guard !pendingPayloads.isEmpty else { return }
      pendingPayloads.removeFirst()
      persistPendingQueueLocked()
    }
  }

  private func nextPendingPayload() -> [String: Any]? {
    queueLock.sync {
      pendingPayloads.first
    }
  }

  private func flushPendingQueue() {
    flushPendingQueue(completion: nil)
  }

  private func flushPendingQueue(completion: ((UIBackgroundFetchResult) -> Void)?) {
    guard let payload = nextPendingPayload() else {
      completion?(.noData)
      return
    }

    sendLocationPayload(payload: payload, allowRetryOnUnauthorized: true, fromQueue: true) { success in
      completion?(success ? .newData : .failed)
    }
  }

  private func persistPendingQueueLocked() {
    defaults.set(pendingPayloads, forKey: keyPendingQueue)
    // Force a sync to reduce risk of losing queue during sudden app termination.
    defaults.synchronize()
  }

  func diagnostics() -> [String: Any] {
    let queueDepth = queueLock.sync { pendingPayloads.count }
    let queueBytes = defaults.array(forKey: keyPendingQueue)
      .flatMap { try? JSONSerialization.data(withJSONObject: $0) }?.count ?? 0
    let lastHeartbeatMs = Int((lastHeartbeatAt?.timeIntervalSince1970 ?? 0) * 1000)
    return [
      "baseApi": baseApiUrl,
      "wsUrl": "",
      "driverId": driverId,
      "driverName": "",
      "vehiclePlate": "",
      "running": isRunning,
      "alive": isRunning,
      "lastHeartbeatMs": lastHeartbeatMs,
      "pendingQueueDepth": queueDepth,
      "pendingQueueBytes": queueBytes,
      "hasAccessToken": !token.isEmpty,
      "hasTrackingToken": !trackingToken.isEmpty,
      "hasTrackingSessionId": !trackingSessionId.isEmpty
    ]
  }

  private func clearConfig() {
    defaults.removeObject(forKey: keyToken)
    defaults.removeObject(forKey: keyTrackingToken)
    defaults.removeObject(forKey: keyTrackingSessionId)
    defaults.removeObject(forKey: keyRefreshToken)
    defaults.removeObject(forKey: keyDriverId)
    defaults.removeObject(forKey: keyBaseApiUrl)
    defaults.removeObject(forKey: keyPendingQueue)
    token = ""
    trackingToken = ""
    trackingSessionId = ""
    refreshToken = ""
    driverId = ""
    baseApiUrl = ""
    queueLock.sync {
      pendingPayloads.removeAll()
    }
    stopHeartbeatLoop()
  }

  private func stopHeartbeatLoop() {
    heartbeatTimer?.cancel()
    heartbeatTimer = nil
  }

  private func startHeartbeatLoop() {
    stopHeartbeatLoop()
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
    timer.schedule(deadline: .now() + heartbeatInterval, repeating: heartbeatInterval)
    timer.setEventHandler { [weak self] in
      self?.sendPresenceHeartbeat(reason: "timer")
    }
    timer.resume()
    heartbeatTimer = timer
  }

  private func currentBatteryPercent() -> Int? {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    guard level >= 0 else { return nil }
    let pct = Int((level * 100.0).rounded())
    return max(0, min(100, pct))
  }

  private func gpsEnabledNow() -> Bool {
    let status = currentAuthorizationStatus()
    return status == .authorizedAlways || status == .authorizedWhenInUse
  }

  private func sendPresenceHeartbeat(
    reason: String = "timer",
    force: Bool = false,
    clientTsMs: Int? = nil
  ) {
    guard hasConfig else { return }
    let now = Date()
    if let settleUntil = tokenSettledUntil, now < settleUntil {
      return
    }
    if let cooldownUntil = heartbeatCooldownUntil, now < cooldownUntil {
      return
    }
    if !force, let last = lastHeartbeatAt, Date().timeIntervalSince(last) < heartbeatMinGap {
      return
    }

    let api = baseApiUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard let url = URL(string: "\(api)/driver/presence/heartbeat") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(heartbeatAuthToken())", forHTTPHeaderField: "Authorization")

    let nowMs = clientTsMs ?? Int(Date().timeIntervalSince1970 * 1000)
    var payload: [String: Any] = [
      "driverId": Int(driverId) ?? 0,
      "device": "NATIVE_IOS",
      "gpsEnabled": gpsEnabledNow(),
      "ts": nowMs,
      "reason": reason
    ]
    if let battery = currentBatteryPercent() {
      payload["battery"] = battery
    }

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      #if DEBUG
      print("iOS heartbeat payload serialization failed: \(error.localizedDescription)")
      #endif
      return
    }
    sendPresenceRequest(request, payload: payload, allowRetryOnUnauthorized: true)
    lastHeartbeatAt = Date()
  }

  private func sendPresenceRequest(
    _ request: URLRequest,
    payload: [String: Any],
    allowRetryOnUnauthorized: Bool
  ) {
    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        #if DEBUG
        print("iOS heartbeat upload failed: \(error.localizedDescription)")
        #endif
        return
      }
      guard let http = response as? HTTPURLResponse else { return }
      if (200..<300).contains(http.statusCode) {
        self.flushPendingQueue()
        return
      }
      #if DEBUG
      let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
      print("iOS heartbeat non-2xx status=\(http.statusCode) body=\(body)")
      #endif

      // On 403: clear stale tracking session — a token refresh won't resolve
      // a session/payload mismatch. The next heartbeat will use the access token.
      if http.statusCode == 403 {
        self.clearTrackingSession()
        return
      }
      guard http.statusCode == 401, allowRetryOnUnauthorized else { return }
      let refreshed = self.refreshTrackingToken() || self.refreshAccessToken()
      guard refreshed else { return }
      self.heartbeatCooldownUntil = Date().addingTimeInterval(self.heartbeatAuthCooldown)
      self.tokenSettledUntil = Date().addingTimeInterval(self.tokenSettleDelay)
      self.scheduleHeartbeatKick(reason: "auth-retry", delay: self.heartbeatAuthCooldown)
    }.resume()
  }

  private func noteTokenMaterialUpdated(scheduleHeartbeat: Bool = true) {
    tokenSettledUntil = Date().addingTimeInterval(tokenSettleDelay)
    if scheduleHeartbeat {
      scheduleHeartbeatKick(reason: "token-update", delay: tokenSettleDelay)
    }
  }

  private func scheduleHeartbeatKick(reason: String, delay: TimeInterval) {
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.sendPresenceHeartbeat(reason: reason)
    }
  }

  private func refreshAccessToken() -> Bool {
    let api = baseApiUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard !api.isEmpty, !refreshToken.isEmpty,
          let url = URL(string: "\(api)/auth/refresh") else {
      return false
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = "{}".data(using: .utf8)

    let semaphore = DispatchSemaphore(value: 0)
    var refreshed = false
    URLSession.shared.dataTask(with: request) { data, response, error in
      defer { semaphore.signal() }
      if let error = error {
        #if DEBUG
        print("iOS token refresh failed: \(error.localizedDescription)")
        #endif
        return
      }
      guard let http = response as? HTTPURLResponse else { return }
      guard (200..<300).contains(http.statusCode) else {
        #if DEBUG
        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        print("iOS token refresh non-2xx status=\(http.statusCode) body=\(body)")
        #endif
        return
      }
      guard let data = data else { return }
      do {
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let payload = (raw["data"] as? [String: Any]) ?? raw
        let access = ((payload["token"] as? String)
                   ?? (payload["access_token"] as? String)
                   ?? (payload["accessToken"] as? String)
                   ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nextRefresh = ((payload["refresh_token"] as? String)
                        ?? (payload["refreshToken"] as? String)
                        ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !access.isEmpty else { return }
        self.token = self.normalizeToken(access)
        self.defaults.set(self.token, forKey: self.keyToken)
        if !nextRefresh.isEmpty {
          self.refreshToken = self.normalizeToken(nextRefresh)
          self.defaults.set(self.refreshToken, forKey: self.keyRefreshToken)
        }
        refreshed = true
      } catch {
        #if DEBUG
        print("iOS token refresh parse failed: \(error.localizedDescription)")
        #endif
      }
    }.resume()
    _ = semaphore.wait(timeout: .now() + 10)
    return refreshed
  }

  private func refreshTrackingToken() -> Bool {
    let api = baseApiUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard !api.isEmpty,
          !trackingToken.isEmpty,
          let url = URL(string: "\(api)/driver/tracking/session/refresh") else {
      return false
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(trackingToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = "{}".data(using: .utf8)

    let semaphore = DispatchSemaphore(value: 0)
    var refreshed = false
    URLSession.shared.dataTask(with: request) { data, response, error in
      defer { semaphore.signal() }
      if let error = error {
        #if DEBUG
        print("iOS tracking token refresh failed: \(error.localizedDescription)")
        #endif
        return
      }
      guard let http = response as? HTTPURLResponse else { return }
      guard (200..<300).contains(http.statusCode) else {
        #if DEBUG
        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        print("iOS tracking token refresh non-2xx status=\(http.statusCode) body=\(body)")
        #endif
        return
      }
      guard let data = data else { return }
      do {
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let payload = (raw["data"] as? [String: Any]) ?? raw
        let nextTracking = ((payload["trackingToken"] as? String)
                         ?? (payload["tracking_token"] as? String)
                         ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nextSessionId = ((payload["sessionId"] as? String)
                          ?? (payload["session_id"] as? String)
                          ?? self.trackingSessionId).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nextTracking.isEmpty else { return }
        self.trackingToken = self.normalizeToken(nextTracking)
        self.trackingSessionId = nextSessionId
        self.defaults.set(self.trackingToken, forKey: self.keyTrackingToken)
        self.defaults.set(self.trackingSessionId, forKey: self.keyTrackingSessionId)
        refreshed = true
      } catch {
        #if DEBUG
        print("iOS tracking token refresh parse failed: \(error.localizedDescription)")
        #endif
      }
    }.resume()
    _ = semaphore.wait(timeout: .now() + 10)
    return refreshed
  }

  private func currentAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return manager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }
}
