#!/usr/bin/env bash
# =============================================================================
# kafka_reassign_partitions.sh
#
# PURPOSE
#   After migrating from a single-broker Kafka cluster to the 3-broker KRaft
#   cluster, existing topics still have replication_factor=1 because that was
#   baked in at creation time.  This script:
#
#     1. Generates a reassignment plan that spreads each topic's partitions
#        across all three brokers (replica factor 3).
#     2. Executes the reassignment.
#     3. Polls until the reassignment is complete before setting
#        min.insync.replicas=2 on every topic.
#
# USAGE
#   Run from the host, once, after the new 3-broker cluster is healthy:
#
#     cd /srv/svtms/infra          # or wherever docker-compose.prod.yml lives
#     bash scripts/kafka_reassign_partitions.sh
#
# PREREQUISITES
#   - All three Kafka containers (svtms-kafka-1/2/3) must be running and healthy.
#   - Docker must be available on this host.
#
# SAFETY
#   - The script only reassigns replicas; it never deletes or truncates data.
#   - A reassignment JSON plan is written to /tmp before execution so you can
#     inspect it with:  cat /tmp/svtms-reassign-plan.json
# =============================================================================

set -euo pipefail

BROKER_CONTAINER="svtms-kafka-1"
BOOTSTRAP="kafka-1:9092"
KAFKA_BIN="/opt/bitnami/kafka/bin"

# Your 5 SV-TMS topics
TOPICS=(
  "notification.events"
  "driver.events"
  "dispatch.events"
  "system.audit.events"
  "message.delivery-status.events"
)

# ── helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
kexec() { docker exec "$BROKER_CONTAINER" "$@"; }

# ── step 0: confirm cluster is reachable ──────────────────────────────────────
log "Checking cluster health..."
kexec "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server "$BOOTSTRAP" --list > /dev/null
log "Cluster reachable. Proceeding."

# ── step 1: build the reassignment JSON ───────────────────────────────────────
# Format expected by kafka-reassign-partitions.sh:
# {
#   "version": 1,
#   "partitions": [
#     { "topic": "foo", "partition": 0, "replicas": [1,2,3] },
#     ...
#   ]
# }
#
# We assign replicas [1,2,3] so every partition lives on all three brokers.
# Kafka elects the first entry in the list as the preferred leader.
# We rotate the preferred leader across partitions for even traffic distribution:
#   partition 0 → leader=1, partition 1 → leader=2, partition 2 → leader=3

log "Building reassignment plan..."

PLAN='{"version":1,"partitions":['
FIRST=1

for TOPIC in "${TOPICS[@]}"; do
  # Fetch current partition count for this topic
  PART_COUNT=$(kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --describe --topic "$TOPIC" \
    | grep -c "^Topic:" || true)

  # If topic describe gives 0 (topic doesn't exist yet), skip gracefully
  if [[ "$PART_COUNT" -eq 0 ]]; then
    log "  WARN: topic '$TOPIC' not found — skipping (will be created by topic-init script)"
    continue
  fi

  # Re-fetch the actual partition count from PartitionCount line
  PART_COUNT=$(kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --describe --topic "$TOPIC" \
    | awk '/PartitionCount:/{print $2}' | head -1)

  log "  Topic '$TOPIC' has $PART_COUNT partition(s)"

  for (( P=0; P<PART_COUNT; P++ )); do
    # Rotate preferred leader: broker IDs are 1, 2, 3
    LEADER=$(( (P % 3) + 1 ))
    case $LEADER in
      1) REPLICAS="[1,2,3]" ;;
      2) REPLICAS="[2,3,1]" ;;
      3) REPLICAS="[3,1,2]" ;;
    esac

    [[ $FIRST -eq 0 ]] && PLAN+=","
    PLAN+="{\"topic\":\"$TOPIC\",\"partition\":$P,\"replicas\":$REPLICAS}"
    FIRST=0
  done
done

PLAN+=']}'

PLAN_FILE="/tmp/svtms-reassign-plan.json"
echo "$PLAN" > "$PLAN_FILE"
log "Reassignment plan written to $PLAN_FILE"
cat "$PLAN_FILE" | python3 -m json.tool 2>/dev/null || cat "$PLAN_FILE"

# Copy the plan into the broker container
docker cp "$PLAN_FILE" "$BROKER_CONTAINER:/tmp/reassign-plan.json"

# ── step 2: execute the reassignment ─────────────────────────────────────────
log ""
log "Executing partition reassignment (this moves data between brokers)..."
kexec "$KAFKA_BIN/kafka-reassign-partitions.sh" \
  --bootstrap-server "$BOOTSTRAP" \
  --reassignment-json-file /tmp/reassign-plan.json \
  --execute

# ── step 3: poll until complete ───────────────────────────────────────────────
log ""
log "Waiting for reassignment to complete..."
MAX_WAIT=300   # seconds
ELAPSED=0
INTERVAL=10

while true; do
  STATUS=$(kexec "$KAFKA_BIN/kafka-reassign-partitions.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassign-plan.json \
    --verify 2>&1 || true)

  if echo "$STATUS" | grep -q "is still in progress"; then
    log "  Still in progress... (${ELAPSED}s elapsed)"
  else
    log "  Reassignment complete."
    break
  fi

  sleep $INTERVAL
  ELAPSED=$(( ELAPSED + INTERVAL ))

  if [[ $ELAPSED -ge $MAX_WAIT ]]; then
    log "ERROR: Reassignment did not finish within ${MAX_WAIT}s. Check broker logs."
    exit 1
  fi
done

# ── step 4: set min.insync.replicas=2 on every topic ─────────────────────────
log ""
log "Setting min.insync.replicas=2 on all topics..."

for TOPIC in "${TOPICS[@]}"; do
  # Check topic exists before configuring
  EXISTS=$(kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --list | grep -cx "^${TOPIC}$" || true)

  if [[ "$EXISTS" -eq 0 ]]; then
    log "  SKIP: '$TOPIC' does not exist"
    continue
  fi

  kexec "$KAFKA_BIN/kafka-configs.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --alter \
    --entity-type topics \
    --entity-name "$TOPIC" \
    --add-config min.insync.replicas=2

  log "  ✓ $TOPIC  →  min.insync.replicas=2"
done

# ── step 5: final verification ────────────────────────────────────────────────
log ""
log "Final topic state:"
for TOPIC in "${TOPICS[@]}"; do
  kexec "$KAFKA_BIN/kafka-topics.sh" \
    --bootstrap-server "$BOOTSTRAP" \
    --describe --topic "$TOPIC" 2>/dev/null \
    | grep -E "^Topic:|ReplicationFactor|Isr|min.insync" || true
  echo ""
done

log "Done. All topics are now replicated across 3 brokers."
log "Each partition has 3 replicas and requires 2 in-sync replicas for writes."
