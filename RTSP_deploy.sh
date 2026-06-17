#!/bin/bash
# ==============================================================================
# Edge Hardware Device Deployment & Orchestration Runner
# Resolves X11 EGL virtualization headers, verifies inbound camera paths,
# compiles deployment schemas, and provisions updated container engines.
# ==============================================================================

# System/Registry Configurations (Abstracted Defaults)
REGISTRY_URL="registry.yourdomain.com:5000"
IMAGE_NAME="edge-vision-app"
CONTAINER_NAME="EDGE_VISION_CONTAINER"

echo "======================================================================"
echo " Starting Edge Deployment & Maintenance Automation Suite             "
echo "======================================================================"

# 1. Resolve X11 Environment Boundaries for DeepStream Hardware EGL Rendering
XAUTH_FILE="$HOME/.Xauthority"

if [ ! -e "$XAUTH_FILE" ] ; then
   echo "[X11] .Xauthority template missing. Provisioning security authorization matrix..."
   touch "$XAUTH_FILE"
   export DISPLAY=:0
   
   # AUTOMATION UPGRADE: Automatically capture the GDM magic cookie token string
   GDM_AUTH_PATH="/run/user/1000/gdm/Xauthority"
   if [ -f "$GDM_AUTH_PATH" ]; then
       Disp_Str=$(xauth -f "$GDM_AUTH_PATH" list | awk '{print $3}' | uniq | head -n 1)
       if [ -n "$Disp_Str" ]; then
           xauth add "$DISPLAY" MIT-MAGIC-COOKIE-1 "${Disp_Str}"
           xhost +local:root &>/dev/null
           echo "[X11] Magic cookie authentication bounds successfully provisioned."
       else
           echo "[X11 Warning] Failed to parse authorization string from GDM server context."
       fi
   fi
else
   echo "[X11] Existing .Xauthority file detected. Verification bypassed."
fi

# 2. Gather Node Deployment Descriptors
echo "Enter the unique Site Registry Number:"
read -r sitenumber

echo "Enter target IP address of Processing Server / DVR:"
read -r dvr_ip

echo "Enter username credential for camera network:"
read -r rtsp_username

echo "Enter password credential for camera network (Use %40 for '@' symbols):"
read -r rtsp_password

echo "----------------------------------------------------------------------"
echo " Initializing Multi-Channel Video Ingestion Verification Trials...     "
echo "----------------------------------------------------------------------"

# Run non-blocking pipeline validation checks over all active streaming indices
for i in {1..8} 
do
    echo "[Testing Pipeline Channel #${i}] Capturing diagnostics..."
    ffmpeg -t 00:00:15 \
           -i "rtsp://${rtsp_username}:${rtsp_password}@${dvr_ip}:554/streaming/channels/0${i}01" \
           -b 900k -vcodec copy -r 60 -y "${sitenumber}_${i}.mp4" 2> temp.txt 
           
    echo "-------------------------------- Pipeline Index Cam ${i} ---------------------------------------" >> "${sitenumber}_fps.txt"
    grep fps ./temp.txt >> "${sitenumber}_fps.txt" 2>/dev/null
done
rm -f temp.txt

# 3. Securely Dispatch Ingestion Diagnostics Back to Central Validation Host
echo "----------------------------------------------------------------------"
echo " Transporting Validation Payloads Back to Host System...             "
echo "----------------------------------------------------------------------"
echo "Enter Engineering Host username:"
read -r host_username
echo "Enter Engineering Host deployment IP:"
read -r host_IP

scp "${sitenumber}_fps.txt" "${host_username}@${host_IP}:"
scp ./"${sitenumber}"_*.mp4 "${host_username}@${host_IP}:"
rm -f "${sitenumber}_fps.txt" ./"${sitenumber}"_*.mp4

echo "[Success] Diagnostic artifacts uploaded to target engineering interface."

# 4. Generate Local Deployment Configurations via Baseline References
cp reference.json generated.json

echo "[Config] Compiling configuration tokens..."
sed -i "s|xxxx|${sitenumber}|g" generated.json

echo "Enter Unique Environment Site_ID String (app_settings.site_id):"
read -r siteid 
sed -i "s|ssss|${siteid}|g" generated.json

echo "Enter Unique Compute Node Asset_ID String (app_settings.asset_id):"
read -r assetID
sed -i "s|aaaa|${assetID}|g" generated.json

sed -i "s|rtsp_user_name|${rtsp_username}|g" generated.json
sed -i "s|rtsp_password|${rtsp_password}|g" generated.json
sed -i "s|rtsp_ip_addr|${dvr_ip}|g" generated.json

# Standardized generic loop layout for mapping configuration zones via template engines
for zone in "Secured_Antechamber_Alpha" "Primary_Zone_Alpha" "Secured_Vault_Internal" "External_Perimeter_Entrance"
do
    # Establish dynamic translation tokens matching key sed parameters
    case "$zone" in
        "Secured_Antechamber_Alpha")   ch_tok="if_str_rm";  drp_tok="if_drp_no";  util_tok="if_str_util" ;;
        "Primary_Zone_Alpha")          ch_tok="bnk_hl";     drp_tok="bnk_drp_no"; util_tok="bnk_util" ;;
        "Secured_Vault_Internal")      ch_tok="in_str_rm";  drp_tok="in_drp_no";  util_tok="in_str_util" ;;
        "External_Perimeter_Entrance") ch_tok="out_entr_cam"; drp_tok="out_drp_no"; util_tok="out_entr_util" ;;
    esac

    echo "Enter 4-digit camera channel assignment for Target Zone [${zone}]:"
    read -r ch
    sed -i "s|${ch_tok}|${ch}|g" generated.json
    
    echo "Enter frame drop configuration threshold (0-5):"
    read -r dr
    sed -i "s|${drp_tok}|${dr}|g" generated.json
    
    echo "Enable inference tracking operations on this channel? (y/n):"
    read -r toggle
    if [[ "$toggle" == "y" ]]; then
        sed -i "s|${util_tok}|true|g" generated.json
    else
        sed -i "s|${util_tok}|false|g" generated.json
    fi
done

mv generated.json "${sitenumber}.json"
echo "[Success] Pipeline operational template compiled successfully as: ${sitenumber}.json"

# 5. Final Active Container Deployment Block
echo "Begin runtime container lifecycle update execution step? (y/n)"
read -r choice

if [[ "$choice" == "y" ]]; then
    # Create cold fallback copies of primary configs
    if [ -f "$HOME/iris.json" ]; then
        mv "$HOME/iris.json" "$HOME/iris.json.bk"
    fi
    cp "./${sitenumber}.json" "$HOME/iris.json"

    # Resolve active internal image version parameters cleanly using Docker image parsing arrays
    version_num=$(sudo docker images | grep "${IMAGE_NAME}" | awk '{print $2}' | awk -F "v" '{print $2}' | awk -F "." '{print $1}' | sort -n | tail -n 1)
    if [ -z "$version_num" ]; then
        version_num="1" # Default fallback version tracking tag index
    fi
    echo "[Docker] Detected local cluster image baseline index: v${version_num}.0"
    
    echo "[Docker] Terminating legacy running execution container containers..."
    sudo docker rm -f "${CONTAINER_NAME}" &>/dev/null
    
    echo "Pull down an updated platform image tag layer from remote registry? (y/n)"
    read -r choice2
    
    if [[ "$choice2" == "y" ]]; then
        echo "Enter explicit target version release index integer (e.g., 16):"
        read -r docker_ver_num
        echo "[Docker] Syncing downstream image layer..."
        sudo docker pull "${REGISTRY_URL}/${IMAGE_NAME}:v${docker_ver_num}.0"
        target_version="v${docker_ver_num}.0"
    else
        target_version="v${version_num}.0"
    fi

    # Reset environment handles for X11 server bindings
    export DISPLAY=:0
    xhost +local:root &>/dev/null
    
    echo "[Docker] Initializing optimized NVIDIA Runtime deep learning container layer..."
    # Formulate standardized mount structures passing hardware drivers directly to container instances
    sudo docker create \
        -v /opt/nvidia/deepstream/deepstream-5.1/:/opt/nvidia/deepstream/deepstream-5.1/ \
        -it --restart=always --net=host --runtime nvidia \
        -e DISPLAY="$DISPLAY" \
        -v "$HOME/iris.json:/app/DS/iris.json" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /usr/bin/docker:/usr/bin/docker \
        -v /tmp/.X11-unix/:/tmp/.X11-unix \
        -v /usr/local/cuda/include:/usr/local/cuda/include \
        -v /usr/include/aarch64-linux-gnu:/usr/include/aarch64-linux-gnu \
        -v /usr/lib/aarch64-linux-gnu/:/usr/lib/aarch64-linux-gnu \
        --name "${CONTAINER_NAME}" \
        "${REGISTRY_URL}/${IMAGE_NAME}:${target_version}"

    echo "[Docker] Commencing hardware engine executions..."
    sudo docker start "${CONTAINER_NAME}"
    
    echo "----------------------------------------------------------------------"
    echo " Streaming Live Pipeline Container Execution Metrics Output...        "
    echo "----------------------------------------------------------------------"
    sudo docker logs -f "${CONTAINER_NAME}" --tail 100
else
    echo "Deployment operation halted. Exiting smoothly."
fi
