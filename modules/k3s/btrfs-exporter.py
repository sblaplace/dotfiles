#!/usr/bin/env python3
import subprocess
import re
from prometheus_client import start_http_server, Gauge
import time

# Metrics
btrfs_total_size = Gauge('btrfs_total_size_bytes', 'Total BTRFS filesystem size', ['device', 'mount'])
btrfs_used_size = Gauge('btrfs_used_size_bytes', 'Used BTRFS space', ['device', 'mount', 'type'])
btrfs_device_count = Gauge('btrfs_device_count', 'Number of devices in BTRFS filesystem', ['mount'])
btrfs_raid_level = Gauge('btrfs_raid_level', 'BTRFS RAID level (1=raid1, 0=single)', ['mount', 'type'])

def parse_btrfs_fi_show():
    """Parse btrfs filesystem show output"""
    output = subprocess.check_output(['btrfs', 'filesystem', 'show']).decode()
    filesystems = {}
    
    current_label = None
    for line in output.split('\n'):
        if 'Label:' in line or 'uuid:' in line:
            # Extract mount point from label line
            if 'path' in line:
                current_label = line.split('path')[-1].strip()
        elif 'devid' in line and current_label:
            # Extract size info
            match = re.search(r'size ([\d.]+)([KMGT]?B) used ([\d.]+)([KMGT]?B)', line)
            if match:
                filesystems[current_label] = {
                    'size': match.group(1) + match.group(2),
                    'used': match.group(3) + match.group(4)
                }
    
    return filesystems

def parse_btrfs_fi_df(mount):
    """Parse btrfs filesystem df output"""
    output = subprocess.check_output(['btrfs', 'filesystem', 'df', mount]).decode()
    data = {}
    
    for line in output.split('\n'):
        if 'RAID1' in line:
            data['raid_type'] = 'raid1'
        elif 'single' in line:
            data['raid_type'] = 'single'
            
        # Parse used/total
        match = re.search(r'used=([\d.]+)([KMGT]?B)', line)
        if match:
            value = float(match.group(1))
            unit = match.group(2)
            multipliers = {'B': 1, 'KB': 1024, 'MB': 1024**2, 'GB': 1024**3, 'TB': 1024**4}
            data['used'] = value * multipliers.get(unit, 1)
    
    return data

def collect_metrics():
    """Collect BTRFS metrics"""
    # Monitor /mnt/backup
    mount = '/mnt/backup'
    
    try:
        # Get filesystem usage
        output = subprocess.check_output(['btrfs', 'filesystem', 'usage', mount]).decode()
        
        # Parse data usage
        for line in output.split('\n'):
            if 'Device size:' in line:
                match = re.search(r'([\d.]+)([KMGT]?B)', line)
                if match:
                    value = float(match.group(1))
                    unit = match.group(2)
                    multipliers = {'B': 1, 'KB': 1024, 'MB': 1024**2, 'GB': 1024**3, 'TB': 1024**4}
                    btrfs_total_size.labels(device='backup', mount=mount).set(value * multipliers[unit])
            
            if 'Used:' in line:
                match = re.search(r'([\d.]+)([KMGT]?B)', line)
                if match:
                    value = float(match.group(1))
                    unit = match.group(2)
                    multipliers = {'B': 1, 'KB': 1024, 'MB': 1024**2, 'GB': 1024**3, 'TB': 1024**4}
                    btrfs_used_size.labels(device='backup', mount=mount, type='total').set(value * multipliers[unit])
        
        # Get device count
        devices = subprocess.check_output(['btrfs', 'device', 'stats', mount]).decode()
        device_count = len([l for l in devices.split('\n') if 'devid' in l])
        btrfs_device_count.labels(mount=mount).set(device_count)
        
        # Detect RAID level
        fi_df = parse_btrfs_fi_df(mount)
        if fi_df.get('raid_type') == 'raid1':
            btrfs_raid_level.labels(mount=mount, type='data').set(1)
        else:
            btrfs_raid_level.labels(mount=mount, type='data').set(0)
            
    except Exception as e:
        print(f"Error collecting BTRFS metrics: {e}")

if __name__ == '__main__':
    # Start metrics server
    start_http_server(9101)
    print("BTRFS Exporter running on :9101")
    
    while True:
        collect_metrics()
        time.sleep(15)  # Collect every 15 seconds