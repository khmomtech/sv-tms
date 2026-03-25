#!/usr/bin/env bash
# Simulator capture helper: screenshots and video recording for iOS Simulator
# Usage: ./sim_capture.sh <action> <output>
# Actions:
#   screenshot <file.png>    -> captures a screenshot of the booted simulator
#   record <file.mp4>        -> records video until CTRL-C (use again to stop if background)
# Example:
#   ./sim_capture.sh screenshot review_home.png
#   ./sim_capture.sh record review_flow.mp4

set -euo pipefail
ACTION=${1:-}
OUT=${2:-}
if [[ -z "$ACTION" || -z "$OUT" ]]; then
  echo "Usage: $0 screenshot|record <output-file>"; exit 1
fi

if ! xcrun simctl list devices | grep -q "Booted"; then
  echo "No booted simulator. Boot a simulator (e.g. iPhone 14 iOS 17) in Simulator.app or via 'xcrun simctl boot <id>'"; exit 2
fi

case "$ACTION" in
  screenshot)
    echo "Capturing screenshot to $OUT"
    xcrun simctl io booted screenshot "$OUT"
    echo "Saved $OUT"
    ;;
  record)
    echo "Recording video to $OUT. Press CTRL+C to stop."
    xcrun simctl io booted recordVideo "$OUT"
    echo "Saved $OUT"
    ;;
  *)
    echo "Unknown action: $ACTION"; exit 3
    ;;
esac
