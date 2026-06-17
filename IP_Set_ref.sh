#!/bin/bash
# ==============================================================================
# Automated Edge Network Configuration & Validation Script
# Provisions static IP network parameters on network interfaces, verifies 
# internet gateway paths post-reboot, and handles dynamic fallbacks on error.
# ==============================================================================

LOG_FILE="/etc/.ip_set.txt"
IP="DeviceIPAddress"
pass="DevicePassword"

# Dynamic Regex Fix: Automatically swaps the last octet to .1 regardless of the IP
gateway=$(echo "${IP}" | sed "s/\.[0-9]*$/.1/g")

echo "======================================================================"
echo " Edge Computing Platform Network Provisioning Engine                  "
echo "======================================================================"

if [ -f "$LOG_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Verification marker found. Validating routing pathways..." >> "$LOG_FILE"
    echo "Checking Internet connectivity..." >> "$LOG_FILE"
    
    # Verify gateway capability using public ICMP pings
    if ping -c 10 -W 10 8.8.8.8 &> /dev/null; then
        echo "Internet path confirmed. Removing provisioning hook from startup persistence..." >> "$LOG_FILE"
        sed -i '/IP_Set.sh/d' /etc/rc.local 2>/dev/null
        echo "Static IP Allocation Success!" >> "$LOG_FILE"
    else
        echo "Internet route unreachable. Rolling back changes to prevent device isolation..." >> "$LOG_FILE"
        
        # Safely purge conflicting static interface allocations
        sed -i '/auto eth0/d' /etc/network/interfaces
        sed -i '/iface eth0/d' /etc/network/interfaces
        sed -i '/address/d' /etc/network/interfaces
        sed -i '/netmask/d' /etc/network/interfaces
        sed -i '/gateway/d' /etc/network/interfaces
        
        echo "Static configurations purged. Restoring fallback dynamic DHCP client. Rebooting..." >> "$LOG_FILE"
        sed -i '/IP_Set.sh/d' /etc/rc.local 2>/dev/null
        reboot    
    fi
else 
    echo "Initialization marker missing. Configuring network for the first time..." | tee "$LOG_FILE"
    echo "Writing static assignments onto network interface directory..." | tee -a "$LOG_FILE"
    
    # Consolidate disk I/O stream modifications cleanly
    {
        echo "auto eth0"
        echo "iface eth0 inet static"
        echo "address ${IP}"
        echo "netmask 255.255.255.0"
        echo "gateway ${gateway}"
    } >> /etc/network/interfaces
    
    echo "Injecting validation logic loop into rc.local persistence profiles..."
    
    # Ensure standard shell header properties exist if creating rc.local from scratch
    if [ ! -f /etc/rc.local ]; then
        echo "#!/bin/bash" > /etc/rc.local
    fi
    
    echo "sleep 1m && echo '${pass}' | sudo -S \$(pwd)/IP_Set.sh" >> /etc/rc.local
    chmod +x /etc/rc.local
    systemctl enable rc.local 2>/dev/null
    
    echo "Static configuration matrix established. Initializing system reboot to bind configurations..."
    cat /etc/network/interfaces >> "$LOG_FILE"
    reboot
fi
