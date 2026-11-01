#!/usr/bin/env bash
# collect_evidence.sh - Evidence collection and preservation
# MIT8321 CA, Lab Exercise 4 - Case SB-2026-001
# Order: volatile data first (RFC 3227 order of volatility), then logs,
# file-system and configuration data. Every item is hashed (SHA-256 + MD5),
# listed in an evidence register, recorded in a chain-of-custody file,
# then sealed read-only and archived.
set -u

CASE_ID="SB-2026-001"
INVESTIGATOR="Feyi Abioye"
LAB_DIR="$HOME/secure-cyber-fortress"
CASE_DIR="$HOME/case_${CASE_ID}"
EV="$CASE_DIR/evidence"
LOG="$CASE_DIR/collection_log.txt"
REGISTER="$CASE_DIR/evidence_register.csv"
COC="$CASE_DIR/chain_of_custody.csv"
APP="securebank-app"

ts()  { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { echo "$(ts) | $INVESTIGATOR | $*" | tee -a "$LOG"; }

# Never overwrite evidence that already exists
if [ -d "$EV" ] && [ -n "$(ls -A "$EV" 2>/dev/null)" ]; then
  echo "ERROR: $EV already holds evidence. Refusing to overwrite it."
  exit 1
fi
mkdir -p "$EV/config"

declare -a ORDER=()
declare -A DESC SRC WHEN

# capture OUTFILE "description" "source" command [args...]
capture() {
  local out="$1" desc="$2" src="$3"; shift 3
  WHEN[$out]="$(ts)"; DESC[$out]="$desc"; SRC[$out]="$src"; ORDER+=("$out")
  log "COLLECT $out <= $*"
  {
    echo "# Case: $CASE_ID | Collected: ${WHEN[$out]} | By: $INVESTIGATOR | Host: $(hostname)"
    echo "# Source: $src"
    echo "# Command: $*"
    echo
    "$@" 2>&1
  } > "$EV/$out"
}

# copy_file SOURCE_PATH OUTFILE "description"  (cp -p keeps original timestamps)
copy_file() {
  local from="$1" out="$2" desc="$3"
  if [ -f "$from" ]; then
    WHEN[$out]="$(ts)"; DESC[$out]="$desc"; SRC[$out]="$from"; ORDER+=("$out")
    cp -p "$from" "$EV/$out"
    log "COPY $out <= $from"
  else
    log "SKIP $out (not found: $from)"
  fi
}

log "=== Collection started for case $CASE_ID on $(hostname) ==="

# 1. Volatile data: system state, network, processes
capture system_info.txt "System time, host and Docker version" "VM host" \
  bash -c 'date -u; echo; hostname; uname -a; echo; uptime; echo; timedatectl 2>/dev/null; echo; docker version --format "Docker server {{.Server.Version}}"'
capture network_connections.txt "Listening ports and active connections on the VM" "VM host" \
  sudo ss -tulpan
capture app_network_connections.txt "Listening ports and connections inside the app container" "$APP container" \
  docker exec "$APP" netstat -tulpan
capture network_interfaces.txt "Network interfaces and IP addresses on the VM" "VM host" \
  ip addr show
capture container_network.txt "Docker lab network with each container IP" "Docker engine" \
  bash -c 'docker network inspect $(docker network ls -q --filter name=securebank-net)'
capture running_processes.txt "All running processes on the VM" "VM host" \
  ps auxww --sort=start_time
capture container_processes.txt "Processes running inside each lab container" "Docker engine" \
  bash -c 'for c in $(docker ps --format "{{.Names}}"); do echo "=== $c ==="; docker top "$c"; echo; done'
capture lab_containers.txt "Lab containers, images, status and published ports" "Docker engine" \
  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

# 2. Logs
copy_file "$LAB_DIR/evidence/securebank.log" securebank.log "SecureBank application security log"
capture app_container_output.txt "App container console output with Docker timestamps" "$APP container" \
  docker logs --timestamps "$APP"
copy_file "$LAB_DIR/evidence/attack_timeline.txt" attack_timeline.txt "Attack timeline written by the lab attack script"
capture log_files.txt "Log files present on the VM file system" "VM host" \
  bash -c "sudo find / -xdev -type f -name '*.log' -printf '%TY-%Tm-%Td %TH:%TM  %10s bytes  %p\n' 2>/dev/null | sort"

# 3. File system: permissions, SUID binaries, disk usage
capture file_permissions.txt "Permissions and owners of every lab file" "VM host" \
  bash -c "find '$LAB_DIR' -path '*/.git' -prune -o -printf '%M %u:%g %8s %TY-%Tm-%Td %TH:%TM %p\n'"
capture app_file_permissions.txt "Permissions of application files inside the container" "$APP container" \
  docker exec "$APP" ls -la /app /app/evidence
capture suid_binaries.txt "SUID binaries on the VM" "VM host" \
  bash -c 'sudo find / -xdev -perm -4000 -type f -exec ls -l {} + 2>/dev/null'
capture app_suid_binaries.txt "SUID binaries inside the app container" "$APP container" \
  docker exec "$APP" sh -c 'find / -xdev -perm -4000 -type f -exec ls -l {} + 2>/dev/null'
capture disk_usage.txt "Disk usage of the VM and Docker" "VM host" \
  bash -c 'df -h; echo; docker system df'

# 4. Configuration
capture config_references.txt "Lab version, local changes, and config lines with debug mode, secrets or credentials" "Lab repository" \
  bash -c "cd '$LAB_DIR' && git log -1 --format='Commit %H (%ci)' && echo && git status --short && git diff -- docker-compose.yml vulnerable-app && echo && grep -nE 'debug=True|secret_key|PASSWORD|password' docker-compose.yml vulnerable-app/app.py vulnerable-app/db_init.sql"
capture docker_inspect_app.json "Full Docker configuration of the app container" "Docker engine" \
  docker inspect "$APP"
copy_file "$LAB_DIR/docker-compose.yml"          config/docker-compose.yml   "Lab Docker Compose file"
copy_file "$LAB_DIR/vulnerable-app/app.py"       config/app.py               "Application source code"
copy_file "$LAB_DIR/vulnerable-app/db_init.sql"  config/db_init.sql          "Database initialisation script"
copy_file "$LAB_DIR/vulnerable-app/Dockerfile"   config/app.Dockerfile       "App container build file"
copy_file "$LAB_DIR/elk-stack/logstash.conf"     config/logstash.conf        "Logstash pipeline configuration"

# 5. Hash every evidence file (paths relative to evidence/ so they can be re-checked)
log "Hashing all evidence files (SHA-256 and MD5)"
( cd "$EV" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$CASE_DIR/hashes.txt"
( cd "$EV" && find . -type f -print0 | sort -z | xargs -0 md5sum )    > "$CASE_DIR/hashes_md5.txt"

# 6. Evidence register
echo "Evidence_ID,File,Description,Source,Collected_by,Collected_UTC,Size_bytes,SHA256" > "$REGISTER"
n=0
for out in "${ORDER[@]}"; do
  n=$((n + 1))
  size=$(stat -c %s "$EV/$out")
  sha=$(sha256sum "$EV/$out" | cut -d' ' -f1)
  printf 'EV-%02d,%s,"%s","%s",%s,%s,%s,%s\n' "$n" "$out" "${DESC[$out]}" "${SRC[$out]}" \
    "$INVESTIGATOR" "${WHEN[$out]}" "$size" "$sha" >> "$REGISTER"
done
log "Evidence register written: $n items"

# 7. Seal: make evidence read-only, archive it, hash the archive
chmod -R a-w "$EV"
tar -czf "$CASE_DIR/${CASE_ID}_evidence.tar.gz" -C "$CASE_DIR" evidence
( cd "$CASE_DIR" && sha256sum "${CASE_ID}_evidence.tar.gz" > "${CASE_ID}_evidence.tar.gz.sha256" )
chmod a-w "$CASE_DIR/hashes.txt" "$CASE_DIR/hashes_md5.txt" "$REGISTER"
ARCHIVE_SHA=$(cut -d' ' -f1 "$CASE_DIR/${CASE_ID}_evidence.tar.gz.sha256")
log "Evidence sealed read-only. Archive SHA-256: $ARCHIVE_SHA"

# 8. Chain of custody: first two entries (later entries are added by hand)
cat > "$COC" <<COC
Entry,Date_UTC,Item,Action,From,To,Handled_by,Purpose,Hash_status
1,${WHEN[${ORDER[0]}]},EV-01 to EV-$(printf '%02d' "$n"),Collected,securebank-lab VM and lab containers,$EV,$INVESTIGATOR,Evidence acquisition,SHA-256 and MD5 recorded in hashes.txt
2,$(ts),${CASE_ID}_evidence.tar.gz,Sealed read-only and archived,$EV,$CASE_DIR,$INVESTIGATOR,Preservation,Archive SHA-256 $ARCHIVE_SHA
COC

log "=== Collection finished: $n items. Case folder: $CASE_DIR ==="
