# ================================
# LOG MONITOR SCRIPT 
# ================================

# ------------------------
# Validate input arguments
# ------------------------
if [ -z "$1" ]; then
    echo "Error: Please provide a log file path." >&2
    echo "Usage: $0 <log_path> [lines_to_scan] [keywords...]"
    echo "Example: $0 /var/log/app.log 2000 ERROR WARNING FATAL"
    exit 1
fi

LOG_FILE="$1"
LINES_TO_SCAN="${2:-1000}" # Default scan 1000 lines if not provided

# Shift the first two parameters to process optional keywords
shift 2
if [ $# -eq 0 ]; then
    # Default monitored keywords
    KEYWORDS=("ERROR" "WARNING")
else
    # User-defined keywords
    KEYWORDS=("$@")
fi
# Default threshold for triggering a critical alert
ERROR_THRESHOLD=10
REPORT_FILE="log_alert_report.txt"
# ------------------------
# Check if log file is valid and readable
# ------------------------
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' does not exist or is not readable." >&2
    exit 2
fi
# ------------------------
# Extract the last N lines from the log
# ------------------------
echo "Analyzing the last $LINES_TO_SCAN lines of $LOG_FILE..."
LAST_N_LINES=$(tail -n "$LINES_TO_SCAN" "$LOG_FILE" || true)

if [ -z "$LAST_N_LINES" ]; then
    echo "Info: Log file '$LOG_FILE' is empty or cannot read last $LINES_TO_SCAN lines."
    echo "--- LOG ANALYSIS REPORT ---" > "$REPORT_FILE"
    echo "No data to analyze." >> "$REPORT_FILE"
    exit 0
fi

# ------------------------
# Count occurrences of each keyword
# ------------------------
declare -A COUNTS
for KEY in "${KEYWORDS[@]}"; do
    COUNTS[$KEY]=$(echo "$LAST_N_LINES" | grep -c "$KEY")
done

# ------------------------
# Find the most recent log entry containing any keyword
# ------------------------
PATTERN=$(printf "|%s" "${KEYWORDS[@]}")
PATTERN="${PATTERN:1}"  # bỏ ký tự "|" đầu
RECENT_ENTRY=$(echo "$LAST_N_LINES" | grep -E "$PATTERN" | tail -n 1)

if [ -n "$RECENT_ENTRY" ]; then
    # Extract a timestamp-like pattern from the line (first two fields)
    RECENT_TIMESTAMP=$(echo "$RECENT_ENTRY" | awk '{print $1 " " $2}')
else
    RECENT_TIMESTAMP="No matching keyword found"
fi

# ------------------------
# Generate report file
# ------------------------
{
    echo "--- LOG ANALYSIS REPORT ---"
    echo "Report generated: $(date)"
    echo "Log file:         $LOG_FILE"
    echo "Lines scanned:    $LINES_TO_SCAN"
    echo "-----------------------------------"
    for KEY in "${KEYWORDS[@]}"; do
        echo "Count of $KEY: ${COUNTS[$KEY]}"
    done
    echo "Most recent timestamp: $RECENT_TIMESTAMP"
    echo "-----------------------------------"
} > "$REPORT_FILE"

# ------------------------
# Check ERROR threshold for critical alert
# ------------------------
CRITICAL_ALERT_TRIGGERED=false
if [ "${COUNTS[ERROR]:-0}" -gt "$ERROR_THRESHOLD" ]; then
    ALERT_MSG="CRITICAL ALERT: ${COUNTS[ERROR]} ERROR entries found (threshold: $ERROR_THRESHOLD)"
    echo "$ALERT_MSG"
    echo "$ALERT_MSG" >> "$REPORT_FILE"
    CRITICAL_ALERT_TRIGGERED=true
else
    echo "ERROR count (${COUNTS[ERROR]:-0}) is within threshold (<= $ERROR_THRESHOLD)."
    echo "Status: OK" >> "$REPORT_FILE"
fi
# ------------------------
# Final output and exit status
# ------------------------
echo "Analysis complete. Report saved to: $REPORT_FILE"

if [ "$CRITICAL_ALERT_TRIGGERED" = true ]; then
    exit 1
fi

exit 0
