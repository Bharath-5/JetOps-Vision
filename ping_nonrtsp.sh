#!/bin/bash
# ==============================================================================
# Multi-Tenant Edge Gateway Reachability Check & Discovery Utility
# Remotely inspects network repositories, parses C++ properties via regex 
# to extract target network addresses, and executes fping telemetry validation.
# ==============================================================================

# --- Operational Node Definitions (Overridable Environment Variables) ---
SERVER_NODE_A="${GATEWAY_NODE_A_IP:-"10.0.1.20"}"
SERVER_NODE_B="${GATEWAY_NODE_B_IP:-"10.0.1.30"}"

PASS_NODE_A="${GATEWAY_NODE_A_PASS:-"secure_hash_a"}"
PASS_NODE_B="${GATEWAY_NODE_B_PASS:-"secure_hash_b"}"

USER_NODE_A="${GATEWAY_NODE_A_USER:-"node-worker-01"}"
USER_NODE_B="${GATEWAY_NODE_B_USER:-"node-worker-02"}"

APP_ROOT_DIR="$HOME/app-framework"

echo "======================================================================"
echo " Launching Fleet Connection Diagnostics Validation Suite              "
echo "======================================================================"

# Preview connectivity availability across cluster managers
sshpass -p "${PASS_NODE_A}" ssh "${USER_NODE_A}@${SERVER_NODE_A}" "ls ${APP_ROOT_DIR}" &>/dev/null
sshpass -p "${PASS_NODE_B}" ssh "${USER_NODE_B}@${SERVER_NODE_B}" "ls ${APP_ROOT_DIR}" &>/dev/null

# Read array input parameters securely
read -r -p "Enter Target Site Identifiers to check for IP routing status (space-separated): " -a target_sites
echo "Initializing Validation Sequence for Targets: ${target_sites[*]}"
echo "----------------------------------------------------------------------"

declare -a ip_addresses_array

for site in "${target_sites[@]}"
do
    # Verify if target workspace profile directory exists on Server Node A
    sshpass -p "${PASS_NODE_A}" ssh "${USER_NODE_A}@${SERVER_NODE_A}" "cd ${APP_ROOT_DIR}/${site} &>/dev/null"
    
    if [ $? -eq 0 ]; then
        echo "[Discovery] Querying metadata profile on Profile Node A for Site: ${site}"
        # Parse connection matrix coordinates dynamically out of C++ configuration schemas
        parsed_ip=$(sshpass -p "${PASS_NODE_A}" ssh "${USER_NODE_A}@${SERVER_NODE_A}" \
            "cat ${APP_ROOT_DIR}/${site}/src/consoleMain.cpp 2>/dev/null | grep -w -E 'sDeviceAddress|sUserName|sPassword' | awk -F ',' 'NR==1{print \$2}' | tr -d ' \"'" \
            | awk -F ',' '{print $2}')
    else
        echo "[Discovery] Node A miss. Routing query to Profile Node B for Site: ${site}"
        parsed_ip=$(sshpass -p "${PASS_NODE_B}" ssh "${USER_NODE_B}@${SERVER_NODE_B}" \
            "cat ${APP_ROOT_DIR}/${site}/src/consoleMain.cpp 2>/dev/null | grep -w -E 'sDeviceAddress|sUserName|sPassword' | awk -F ',' 'NR==1{print \$2}' | tr -d ' \"'" \
            | awk -F ',' '{print $2}')
    fi

    # Append valid structural discoveries onto telemetry processing stack arrays
    if [ -n "$parsed_ip" ]; then
        ip_addresses_array+=("$parsed_ip")
    else
        echo "[Warning] Connection parameters unresolvable for target identifier: ${site}"
        ip_addresses_array+=("unresolvable")
    fi
done

echo "----------------------------------------------------------------------"
echo " Discovered Public Interface Network Mappings: [ ${ip_addresses_array[*]} ]"
echo "----------------------------------------------------------------------"

site_index_counter=0

for target_ip in "${ip_addresses_array[@]}"
do
    current_site_tag="${target_sites[$site_index_counter]}"
    
    if [[ "$target_ip" == "unresolvable" ]]; then
        echo "🚨 [Status] Site: ${current_site_tag} Cluster Interface is UNREACHABLE (Missing Schema Link)"
        ((site_index_counter++))
        continue
    fi

    # Execute precise validation test over the active node gateway
    # BUG FIX: Resolved nesting quote collisions to cleanly grab remote process terminal exit boundaries ($?)
    sshpass -p "${PASS_NODE_A}" ssh "${USER_NODE_A}@${SERVER_NODE_A}" "fping -c1 -t1100 ${target_ip} &>/dev/null"
    icmp_exit_state=$?

    if [ $icmp_exit_state -eq 0 ]; then
        echo "🟢 [Status] Site: ${current_site_tag} Processing Target IP [${target_ip}] is UP / OPERATIONAL"
    else
        echo "🔴 [Status] Site: ${current_site_tag} Processing Target IP [${target_ip}] is DOWN / OFFLINE"
    fi
    
    ((site_index_counter++))
done

echo "----------------------------------------------------------------------"
echo " Network Verification Sequence Completed."
