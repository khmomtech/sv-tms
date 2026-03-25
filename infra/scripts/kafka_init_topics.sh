#!/usr/bin/env bash
# =============================================================================
# kafka_init_topics.sh
#
# PURPOSE
#   Create all SV-TMS Kafka topics on a freshly deployed 3-broker cluster.
#   Run this ONCE after the cluster is healthy on any new environment.
#   It is safe to run again — existing topics are skipped without error.
#
#   Topics created:
#     notification.events          – driver push notifications
#     driver.events                – driver action events (ack, read, location)
#     dispatch.events              – trip/order dispatch lifecycle
#     system.audit.events          – security & change audit trail
#     message.delivery-status.events – delivery confirmation from message-api
#     notification.events.DLT      – dead-letter topic for failed consumers
#
# USAGE
#   cd /srv/svtms/infra
#   bash scripts/kafka_init_topics.sh
#
# TUNING
#   PARTITIONS   3 is a good start — allows 3 parallel consumer instances.
#                Increase if you add more message-api replicas later.
#   REPLICATION  Always 3 (matches the cluster size).
#   RETENTION    7 days by default. The DLT uses 30 days so you have more
#                time to investigate and replay failed messages.
# =============================================================================

set -euo pipefail

BROKER_CONTAINER="svtms-kafka-1"
BOOTSTRAP="kafka-1:9092"
KAFKA_BIN="/opt/bitnami/kafka/bin"

PARTITIONS=3
REPLICATION=3
RETENTION_MS=$(( 7 * 24 * 60 * 60 * 1000 ))       # 7 days in milliseconds
DLT_RETENTION_MS=$(( 30 * 24 * 60 * 60 * 1000 ))  # 30 days for dead-letter

# ── helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
kexec() { docker exec "$BROKER_CONTAINER" "$@"; }

create_topic() {
  local TOPIC=$1
  local RETENTION=$2

  # Check if topic already exists
  EXISTS=$(kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --list | grep -cx "^${TOPIC}$" || true)

  if [[ "$EXISTS" -gt 0 ]]; then
    log "  SKIP  '$TOPIC' already exists"
    return
  fi

  kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --create \
    --topic "$TOPIC" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION" \
    --config min.insync.replicas=2 \
    --config retention.ms="$RETENTION" \
    --config cleanup.policy=delete

  log "  ✓ Created '$TOPIC'  (partitions=$PARTITIONS, rf=$REPLICATION, retention=${RETENTION}ms)"
}

# ── confirm cluster is up ─────────────────────────────────────────────────────
log "Checking Kafka cluster..."
kexec "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server "$BOOTSTRAP" --list > /dev/null
log "Cluster reachable. Creating topics..."
echo ""

# ── create all topics ─────────────────────────────────────────────────────────
create_topic "notification.events"              "$RETENTION_MS"
create_topic "driver.events"                    "$RETENTION_MS"
create_topic "dispatch.events"                  "$RETENTION_MS"
create_topic "system.audit.events"              "$RETENTION_MS"
create_topic "message.delivery-status.events"   "$RETENTION_MS"

# Dead-letter topic — longer retention so failed messages can be investigated
create_topic "notification.events.DLT"          "$DLT_RETENTION_MS"

# ── verify ────────────────────────────────────────────────────────────────────
echo ""
log "Topic summary:"
kexec "$KAFKA_BIN/kafka-topics.sh" \
  --bootstrap-server "$BOOTSTRAP" \
  --describe \
  --topics-with-overrides 2>/dev/null || \
kexec "$KAFKA_BIN/kafka-topics.sh" \
  --bootstrap-server "$BOOTSTRAP" \
  --list

echo ""
log "Done. All topics ready."
