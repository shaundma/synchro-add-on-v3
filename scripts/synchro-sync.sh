#!/bin/bash
# Synchro Add-on Sync Script
# Variables will be replaced by sed during installation

DESTINATION_FOLDER='__SYNC_FOLDER__'
DESTINATION_OWNER='__LOCAL_OWNER__'
SOURCE_FOLDER='__REMOTE_SYNC_FOLDER__'
KEEP_EXISTING='__KEEP_EXISTING__'
REMOTE_IP='__REMOTE_IP__'
REMOTE_USER='__REMOTE_USER__'
SSH_KEY='/root/.ssh/id_synchro'
LOG_FILE='/var/log/synchro-addon.log'

# Ensure log directory exists
mkdir -p $(dirname $LOG_FILE)

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "Starting sync: Source=$REMOTE_IP:$SOURCE_FOLDER -> Destination=$DESTINATION_FOLDER, KeepExisting=$KEEP_EXISTING"

# Build rsync options
RSYNC_OPTS="-avz --no-owner --no-group"

# Add --delete flag if we should NOT keep existing files
if [ "$KEEP_EXISTING" != "true" ]; then
  RSYNC_OPTS="$RSYNC_OPTS --delete"
  log "Using --delete flag (will remove files in destination not present in source)"
else
  log "Keeping existing files (--delete flag not used)"
fi

# Perform sync FROM source (remote) TO destination (local)
rsync $RSYNC_OPTS -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" "$REMOTE_USER@$REMOTE_IP:$SOURCE_FOLDER/" "$DESTINATION_FOLDER/" >> $LOG_FILE 2>&1

SYNC_RESULT=$?

if [ $SYNC_RESULT -eq 0 ]; then
  log "Sync completed successfully"

  # Change ownership if DESTINATION_OWNER is set
  if [ -n "$DESTINATION_OWNER" ]; then
    log "Changing ownership of $DESTINATION_FOLDER to $DESTINATION_OWNER"
    chown -R "$DESTINATION_OWNER:$DESTINATION_OWNER" "$DESTINATION_FOLDER" >> $LOG_FILE 2>&1
    CHOWN_RESULT=$?
    if [ $CHOWN_RESULT -eq 0 ]; then
      log "Ownership changed successfully"
    else
      log "Failed to change ownership (exit code $CHOWN_RESULT)"
    fi
  fi
else
  log "Sync failed with exit code $SYNC_RESULT"
fi

exit $SYNC_RESULT
