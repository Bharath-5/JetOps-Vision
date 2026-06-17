#!/bin/bash
# ==============================================================================
# Edge Inference Configuration Compiler & Pipeline Migrator
# Parses dynamic channel changes from active run-states, rebuilds the baseline
# application JSON schemas, and provisions downstream execution routines.
# ==============================================================================

# Target Variables (Injected via Environment or standard deployment configurations)
ACTIVE_PIPELINES=0
SUDO_PASS="DevPass"
EXPECTED_VERSION="ExpVerNum"

# Ensure runtime targets exist securely before executing configuration changes
if [ ! -f "iris.json" ] || [ ! -f "reference.json" ]; then
    echo "[Error] Missing vital system config templates ('iris.json' or 'reference.json')."
    exit 1
fi

echo "======================================================================"
echo " Launching Configuration Schema Refactoring Engine                   "
echo "======================================================================"

# 1. Archive current active deployment metrics configuration
mv iris.json iris.json.bk

# --- Block Parsing Function ---
# Modernizing code style to eliminate redundant chunk copy-pasting loops
parse_and_inject_channel() {
    local block_pattern="$1"    # e.g., "Secured_Antechamber"
    local name_token="$2"       # e.g., "Antechamber_Alpha"
    local util_token="$3"       # e.g., "ante_util"
    local url_token="$4"        # e.g., "ante_url"
    local drop_token="$5"       # e.g., "ante_drp_no"

    # Extract JSON boundary blocks cleanly using awk target groups
    awk "/${block_pattern}/,/drop_frames_interval/" iris.json.bk > tmp.txt 2>/dev/null
    
    if [ ! -s tmp.txt ]; then
        echo "[Warning] Target schema slice block [${block_pattern}] missing in active configuration context."
        return
    fi

    # Extract dynamic properties securely using precise regex text extraction
    local parsed_name=$(grep '"name"' tmp.txt | awk -F '"' '{print $4}')
    local parsed_util=$(grep '"utilize"' tmp.txt | awk -F ':' '{print $2}' | tr -d ' ,')
    local parsed_url=$(grep '"url"' tmp.txt | awk -F '"' '{print $4}')
    local parsed_interval=$(grep '"drop_frames_interval"' tmp.txt | awk -F ':' '{print $2}' | tr -d ' ,')
    local parsed_drop_enabled=$(grep '"drop_frames"' tmp.txt | awk -F ':' '{print $2}' | tr -d ' ,')

    # Update template values inside master reference configuration
    if [ -n "$parsed_name" ];     then sed -i "s|${name_token}|${parsed_name}|g" reference.json; fi
    if [ -n "$parsed_util" ];     then sed -i "s|${util_token}|${parsed_util}|g" reference.json; fi
    if [ -n "$parsed_url" ];      then sed -i "s|${url_token}|${parsed_url}|g" reference.json; fi
    if [ -n "$parsed_interval" ]; then sed -i "s|${drop_token}|${parsed_interval}|g" reference.json; fi

    # Increment active camera fleet counts if dropping frames is actively enabled
    if [[ "$parsed_drop_enabled" == *"true"* ]]; then
        ((ACTIVE_PIPELINES++))
    fi
    
    rm -f tmp.txt
}

# 2. Sequential Processing of Core Ingestion Pipelines
# Map old localized names to generalized, elite enterprise pipeline tokens
parse_and_inject_channel "Infront" "xxxx_Secured_Antechamber_Alpha" "if_str_util" "if_str_rm" "if_drp_no"
parse_and_inject_channel "Banking" "xxxx_Primary_Zone_Alpha" "bnk_util" "bnk_hl" "bnk_drp_no"
parse_and_inject_channel "Inside"  "xxxx_Secured_Vault_Internal" "in_str_util" "in_str_rm" "in_drp_no"
parse_and_inject_channel "Outside" "xxxx_External_Perimeter_Entrance" "out_entr_util" "out_entr_cam" "out_drp_no"

# 3. Refactor Global DeepStream Muxer Dimension Envelopes
awk '/streammux/,/height/' iris.json.bk > tmp.txt 2>/dev/null
if [ -s tmp.txt ]; then
    mux_width=$(grep '"width"' tmp.txt | awk -F ':' '{print $2}' | tr -d ' ,')
    mux_height=$(grep '"height"' tmp.txt | awk -F ':' '{print $2}' | tr -d ' ,')
    
    if [ -n "$mux_width" ];  then sed -i "s/streammux_width/${mux_width}/g" reference.json; fi
    if [ -n "$mux_height" ]; then sed -i "s/streammux_height/${mux_height}/g" reference.json; fi
fi
rm -f tmp.txt

# 4. Bind Cloud Asset Identification Hashes Securely
site_id_hash=$(grep '"site_id"' iris.json.bk | head -n 1 | awk -F '"' '{print $4}')
asset_id_hash=$(grep '"asset_id"' iris.json.bk | head -n 1 | awk -F '"' '{print $4}')

if [ -n "$site_id_hash" ];  then sed -i "s/ssss/${site_id_hash}/g" reference.json; fi
if [ -n "$asset_id_hash" ]; then sed -i "s/aaaa/${asset_id_hash}/g" reference.json; fi

# 5. Lock-in Schema updates and compile target Deployment Configurations
mv reference.json iris.json

if [ -f "RTSP_Deploy.sh" ]; then
    sed -i "s/ExpectedVersionNumber/${EXPECTED_VERSION}/g" RTSP_Deploy.sh
    sed -i "s/DevicePassword/${SUDO_PASS}/g" RTSP_Deploy.sh
    
    # Genericized comment placeholder implementation block for channel adjustments
    sed -i '/FourthPipelineChannel/ s/^/\/\//' RTSP_Deploy.sh 2>/dev/null
    
    echo "[Success] Deployment payload compiled. Initializing container stack..."
    chmod +x RTSP_Deploy.sh
    ./RTSP_Deploy.sh
else
    echo "[Error] Tail downstream container script 'RTSP_Deploy.sh' missing. Aborting."
    exit 1
fi
