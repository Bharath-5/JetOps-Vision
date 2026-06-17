#!/bin/bash
# ==============================================================================
# Automated Edge Network Configuration & Validation Script
# Provisions static IP network parameters on network interfaces, verifies 
# internet gateway paths post-reboot, and handles dynamic fallbacks on error.
# ==============================================================================

LOG_FILE="/etc/.ip_provision_status.txt"    # Normalized generic log pointer
TARGET_IP="DeviceIPAddress"                 # Token parsed dynamically by orchestrator
SUDO_PASS="DevicePassword"                  # Token parsed dynamically by orchestrator

# Dynamically calculate the gateway address by swapping the trailing octet to .1
GATEWAY_IP=$(echo "${TARGET_IP}" | sed "s/\.[0-9]*$/.1/g")

echo "======================================================================"
echo " Edge Computing Platform Network Provisioning Engine                  "
echo "======================================================================"

if [ -f "$LOG_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Log verification marker discovered. Validating changes..." >> "$LOG_FILE"
    echo "Executing connectivity test via ICMP ping..." >> "$LOG_FILE"
    
    # Ping a reliable public DNS resolver to verify outward routing viability
    if ping -c 10 -W 10 8.8.8.8 &> /dev/null; then
        echo "Network status: Connected. Removing provisioning routine from persistence initialization..." >> "$LOG_FILE"
        sed -i '/IP_Set.sh/d' /etc/rc.local 2>/dev/null
        echo "Static IP Allocation Success!" >> "$LOG_FILE"
    else
        echo "Network status: Connection Failed. Rolling back changes to prevent hardware isolation..." >> "$LOG_FILE"
        
        # Safe purging of static structural configuration lines
        sed -i '/auto eth0/d' /etc/network/interfaces
        sed -i '/iface eth0/d' /etc/network/interfaces
        sed -i '/address/d' /etc/network/interfaces
        sed -i '/netmask/d' /etc/network/interfaces
        sed -i '/gateway/d' /etc/network/interfaces
        
        echo "Rollback complete. Restoring dynamic DHCP interface states. Scheduling system reboot..." >> "$LOG_FILE"
        sed -i '/IP_Set.sh/d' /etc/rc.local 2>/dev/null
        reboot    
    fi
else 
    echo "Initialization marker not found. Running network provisioning configuration for the first time..." | tee "$LOG_FILE"
    echo "Compiling interface static assignments onto /etc/network/interfaces..." | tee -a "$LOG_FILE"
    
    # Append structured interface directives safely
    {
        echo "auto eth0"
        echo "iface eth0 inet static"
        echo "address ${TARGET_IP}"
        echo "netmask 255.255.255.0"
        echo "gateway ${GATEWAY_IP}"
    } >> /etc/network/interfaces
    
    echo "Injecting verification routing engine onto system startup profiles..."
    
    # Ensure standard shell header properties exist if creating rc.local from scratch
    if [ ! -f /etc/rc.local ]; then
        echo "#!/bin/bash" > /etc/rc.local
    fi
    
    # Inject secure startup validation invocation string hook
    echo "sleep 1m && echo '${SUDO_PASS}' | sudo -S $(pwd)/IP_Set.sh" >> /etc/rc.local
    
    chmod +x /etc/rc.local
    systemctl enable rc.local 2>/dev/null
    
    echo "Static configuration matrix established. Initializing system reboot to bind configurations..."
    cat /etc/network/interfaces >> "$LOG_FILE"
    reboot
fi
