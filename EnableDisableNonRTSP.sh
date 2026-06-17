#!/bin/bash
# ==============================================================================
# Pipeline Telemetry Dynamic Sync & Orchestration Wrapper
# This script handles automated state updates (enabling/disabling ingestion pipelines)
# based on node status changes, then dynamically refreshes runtime engines.
# ==============================================================================

# --- Dynamic Configuration Profiles ---
# Replaced client-specific username loops with clear environment profiles
PROFILE_A="worker-node-01"
PROFILE_B="worker-node-02"

CURRENT_USER=$(whoami)

echo "======================================================================"
echo " Executing MLOps Fleet Status Synchronization..."
echo "======================================================================"

if [[ "$CURRENT_USER" == "$PROFILE_A" ]]; then
    echo "[Info] Applying configuration policies for Profile: ${PROFILE_A}"
    
    BASE_DIR="$HOME/pipeline-prod"
    ENGINE_DIR="$HOME/StreamGenerator"
    APP_DIR="$HOME/app-framework"
    
    # 1. Generate Fail-Safe Configuration Backups
    cp "${BASE_DIR}/config.json" "${BASE_DIR}/config.json.bk" 2>/dev/null
    cp "${BASE_DIR}/config_secondary.json" "${BASE_DIR}/config_secondary.json.bk" 2>/dev/null
        
    # 2. De-allocate pipelines for nodes confirmed offline
    if [[ -f "$HOME/disableTheseCodes.txt" ]]; then
        echo "[Sync] Disabling ingestion routing for disconnected edge devices..."
        for code in $(cat "$HOME/disableTheseCodes.txt")
        do
            # Advanced Multi-Line Sed Token Manipulation Block
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":true/\"utilize\":false/g}" "${BASE_DIR}/config.json"
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":true/\"utilize\":false/g}" "${BASE_DIR}/config_secondary.json"
        done
        rm -f "$HOME/disableTheseCodes.txt"
    fi
    
    # 3. Allocate/Activate pipelines for nodes confirmed operational
    if [[ -f "$HOME/enableTheseCodes.txt" ]]; then
        echo "[Sync] Restoring ingestion routing for operational edge devices..."
        for code in $(cat "$HOME/enableTheseCodes.txt")
        do
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":false/\"utilize\":true/g}" "${BASE_DIR}/config.json"
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":false/\"utilize\":true/g}" "${BASE_DIR}/config_secondary.json"
        done
        rm -f "$HOME/enableTheseCodes.txt"
    fi

    # 4. Gracefully Terminate Legacy Running Stacks
    echo "[Orchestration] Refreshing process dependencies. Recalibrating cluster states..."
    pkill -f tmux
    killall inference-engine-01 2>/dev/null
    killall inference-engine-02 2>/dev/null
    
    # 5. Initialize Decoupled Pipeline Managers via background Multiplexing (tmux)
    echo "[Orchestration] Launching detached stream cluster endpoints..."
    tmux new-session -d -s StreamServer "cd ${ENGINE_DIR}; python3 ./streamserver.py"
    
    # Dynamic ingestion asset fetch processing loop
    for project_node in $(find "$APP_DIR"/*/linux64/proj/sdkTest 2>/dev/null | sed 's/\//\t/g' | awk '{print $4}')
    do 
        tmux new-session -d -s "fetch_${project_node}" "cd ${APP_DIR}/${project_node}/linux64/proj; ./sdkTest"
    done

    # Initialize Primary Application Ingestion Routines
    tmux new-session -d -s core-pipeline-01 "cd ${BASE_DIR}; ./check.sh"
    tmux new-session -d -s core-pipeline-02 "cd ${BASE_DIR}; ./check2.sh"
    echo "[Success] Profile A execution environment refreshed successfully."

elif [[ "$CURRENT_USER" == "$PROFILE_B" ]]; then
    echo "[Info] Applying configuration policies for Profile: ${PROFILE_B}"
    
    BASE_DIR="$HOME/pipeline-prod"
    ENGINE_DIR="$HOME/StreamGenerator"
    APP_DIR="$HOME/app-framework"
    
    # 1. Generate Fail-Safe Configuration Backups
    cp "${BASE_DIR}/config.json" "${BASE_DIR}/config.json.bk" 2>/dev/null
    cp "${BASE_DIR}/config_secondary.json" "${BASE_DIR}/config_secondary.json.bk" 2>/dev/null
        
    # 2. De-allocate pipelines for nodes confirmed offline
    if [[ -f "$HOME/disableTheseCodes.txt" ]]; then
        echo "[Sync] Disabling ingestion routing for disconnected edge devices..."
        for code in $(cat "$HOME/disableTheseCodes.txt")
        do
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":true/\"utilize\":false/g}" "${BASE_DIR}/config.json"
        done
        rm -f "$HOME/disableTheseCodes.txt"
    fi

    # 3. Allocate/Activate pipelines for nodes confirmed operational
    if [[ -f "$HOME/enableTheseCodes.txt" ]]; then
        echo "[Sync] Restoring ingestion routing for operational edge devices..."
        for code in $(cat "$HOME/enableTheseCodes.txt")
        do
            sed -i "/${code}/!b;:a;/url/!{$!{N;ba}};{s/\"utilize\":false/\"utilize\":true/g}" "${BASE_DIR}/config.json"
        done
        rm -f "$HOME/enableTheseCodes.txt"
    fi

    # 4. Gracefully Terminate Legacy Running Stacks
    echo "[Orchestration] Refreshing process dependencies. Recalibrating cluster states..."
    pkill -f tmux
    killall inference-engine-01 2>/dev/null
    
    # 5. Initialize Decoupled Pipeline Managers via background Multiplexing (tmux)
    echo "[Orchestration] Launching detached stream cluster endpoints..."
    tmux new-session -d -s StreamServer "cd ${ENGINE_DIR}; python3 ./streamserver.py"
    
    for project_node in $(find "$APP_DIR"/*/linux64/proj/sdkTest 2>/dev/null | sed 's/\//\t/g' | awk '{print $4}')
    do 
        tmux new-session -d -s "fetch_${project_node}" "cd ${APP_DIR}/${project_node}/linux64/proj; ./sdkTest"
    done

    # Initialize Primary Application Ingestion Routines
    tmux new-session -d -s core-pipeline-01 "cd ${BASE_DIR}; ./check.sh"
    echo "[Success] Profile B execution environment refreshed successfully."

else
    echo "[Error] Access Denied: Unrecognized system execution profile runtime architecture. Terminating."
    exit 1
fi
