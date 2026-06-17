#!/bin/bash
# ==============================================================================
# Database Cluster Validation & Node Enumeration Loop
# This script iterates through all configured cluster database entries to 
# pull down connection schemas for network validation testing.
# ==============================================================================

# Initialize loop tracker safely using standard Bash integer definitions
node_counter=1

# Check if the database directory contains entries before running the loop
if [ ! -d "./DB" ] || [ -z "$(ls -A ./DB/ 2>/dev/null)" ]; then
    echo "[Warning] Database directory './DB' is missing or empty. Please initialize mock data files."
    exit 1
fi

echo "Scanning active edge node connection profiles..."
echo "----------------------------------------------------------------------"

# Loop through every credential string (<username>@<ip>) found in Column 2 of the cluster database
for node_connection in $(cat DB/* 2>/dev/null | awk '{print $2}')
do 
    # Dynamically extract the specific user and IP address for the current row
    node_username=$(echo "${node_connection}" | awk -F "@" '{print $1}')
    node_ip=$(echo "${node_connection}" | awk -F "@" '{print $2}')
    
    # Skip iteration if data row parsing is blank or malformed
    if [[ -z "$node_username" || -z "$node_ip" ]]; then
        continue
    fi

    # Output metrics clearly to console terminal
    echo "Node Index:   #${node_counter}"
    echo "Target User:  ${node_username}"
    echo "Target Host:  ${node_ip}"
    echo "----------------------------------------------------------------------"
    
    # Correct Bash Arithmetic Increment Operation
    ((node_counter++))
done

echo "Node enumeration complete. Total target endpoints mapped: $((node_counter - 1))"
