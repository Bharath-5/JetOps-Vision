#!/bin/bash
# ==============================================================================
# Retrospective Ingestion Data Extraction Utility
# Extracts a precise slice of historical video archive footage from a target 
# camera server via time-parameterized RTSP streams, shipping it to a host node.
# ==============================================================================

# Target Tokens (Injected dynamically by top-level orchestration scripts)
TARGET_CAMERA="SelectedCamName"
RETRIEVAL_DURATION="Duration_Min"
START_TIMESTAMP="YYYYMMDDTHHMMSSz" # Expected format: YYYYMMDDTHHMMSSz (e.g. 20260617T120000z)
SITE_ID="sitenumber"

HOST_USER="host_username"
HOST_IP="host_IP"
HOST_PASS="host_password"

echo "======================================================================"
echo " Launching Historical Stream Retrieval Pipeline                       "
echo "======================================================================"

# 1. Verify and Install Secure Shell Copy Dependencies
if ! command -v sshpass &> /dev/null; then
   echo "[Setup] Fetching secure runtime dependencies (sshpass)..."
   sudo apt-get update -y && sudo apt-get install -y sshpass
fi

# 2. Resilient JSON Extraction Engine
# Replaced brittle head-8 pipe limits with a robust paragraph matching pattern block.
# This finds the exact camera block first, then safely extracts its specific URL.
if [ -f "iris.json" ]; then
    echo "[Engine] Extracting stream source coordinates for: ${TARGET_CAMERA}..."
    
    RAW_URL=$(awk -v cam="${TARGET_CAMERA}" '
        $0 ~ cam {in_block=1} 
        in_block && /"url"/ {print $0; exit}
    ' iris.json | awk -F '"' '{print $4}')
    
    # Modernize stream track queries to match open source configuration layouts safely
    # If your pipeline expects a route change modification hook:
    BASE_STREAM_URL=$(echo "${RAW_URL}" | sed "s/channels/tracks/g")
else
    echo "[Error] Primary configuration matrix 'iris.json' missing from workspace. Aborting."
    exit 1
fi

if [ -z "$BASE_STREAM_URL" ]; then
    echo "[Error] Unable to resolve valid stream source string matching identifier: ${TARGET_CAMERA}"
    exit 1
fi

# 3. Formulate Parameterized RTSP Timeline Query
# Concatenates standard network surveillance protocols to access back-logged frames
QUERY_STREAM_URL="${BASE_STREAM_URL}?starttime=${START_TIMESTAMP}"
OUTPUT_FILE="${SITE_ID}_historical_retrospective.mp4"

echo "[Engine] Initiating retrospective stream compilation pipeline..."
echo "[Engine] Extracting data window: ${RETRIEVAL_DURATION} minutes."

# Execute stream copy using optimized container queues to prevent dropframes over volatile connections
ffmpeg -t "00:${RETRIEVAL_DURATION}:00" \
       -i "${QUERY_STREAM_URL}" \
       -b 900k \
       -max_muxing_queue_size 9999 \
       -vcodec copy \
       -r 60 \
       -y "${OUTPUT_FILE}" 2> ffmpeg_extraction_log.txt

# 4. Flush Stale Cryptographic Keys to Clear Connection Sockets
if [[ -n "$HOST_IP" && "$HOST_IP" != "host_IP" ]]; then
    echo "[Security] Resetting host validation keys..."
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${HOST_IP}" &>/dev/null
fi

# 5. Securely Export Processed Payload Back to Engineering Server Context
if [ -f "${OUTPUT_FILE}" ]; then
    echo "[Transport] Shipping archive payload back to host interface gateway..."
    sshpass -p "${HOST_PASS}" scp -o StrictHostKeyChecking=no "${OUTPUT_FILE}" "${HOST_USER}@${HOST_IP}:"
    
    # Clean up localized temporary storage foot-prints from edge device
    rm -f "${OUTPUT_FILE}" ffmpeg_extraction_log.txt
    echo "[Success] Retrospective compilation lifecycle completed successfully."
else
    echo "[Error] Extraction pipeline completed but failed to render media container output."
    exit 1
fi
