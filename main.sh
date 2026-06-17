#!/bin/bash

# ==============================================================================
# CONFIGURATION & ENVIRONMENT VARIABLES (Override these in your system or .env)
# ==============================================================================
# Use values from environment, otherwise fallback to safe generic defaults
DEVICE_PASSWORD="${EDGE_DEVICE_PASS:-"your_secure_password"}"
DEFAULT_DVR_USER="${DEFAULT_DVR_USER:-"admin"}"
DEFAULT_DVR_PASS="${DEFAULT_DVR_PASS:-"password123"}"

# API Configurations (Scrubbed and genericized)
API_BASE_URL="${MONITORING_API_URL:-"https://api.yourdomain.com:8002"}"
API_MESSAGE_ID="${API_MESSAGE_ID:-"HEARTBEAT_GENERATED_ID"}"
API_APP_ID="${API_APP_ID:-"00000000-0000-0000-0000-000000000000"}"
API_CUST_ID="${API_CUST_ID:-"00000000-0000-0000-0000-000000000000"}"
API_USER_ID="${API_USER_ID:-"00000000-0000-0000-0000-000000000000"}"
API_TOKEN="${API_TOKEN:-"00000000-0000-0000-0000-000000000000"}"

echo "======================================================================"
echo " Edge Device Deployment & Maintenance Framework                       "
echo "======================================================================"
echo "Choose an option. The script will exit if any other key is pressed:"
echo "1. Setup device before dispatch"
echo "2. SSH into a device"
echo "3. Set static IP for a device"
echo "4. RTSP Deployment"
echo "5. Non RTSP Deployment"
echo "6. Extract RTSP historical feed"
echo "7. Maintain sites: NonRTSP script"
echo "8. Maintain sites: Down script"
echo "9. Get Remote Desktop/VNC access"

read -r option
set_flag=0

if [[ $option -eq 1 ]]; then
    echo "Work in progress"    
elif [[ $option -eq 2 ]]; then
    echo "Enter search string:"
    read -r str
    rm -f full_details.txt
    cat DB/Cluster*.txt >> full_details.txt 2>/dev/null
    grep "${str}" full_details.txt
    creds=$(grep "${str}" full_details.txt | awk '{print $2}')
    echo "Connecting via SSH to ${creds}..."
    sshpass -p "${DEVICE_PASSWORD}" ssh "${creds}" 
elif [[ $option -eq 3 ]]; then
    echo "Enter the device creds (<user>@<ip>):"
    read -r creds

    cp IP_Set_ref.sh IP_Set.sh
    
    echo "Enter the IP to be set:"
    read -r ip_addr
    
    sed -i "s/DeviceIPAddress/${ip_addr}/g" IP_Set.sh
    sed -i "s/DevicePassword/${DEVICE_PASSWORD}/g" IP_Set.sh
    
    sshpass -p "$DEVICE_PASSWORD" scp -o StrictHostKeyChecking=no IP_Set.sh "$creds":
    sshpass -p "$DEVICE_PASSWORD" ssh "$creds" "echo $DEVICE_PASSWORD | sudo -S chmod 744 ./IP_Set.sh; echo $DEVICE_PASSWORD | sudo -S ./IP_Set.sh"
fi
        
while [[ $option -eq 4 ]]; do
    if [[ $set_flag -eq 0 ]]; then
        echo "Enter the ssh credentials <username>@<ip-address>:"
        read -r creds
        device_username=$(echo "$creds" | awk -F "@" '{print $1}')
        device_ip=$(echo "$creds" | awk -F "@" '{print $2}')
        set_flag=1
    fi

    echo "Choose an option:"
    echo "1. Fix NoEGL Display"
    echo "2. Extract Cam recordings"
    echo "3. JSON generation and deployment"
    echo "4. Network Health Patch"
    read -r option2

    if [[ $option2 -eq 1 ]]; then
        echo "This is currently a work in progress" 
    elif [[ $option2 -eq 2 ]]; then
        cp host_ref hosts
        cp CamRec_ref.sh CamRec.sh
        sed -i "s/<ip-address>/${device_ip}/g" hosts
        sed -i "s/<username>/${device_username}/g" hosts

        if grep -q "${device_ip}" ./DB/Cluster*.txt; then
            sitenumber=$(grep "${device_ip}" ./DB/Cluster*.txt | awk '{print $3}' | awk -F "_" '{print $1}')
            echo "The site code is ${sitenumber}"
        else
            echo "The site details are not in local DB. Please enter the site name without spaces [Ex: 123_XYZ_Road]:"
            read -r sitename
            sitenumber=$(echo "$sitename" | awk -F "_" '{print $1}')
            echo "Using sitenumber: ${sitenumber}"
        fi

        echo "Do you want to use default DVR credentials? (y / n)"
        read -r use_default
        if [[ $use_default == "y" ]]; then
            sed -i "s/rtsp_username/${DEFAULT_DVR_USER}/g" CamRec.sh
            sed -i "s/rtsp_password/${DEFAULT_DVR_PASS}/g" CamRec.sh
        else
            echo "Enter DVR username:"
            read -r DVR_username
            echo "Enter DVR password:"
            read -r DVR_password
            sed -i "s/rtsp_username/${DVR_username}/g" CamRec.sh
            sed -i "s/rtsp_password/${DVR_password}/g" CamRec.sh
        fi
        sed -i "s/sitenumber/${sitenumber}/g" CamRec.sh

        echo "Detecting network interface IP..."
        # Pulls up available local IPs dynamically instead of hardcoded subnets
        local_ips=$(ifconfig | grep -E "inet " | awk '{print $2}' | grep -v "127.0.0.1")
        echo "Available local IPs:"
        echo "${local_ips}"
        echo "Enter the exact host IP you wish to use for routing data back:"
        read -r host_ip

        host_user=$(whoami)
        echo "Your credentials: $host_user@$host_ip"
        sed -i "s/host_username/$host_user/g" CamRec.sh
        sed -i "s/host_IP/$host_ip/g" CamRec.sh
        echo "Please enter your password for secure callback (scp):"
        read -r -s host_pass # -s hides password typing input
        echo ""
        sed -i "s/host_password/$host_pass/g" CamRec.sh
    
        sshpass -p "$DEVICE_PASSWORD" scp -o StrictHostKeyChecking=no CamRec.sh "$creds":
        sshpass -p "$DEVICE_PASSWORD" ssh "$creds" "chmod +x CamRec.sh; ./CamRec.sh"

    elif [[ $option2 -eq 3 ]]; then
        if [[ $set_flag -eq 0 ]]; then
            echo "Enter the ssh credentials <username>@<ip-address>:"
            read -r creds
            device_username=$(echo "$creds" | awk -F "@" '{print $1}')
            device_ip=$(echo "$creds" | awk -F "@" '{print $2}')
            set_flag=1
        fi
        rm -f generated.json deployment_config.json
        cp reference.json generated.json
        
        count=0    
        echo "Base deployment file created."
        echo "Enter site number:"
        read -r sitenumber
        sed -i "s/xxxx/${sitenumber}/g" generated.json
        
        echo "Enter unique site_ID:"
        read -r siteid 
        sed -i "s/ssss/${siteid}/g" generated.json
        
        echo "Enter asset ID:"
        read -r assetID
        sed -i "s/aaaa/${assetID}/g" generated.json
        
        echo "Updating stream infrastructure configurations..."
        echo "Enter camera system username:"
        read -r rtsp_username
        echo "Enter camera system password (use %40 for @):"
        read -r rtsp_password
        sed -i "s/rtsp_user_name/${rtsp_username}/g" generated.json
        sed -i "s/rtsp_password/${rtsp_password}/g" generated.json
                
        # --- Camera Streaming Config Block ---
        # Camera channel names genericized for public codebase versatility
        for cam_name in "Zone_1_Primary" "Zone_2_Secondary" "Zone_3_Internal" "Zone_4_External"; do
            echo "Channel number [4 digits] for ${cam_name}:"
            read -r ch
            echo "Which processing engine / pipeline index to route to? [10,20,30,40]:"
            read -r choice
            
            # Use lower-case sanitized name for token replacement mapping
            token_prefix=$(echo "${cam_name}" | tr '[:upper:]' '[:lower:]' | cut -d'_' -f1-2)
            sed -i "s/${token_prefix}_ch/${ch}/g" generated.json
            
            echo "Number of frames to drop for bandwidth optimization? (e.g. 0-5):"
            read -r dr
            sed -i "s/${token_prefix}_drp_no/${dr}/g" generated.json
            
            echo "Enable pipeline tracking for this camera? y/n"
            read -r active
            if [[ $active == "y" ]]; then
                ((count++))
                sed -i "s/${token_prefix}_util/true/g" generated.json
            else
                sed -i "s/${token_prefix}_util/false/g" generated.json
            fi
        done
        
        echo "Total active pipelines utilized: $count"
        sed -i "s/num_of_cams/$count/g" generated.json

        echo "DeepStream Streammux Resolution Configuration:"
        echo "Enter Processing Width (e.g. 1920):"
        read -r w
        sed -i "s/streammux_width/$w/g" generated.json
        echo "Enter Processing Height (e.g. 1080):"
        read -r h
        sed -i "s/streammux_height/$h/g" generated.json
        
        mv generated.json deployment_config.json
        echo "Configuration file compiled successfully as deployment_config.json"
        
        echo "Copy configuration metadata to the edge node and initiate pipeline stack? (y/n)"
        read -r DeployChoice
    
        if [[ $DeployChoice == "y" ]]; then
            sshpass -p "$DEVICE_PASSWORD" scp -o StrictHostKeyChecking=no deployment_config.json "$creds":
            echo "Which pipeline schema version do you want to deploy? (Integer only, e.g., 16):"
            read -r ExpectedVersionNum
            cp RTSP_Deploy_ref.sh RTSP_Deploy.sh
            sed -i "s/ExpectedVersionNumber/${ExpectedVersionNum}/g" RTSP_Deploy.sh
            sed -i "s/DevicePassword/$DEVICE_PASSWORD/g" RTSP_Deploy.sh    

            echo "Is this target hardware an Official DevKit baseline? (y / n)"
            read -r DevKit
            if [[ $DevKit == "y" ]]; then
                sed -i "s/DeviceType/1/g" RTSP_Deploy.sh
            else
                sed -i "s/DeviceType/2/g" RTSP_Deploy.sh
            fi

            if [[ $ExpectedVersionNum -eq 16 ]]; then
                # Handle standard object detection model configuration files dynamically
                sshpass -p "$DEVICE_PASSWORD" scp -o StrictHostKeyChecking=no config_infer_primary_yolov5s.txt "$creds":
            fi

            sshpass -p "$DEVICE_PASSWORD" scp -o StrictHostKeyChecking=no RTSP_Deploy.sh "$creds":
            sshpass -p "$DEVICE_PASSWORD" ssh "$creds" "chmod +x RTSP_Deploy.sh; ./RTSP_Deploy.sh"
        fi
    elif [[ $option2 -eq 4 ]]; then
        echo "Running Diagnostic Ping Correction..."
    else
        break
    fi
done

while [[ $option -eq 5 ]]; do
    echo "Choose an option:"
    echo "1. File-based processing image fetch from SDK-Test"
    echo "2. Local testing execution in container machine"
    echo "3. Stream generator structure inclusion"
    echo "4. Append telemetry config settings directly"
    read -r option2
    echo "Module integration framework: Work in progress"
    break
done

if [[ $option -eq 6 ]]; then
    if [[ $set_flag -eq 0 ]]; then
        echo "Enter the ssh credentials <username>@<ip-address>:"
        read -r creds
        device_username=$(echo "$creds" | awk -F "@" '{print $1}')
        device_ip=$(echo "$creds" | awk -F "@" '{print $2}')
        set_flag=1
    fi
    cp OldRec_ref.sh OldRec.sh
    cp host_ref hosts
    echo "Select target processing camera channel:"
    echo "1. Primary Tracking Target"
    echo "2. Secondary Area Entry"
    echo "3. Interior Workspace View"
    echo "4. Perimeter External View"
    read -r CamSelect
    case $CamSelect in
        1) sed -i "s/SelectedCamName/Zone_1_Primary/g" OldRec.sh ;;
        2) sed -i "s/SelectedCamName/Zone_2_Secondary/g" OldRec.sh ;;
        3) sed -i "s/SelectedCamName/Zone_3_Internal/g" OldRec.sh ;;
        4) sed -i "s/SelectedCamName/Zone_4_External/g" OldRec.sh ;;
    esac

    echo "Enter date parameter for retrospective retrieval (YYYYMMDD):"
    read -r reqd_date
    sed -i "s/YYYYMMDD/$reqd_date/g" OldRec.sh
    
    echo "Enter timestamp block start window (HHMMSS - 24Hr):"
    read -r reqd_time
    sed -i "s/HHMMSS/$reqd_time/g" OldRec.sh
    
    echo "Enter data partition length in total minutes:"
    read -r reqd_duration
    sed -i "s/Duration_Min/$reqd_duration/g" OldRec.sh
        
    sed -i "s/<ip-address>/${device_ip}/g" hosts
    sed -i "s/<username>/${device_username}/g" hosts
        
    if grep -q "${device_ip}" ./DB/Cluster*.txt; then
        sitenumber=$(grep "${device_ip}" ./DB/Cluster*.txt | awk '{print $3}' | awk -F "_" '{print $1}')
        echo "The detected site classification code is ${sitenumber}"
    else
        echo "Site details missing from local database directory. Enter system tag string [Ex: 123_Location_Name]:"
        read -r sitename
        sitenumber=$(echo "$sitename" | awk -F "_" '{print $1}')
        echo "Assigned site designation number: ${sitenumber}"
    fi
        
    sed -i "s/sitenumber/${sitenumber}/g" CamRec.sh
    echo "Checking target loopback address context..."
        
    local_ips=$(ifconfig | grep -E "inet " | awk '{print $2}' | grep -v "127.0.0.1")
    echo "Available runtime node IPs on host:"
    echo "${local_ips}"
    echo "Input intended callback deployment IP destination:"
    read -r host_ip
        
    host_user=$(whoami)
    echo "Your routing schema: $host_user@$host_ip"
    sed -i "s/host_username/$host_user/g" OldRec.sh
    sed -i "s/host_IP/$host_ip/g" OldRec.sh
    echo "Please input access context password for safe transport:"
    read -r -s host_pass
    echo ""
    sed -i "s/host_password/$host_pass/g" OldRec.sh

    cp ref.yml OldRec.yml
    sed -i "s/execute_this/OldRec.sh/g" OldRec.yml
    echo "Executing automation pipeline using Ansible orchestration engine..."
    ansible-playbook OldRec.yml    

elif [[ $option -eq 7 ]]; then
    ./ping_nonrtsp.sh

elif [[ $option -eq 8 ]]; then
    echo "Initiating Global Node Telemetry Verification Pipeline..."
    echo "1. Identify active disconnected edge compute platforms"
    echo "2. Download live state records securely from metric dashboard telemetry API"
    echo "3. Query video parsing errors (0 FPS active dropped state traps)"
    echo "4. Reconcile discrepancy arrays between state machines"
    echo "--------------------------------------------------------------------------------"
    cat ./DB/Cluster*.txt > full_details.txt 2>/dev/null
    awk '{print $2}' full_details.txt | awk -F "@" '{print $2}' > all_ip.txt
    
    echo "Computing host reachability index (fping)..."
    fping -t 5000 -f all_ip.txt | grep "unreachable" | awk '{print $1}' > raw_down_ips.txt
    
    echo "Unreachable Hardware Fleet Logs:"
    while read -r IP; do
        grep -w "$IP" full_details.txt
    done < raw_down_ips.txt | tee Device_down.txt
    rm -f raw_down_ips.txt

    echo "Total devices currently completely un-routable / offline:"
    wc -l < Device_down.txt
    
    # Generic loop checking logic for infrastructure scaling tags rather than specific company phases
    for tag in "Cluster1" "Cluster2" "Cluster3" "Cluster4"; do
        echo "Unreachable nodes classified under [${tag}]:"
        grep -c "${tag}" Device_down.txt
    done
    echo "--------------------------------------------------------------------------------"
    
    # Dynamically build standard tracking URL via safe variable definitions
    START_DATE=$(date -u '+%Y-%m-%d')
    TIME_WINDOW=$(date -u -d -4hours '+%H:%M:%S')
    END_DATE=$(date -u '+%Y-%m-%d')
    END_TIME=$(date -u '+%H:%M:%S')
    
    QUERY_URL="${API_BASE_URL}/api/v2/Asset/HealthStatus/CameraHealthSitewise?StartDate=${START_DATE}%20${TIME_WINDOW}&EndDate=${END_DATE}%20${END_TIME}&Region=Global&SiteStatus=ONLINE"
    echo "Querying telemetry metrics target url: ${QUERY_URL}"
    
    curl "$QUERY_URL" \
      -H "authority: $(echo "${API_BASE_URL}" | awk -F/ '{print $3}')" \
      -H "messageid: ${API_MESSAGE_ID}" \
      -H "zumo-api-version: 2.0.0" \
      -H "applicationid: ${API_APP_ID}" \
      -H "custid: ${API_CUST_ID}" \
      -H 'content-type: application/json' \
      -H 'accept: application/json' \
      -H "userid: ${API_USER_ID}" \
      -H "sessiontoken: ${API_TOKEN}" \
      -H 'compression: false' \
      --compressed > current.json
    
    # Process structured outputs cleanly
    sed 's/\\n/\n/g' current.json | sed 's/\\"/"/g' | sed 's/\\r//g' | grep -E -w "SiteId|EdgeDeviceHealth" | uniq | awk 'NR%3' > json_extracted.txt
    
    grep SiteId json_extracted.txt | sed 's/^ *//' | uniq | awk -F "\"" '{print $4}' | sed 's|SITE_||g' | awk -F "_" '{print $1}' > 1.txt

    grep EdgeDeviceHealth json_extracted.txt | awk -F "\"" '{print $4}' > 2.txt
    paste 1.txt 2.txt > Dashboard.txt
    rm -f 1.txt 2.txt
    
    grep -v "INACTIVE" Dashboard.txt > Dashboard_active.txt
    grep "INACTIVE" Dashboard.txt > Dashboard_inactive.txt
    
    cp Device_down.txt Device_down.txt.bk
    awk '{print $3}' Device_down.txt > Device_down_1.txt
    
    while read -r i; do
        sed -i "/^${i}_/d" Device_down_1.txt
    done < <(awk '{print $1}' Dashboard_inactive.txt)
    echo "--------------------------------------------------------------------------------"
    
    sed 's/\\n/\n/g' current.json | sed 's/\\"/"/g' | sed 's/\\r//g' | grep -B 1 "\"CameraFPS\": 0.0" | sed "/--/d" | grep -v Camera | awk -F "\"" '{print $4}' | uniq | grep -o -E '[0-9]+_' > 0fps.txt
    
    echo "Warning: The following operating pipelines indicate 0.0 FPS Video Streaming Drops:"
    awk '{print $3}' full_details.txt > full.txt
    rm -f 0fps_site

    while read -r i; do
        grep "^$i" full.txt >> 0fps_site    
    done < 0fps.txt
    
    grep -F -f 0fps_site full_details.txt 2>/dev/null
    rm -f 0fps.txt 0fps_site full.txt
    
    echo "--------------------------------------------------------------------------------"
    echo "Reconciliation Error Matrix: Compute node offline but flagged ACTIVE on monitoring stack:"
    grep -F -f Device_down_1.txt full_details.txt | tee disableThese.txt
    
    cat Device_down.txt | awk '{print $3}' | grep -o -E '[0-9]+_' | grep -o -E '[0-9]+' > Device_down_sitecode.txt
    awk '{print $1"_"}' Dashboard_inactive.txt > Dashboard_inactive_new.txt
    
    while read -r i; do
        sed -i "/^${i}_/d" Dashboard_inactive_new.txt 
    done < Device_down_sitecode.txt
    
    echo "--------------------------------------------------------------------------------"
    echo "Reconciliation Error Matrix: Compute node online/reachable but flagged INACTIVE on monitoring stack:"
    rm -f look_into
    grep -F -f Dashboard_inactive_new.txt full_details.txt | tee enableThese.txt > look_into
    cat look_into
    
    rm -f Dashboard*.txt Device*.txt all_ip.txt ./*.bk json*.txt current.json Dashboard_inactive_new.txt
    rm -f disableThese.txt enableThese.txt full_details.txt
    
    echo "Do you want to establish multi-terminal SSH validation triage to looking nodes? (y/n)"
    read -r choice
    if [[ $choice == 'y' ]]; then
        cmd="gnome-terminal"
        while read -r i; do
            k=$(echo "$i" | awk -F '@' '{print $2}')
            cmd="${cmd} --tab -e \"bash -c \\\" sshpass -p ${DEVICE_PASSWORD} ssh $i ; exec bash \\\" \" "
        done < <(awk '{print $2}' look_into)
        echo "Spawning interactive cluster nodes diagnostics terminals..."
        eval "${cmd}"
    fi
    rm -f look_into
        
elif [[ $option -eq 9 ]]; then
    echo "Enter search criteria parameter:"
    read -r str
    rm -f full_details.txt
    cat DB/Cluster*.txt >> full_details.txt 2>/dev/null
    grep "${str}" full_details.txt
    creds=$(grep "${str}" full_details.txt | awk '{print $2}')
    
    echo "Configuring window system environment configurations and launching VNC Engine over SSH..."
    sshpass -p "${DEVICE_PASSWORD}" ssh "${creds}" "gsettings set org.gnome.Vino prompt-enabled false; gsettings set org.gnome.Vino require-encryption false; /usr/lib/vino/vino-server --display=:0"
else
    echo "The script now exits. Thank you!"
fi
