Capture instructions — short demo for App Review

Goal: record 30-60s video showing reviewer flow: login → On Duty → accept location → open job → upload POD

Recommended devices
- iPhone 14 or 15, iOS 17+

Simulator (macOS)
- Boot an iOS Simulator (Simulator.app) matching device + iOS version.
- Use `tms_driver_app/scripts/sim_capture.sh`:

```bash
# screenshot
./tms_driver_app/scripts/sim_capture.sh screenshot review_home.png

# record (press CTRL+C to stop)
./tms_driver_app/scripts/sim_capture.sh record review_flow.mp4
```

Physical device (screen recording)
- Use QuickTime (Connect iPhone → New Movie Recording → select device) or built-in iOS screen recorder.
- Steps to record:
  1. Install TestFlight build or deploy from Xcode.
  2. Log in with reviewer@test.sv / Review!234.
  3. Tap "On Duty" and allow foreground location when prompted.
  4. Open a job, take/upload POD photo, and confirm submission.

Naming & upload
- Name files: `review_video_<device>-YYYYMMDD.mp4`, `review_screens_<device>-YYYYMMDD.png`
- Upload to App Store Connect or provide via secure link in reviewer notes.
