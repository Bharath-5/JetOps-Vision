#!/bin/bash
# ==============================================================================
# Edge Video Extraction & Validation Utility
# This script extracts diagnostic clips from edge camera configurations via RTSP 
# streams using ffmpeg to validate pipeline routing during deployment.
# ==============================================================================

# Variables expected to be injected or dynamic
SITE_ID="sitenumber"            # Replaced dynamically by orchestrator script
RTSP_USER="rtsp_username"        # Replaced dynamically by orchestrator script
RTSP_PASS="rtsp_password"        # Replaced dynamically by orchestrator script
HOST_USER="host_username"        # Replaced dynamically by orchestrator script
HOST_IP="host_IP"                # Replaced dynamically by orchestrator script
HOST_PASS="host_password"        # Replaced dynamically by orchestrator script
SUDO_PASS="DevicePassword"       # Replaced dynamically by orchestrator script

# Ensure dependency utilities are installed securely
if ! command -v sshpass &> /dev/null; then
   echo "Installing system dependencies..."
   echo "${SUDO_PASS}" | sudo -S apt-get update -y && \
   echo "${SUDO_PASS}" | sudo -S apt-get install -y sshpass
fi

# Determine base gateway/subnet context dynamically
# Tries to match an active interface address and safely falls back if necessary
BASE_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
if [ -z "$BASE_IP" ]; then
    BASE_IP=$(hostname -I | awk '{print $1}')
fi

# Extract the network segment prefix (e.g., 192.168.1.)
IP_PREFIX=$(echo "$BASE_IP" | awk -F. '{print $1"."$2"."$3"."}')

# Loop through potential processing engine host IPs (Indices 10, 20, 30, 40)
for i in {1..4}
do
    # Constructing Target Camera Server Network Subnet Group
    DVR_IP="${IP_PREFIX}${i}0"
    
    # Iterate through target camera stream processing channels
    for j in {1..8}
    do
        echo "Testing Stream Pipeline: DVR ${DVR_IP} | Channel ${j}"
        
        # Pull down a short 15-second frame sample using optimized hardware copy codecs
        ffmpeg -t 00:00:15 \
               -i "rtsp://${RTSP_USER}:${RTSP_PASS}@${DVR_IP}:554/streaming/channels/0${j}01" \
               -b 900k -vcodec copy -r 60 -y "${SITE_ID}_${i}_${j}.mp4" 2> temp.txt 
        
        # Append diagnostic tracking logs
        echo "-------------------------------- Cam ${i} Channel ${j} ---------------------------------------" >> "${SITE_ID}_fps.txt"
        cat ./temp.txt >> "${SITE_ID}_fps.txt"
    done
done

# Clear stale host keys to guarantee stable loopback execution shifts
if [ -n "$HOST_IP" ]; then
    ssh-keygen -f "/home/$(whoami)/.ssh/known_hosts" -R "${HOST_IP}" 2>/dev/null
fi

# Securely upload diagnostic telemetry back to destination engineering node
echo "Shipping telemetry payload data back to host gateway..."
sshpass -p "${HOST_PASS}" scp -o StrictHostKeyChecking=no "${SITE_ID}_fps.txt" "${HOST_USER}@${HOST_IP}:"
sshpass -p "${HOST_PASS}" scp -o StrictHostKeyChecking=no "${SITE_ID}_"*.mp4 "${HOST_USER}@${HOST_IP}:"

# Cleanup local temporary files
rm -f temp.txt "${SITE_ID}_fps.txt" "${SITE_ID}_"*.mp4
