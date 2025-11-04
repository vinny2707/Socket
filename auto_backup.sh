# --- ARGUMENT VALIDATION ---
# Check for correct number of arguments (3 mandatory, 1 optional).
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <source_dir> <backup_dir> <max_backups> [optional_exclude_file]"
    exit 1
fi
# --- VARIABLE ASSIGNMENT ---
# Assign arguments to variables for readability
SOURCE_DIR=$1
BACKUP_DIR=$2
MAX_BACKUP=$3
EXCLUDE_FILE=$4

# ---GET LOG FILE DIRECTORY---
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
LOG_FILE="$USER_HOME/backup.log"
# --- BACKUP FILENAME ---
# Generate a timestamp for the backup file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
# Create a unique backup filename
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
# Define the full path for the new backup file
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
# --- LOG FUNCTION ---
# Define a function for logging messages
log(){
	# Try to create the log file if it doesn't exist, suppressing errors
	touch "$LOG_FILE" 2>/dev/null
	# Check if log file is writable
	if [ $? -ne 0 ]; then
		echo "ERROR: Can write in file log $LOG_FILE. Check Permission." >&2
	fi
	# Append the timestamped message to the log file
	echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}
# --- PRE-RUN CHECKS ---
# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
	echo "ERROR: Source dir not found!" >&2
	log "FAIL: Source dir not found: $SOURCE_DIR"
	exit 1
fi
# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
	echo "ERROR: Backup dir not found!" >&2
	log "FAIL: Backup dir not found: $BACKUP_DIR"
	exit 1
fi
# Check if we have write permissions in the backup directory
if [ ! -w "$BACKUP_DIR" ]; then
	echo "ERROR: Write Permission Denied!" >&2
	log "FAIL: Write Permission Denied: $BACKUP_DIR"
	exit 1
fi
# --- START BACKUP PROCESS ---
echo "START: Backup from $SOURCE_DIR to $BACKUP_FILE"
log "START:  Backup from $SOURCE_DIR  to $BACKUP_FILE"

START_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
log "StartTime: $START_TIME"
# ===================== BUILD EXCLUDE OPTIONS =====================
EXCLUDE_OPT=""
# Check if the 4th argument (exclude file) was provided
if [ -n "$EXCLUDE_FILE" ]; then
	# Check if the provided file actually exists
    if [ -f "$EXCLUDE_FILE" ]; then 
        echo "Using exclude list from: $EXCLUDE_FILE"
        log "INFO: Using exclude list from: $EXCLUDE_FILE"
		# Set the tar option for excluding files
        EXCLUDE_OPT="--exclude-from=$EXCLUDE_FILE"
    else
		# Warn the user if the file is missing
        echo "WARNING: Exclude file '$EXCLUDE_FILE' not found! Backing up WITHOUT excludes." >&2
        log "WARNING: Exclude file '$EXCLUDE_FILE' not found. Backing up without excludes."
    fi
fi
# ===================== BACKUP =====================
# Create the compressed archive
# -c: create archive
# -z: compress with gzip
# -f: specify output file
# $EXCLUDE_OPT: add exclude options
# -C: change directory to $SOURCE_DIR before archiving
# .: archive all content in that directory
tar -czf "$BACKUP_FILE" $EXCLUDE_OPT -C "$SOURCE_DIR" .
# --- POST-BACKUP CHECK ---
# Check the exit code of the tar command
if [ $? -eq 0 ]; then
	# Success
	END_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
	echo "Backup successful: $BACKUP_NAME"
	log "SUCCESS: Backup Completion."
	log "INFO: Backup file name: $BACKUP_NAME"
	log "EndTime: $END_TIME"
else
	# Failure
	END_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
	echo "ERROR: Compression failure." >&2
	log "FAIL: Compression failure with $BACKUP_NAME."
	log "EndTime: $END_TIME"
	exit 1
fi
#===================== MANAGE OLD BACKUPS =====================
echo "Check number of backups."
# Count the total number of backups
BACKUPS_COUNT=$(ls -1q "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)
# Check if the count exceeds the maximum allowed
if [ "$BACKUPS_COUNT" -gt "$MAX_BACKUP" ]; then
	# Calculate how many backups to delete
	DELETE_COUNT=$((BACKUPS_COUNT - MAX_BACKUP))
	# List backups by time (ls -1t), get all *except* the newest $MAX_BACKUP (tail)
	BACKUP_DELETE=$(ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "+$((MAX_BACKUP + 1))")
	if [ -n "$BACKUP_DELETE" ]; then
		echo "Delete $DELETE_COUNT backups."
		# Show which files will be deleted
		echo "$BACKUP_DELETE"
		# Pipe the list of files to xargs to delete them
		echo "$BACKUP_DELETE" | xargs -I {} rm -f {}
		# Log the deletion
		if [ $? -eq 0 ]; then
			log "NOTIFICATION: Deleted $DELETE_COUNT old backup."
		else
			log "WARNING: Failure to delete old backup."
		fi
	fi
else
	echo "Do not have to delete backup"
fi
# --- END OF SCRIPT ---
log "END: Backup Completion"
echo "END: Finish Process"
exit 0
