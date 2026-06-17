#!/usr/bin/python3
"""
Edge AI Computing Platform Telemetry Agent
Periodically tracks physical edge interface data allocations (Ethernet/VPN) 
and securely broadcasts active runtime heartbeats back to an infrastructure monitoring API.
"""

import os
import sys
import time
import requests

# ==============================================================================
# ENVIRONMENT ROUTING & CREDENTIAL ARCHITECTURE (Scrubbed / Extracted Defaults)
# ==============================================================================
API_URL = os.environ.get("FLEET_HEARTBEAT_URL", "https://api.yourdomain.com/api/v2/Asset/Heartbeat")
APP_ID = os.environ.get("FLEET_APP_ID", "00000000-0000-0000-0000-000000000000")
CUST_ID = os.environ.get("FLEET_CUST_ID", "00000000-0000-0000-0000-000000000000")
SESSION_TOKEN = os.environ.get("FLEET_SESSION_TOKEN", "00000000-0000-0000-0000-000000000000")

# Interface Targets (Defaults can be overridden seamlessly via variables)
PRIMARY_IFACE = os.environ.get("EDGE_PRIMARY_INTERFACE", "eth0")
TUNNEL_IFACE = os.environ.get("EDGE_TUNNEL_INTERFACE", "tun1")

# Asset Context Mapping (Populated via system parameters or general fallbacks)
ASSET_SITE_TAG = os.environ.get("EDGE_SITE_DESIGNATION", "2358_RegionC-Branch_Kappa")
ASSET_HARDWARE_MODEL = os.environ.get("EDGE_HARDWARE_MODEL", "NANO")

ASSET_ID = f"COMPUTE_NODE_{ASSET_SITE_TAG}_{ASSET_HARDWARE_MODEL}"
SITE_ID = f"SITE_{ASSET_SITE_TAG}"

def get_ipaddress_matrix():
    """
    Queries local platform routing details using network boundaries safely.
    Parses active network device arrays dynamically.
    """
    interfaces_data = []
    try:
        # Isolate active system physical/virtual adapter pipelines
        with os.popen("ip addr | grep LOWER_UP | awk '{print $2}'") as eth_pipe:
            interfaces = eth_pipe.read().strip().replace(':', '').split('\n')
        
        if not interfaces or interfaces == ['']:
            return {'interface': [], 'itfip': []}
            
        # Safely filter layout configurations out of list head
        if len(interfaces) > 0 and 'lo' in interfaces[0]:
            del interfaces[0]

        for iface in interfaces:
            query_cmd = f"ip addr show {iface} | awk '{{if ($2 == \"forever\"){{!$2}} else {{print $2}}}}'"
            with os.popen(query_cmd) as pipe:
                address_blocks = pipe.read().strip().split('\n')
                
            # Normalize interface listing sizes uniformly
            while len(address_blocks) < 4:
                address_blocks.append('unavailable')
                
            address_blocks[0] = iface
            interfaces_data.append(address_blocks)

        return {'interface': interfaces, 'itfip': interfaces_data}

    except Exception as err:
        return str(err)

def extract_interface_ip(target_interface):
    """
    Resolves the exact bound IP string mapping out of extracted matrix blocks.
    """
    matrix_response = get_ipaddress_matrix()
    if isinstance(matrix_response, str) or 'itfip' not in matrix_response:
        return 'unavailable'
        
    all_info = matrix_response['itfip']
    for info in all_info:
        if info[0] == target_interface:
            # Safely grab IP block mapping, tracking fallback criteria
            return info[2] if len(info) > 2 else 'unavailable'
    return 'unavailable'

def get_epoch_milliseconds_timestamp():
    """
    Generates standard unix milliseconds string header tags.
    """
    return str(int(round(time.time() * 1000)))

def broadcast_heartbeat_payload():
    """
    Gathers local health configuration context metrics and fires standard
    JSON structure payloads out to telemetry cluster endpoint arrays.
    """
    eth_ip = str(extract_interface_ip(PRIMARY_IFACE))
    tun_ip = str(extract_interface_ip(TUNNEL_IFACE))
    current_timestamp = get_epoch_milliseconds_timestamp()

    # Formulate structured payload dictionaries
    payload = {
        "CameraInfoList": [],
        "Edgeinfo": {
            "Memory": 0,
            "AssetId": ASSET_ID,
            "AssetType": ASSET_HARDWARE_MODEL,
            "CpuMem": 0,
            "DiskMem": 0,
            "EthIp": eth_ip,
            "SiteId": SITE_ID,
            "Tun0Ip": tun_ip
        }
    }

    # Construct request authentication metadata
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "ApplicationId": APP_ID,
        "SessionToken": SESSION_TOKEN,
        "UserId": ASSET_ID,
        "CustId": CUST_ID,
        "MessageId": current_timestamp
    }

    try:
        # Use a timeout parameter to prevent infinite script execution blocking on flaky networks
        response = requests.post(url=API_URL, headers=headers, json=payload, timeout=15)
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Telemetry Dispatch Status Code: {response.status_code}")
    except requests.exceptions.RequestException as error:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Telemetry Agent Request Unsuccessful: {error}")

def main():
    print(f"Initializing Edge Telemetry Pipeline for Target: {ASSET_ID}...")
    print(f"Tracking interfaces: Primary={PRIMARY_IFACE}, Tunnel={TUNNEL_IFACE}")
    print("----------------------------------------------------------------------")
    
    # Run loop context tracking every 5 minutes (300 seconds)
    while True:
        broadcast_heartbeat_payload()
        time.sleep(300)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nTelemetry Agent manually terminated. Exiting.")
        sys.exit(0)
