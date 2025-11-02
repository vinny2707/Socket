# Log File Directory
if [ $# -ne 3 ]; then
	echo "Usage: $0 <source_dir> <backup_dir> <max_backups>"
	exit 1
fi

SOURCE_DIR=$1
BACKUP_DIR=$2
MAX_BACKUP=$3

LOG_FILE="/home/vinny/backup.log"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"

BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"

log(){
	touch "$LOG_FILE" 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "ERROR: Can write in file log $LOG_FILE. Check Permission." >&2
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

if [ ! -d "$SOURCE_DIR" ]; then
	echo "ERROR: Source dir not found!" >&2
	log "FAIL: Source dir noit found: $SOURCE_DIR"
	exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
	echo "ERROR: Backup dir not found!" >&2
	log "FAIL: Backup dir not found: $BACKUP_DIR"
	exit 1
fi
if [ ! -w "$BACKUP_DIR" ]; then
	echo "ERROR: Write Permission Denied!" >&2
	log "FAIL: Write Permission Denied: $BACKUP_DIR"
	exit 1
fi

echo "START: Backup from $SOURCE_DIR to $BACKUP_FILE"
log "START:  Backup from $SOURCE_DIR  to $BACKUP_FILE"
START_TIME=$(date +%s)
tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

if [ $? -eq 0 ]; then
	END_TIME=$(date +%s)
	ELAPSED=$((END_TIME - START_TIME))
	echo "Backup successful: $BACKUP_FILE"
	log "SUCCESS: Backup Completion $BACKUP_NAME. TIME: $ELAPSED s."
else
	END_TIME=$(date +%s)
	ELAPSED=$((END_TIME - START_TIME))
	echo "ERROR: Compression failure." >&2
	log "FAIL: Compression failure with $BACKUP_NAME. TIME: $ELAPSED s."
fi
echo "Check number of backups."
BACKUPS_COUNT=$(ls -1q "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUPS_COUNT" -gt "$MAX_BACKUP" ]; then
	DELETE_COUNT=$((BACKUPS_COUNT - MAX_BACKUP))
	BACKUP_DELETE=$(ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "+$((MAX_BACKUP + 1))")
	if [ -n "$BAC KUP_DELETE" ]; then
		echo "Delete $DELETE_COUNT backups."
		echo "$BACKUP_DELETE"

		echo "$BACKUP_DELETE" | xargs -I {} rm -f {}

		if [ $? -eq 0]; then
			log "INFO: Deleted $DELETE_COUNT old backup."
		else
			log "WARNING: Failure to delete old backup."
		fi
	fi
else
	echo "Do not have to delete backup"
fi

log "FINISH: Backup Completion"
echo "Finish Process"
exit 0

