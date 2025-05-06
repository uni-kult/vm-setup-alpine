#!/bin/sh
set -eu

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


# No Colors
RED=''
GREEN=''
YELLOW=''
BLUE=''
MAGENTA=''
CYAN=''
NC='' 

# Function to get system information with grep
grep_info() {
    local file="$1"
    local pattern="$2"
    local use_regex="$3"
    
    if [ "$use_regex" = "true" ]; then
        grep -m 1 -E "$pattern" "$file" 2>/dev/null
    else
        grep -m 1 "$pattern" "$file" 2>/dev/null
    fi
}

# Function to format sizes in human-readable format
format_size() {
    local size=$1
    if [ -z "$size" ] || [ "$size" = "0" ]; then
        echo "0 B"
        return
    fi
    
    if [ "$size" -ge 1073741824 ]; then
        echo "$(echo "scale=1; $size/1073741824" | bc -l 2>/dev/null || echo "$size/1073741824" | awk '{printf "%.1f", $1}') GB"
    elif [ "$size" -ge 1048576 ]; then
        echo "$(echo "scale=1; $size/1048576" | bc -l 2>/dev/null || echo "$size/1048576" | awk '{printf "%.1f", $1}') MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$(echo "scale=1; $size/1024" | bc -l 2>/dev/null || echo "$size/1024" | awk '{printf "%.1f", $1}') KB"
    else
        echo "$size B"
    fi
}

# Function to calculate percentage
calc_percentage() {
    local used=$1
    local total=$2
    
    if [ "$total" -gt 0 ]; then
        echo "$(echo "scale=1; 100*$used/$total" | bc -l 2>/dev/null || echo "$used*100/$total" | awk '{printf "%.1f", $1}')%"
    else
        echo "0%"
    fi
}

# Function to log information with formatting
log_info() {
    local key="$1"
    local value="$2"
    printf "%-20s %s\n" "$key:" "$value"
}

# CPU Model and Microarchitecture
cpu_model=$(grep_info "/proc/cpuinfo" "model name")
if [ -n "$cpu_model" ]; then
    cpu_model=$(echo "$cpu_model" | sed 's/model name.*: //')
else
    cpu_model="CPU model not detected"
fi
log_info "CPU Model" "${GREEN}$cpu_model${NC}"

# CPU Microarchitecture detection (basic)
cpu_family=$(grep_info "/proc/cpuinfo" "cpu family" | sed 's/.*: //')
cpu_model_id=$(grep_info "/proc/cpuinfo" "model" | sed 's/.*: //')
cpu_stepping=$(grep_info "/proc/cpuinfo" "stepping" | sed 's/.*: //')
cpu_vendor=$(grep_info "/proc/cpuinfo" "vendor_id" | sed 's/.*: //')

# Try to determine CPU microarchitecture for Intel/AMD
cpu_arch="Unknown"
if [ "$cpu_vendor" = "GenuineIntel" ]; then
    case "$cpu_family:$cpu_model_id" in
        "6:42") cpu_arch="Sandy Bridge" ;;
        "6:45") cpu_arch="Sandy Bridge-EP" ;;
        "6:58") cpu_arch="Ivy Bridge" ;;
        "6:60"|"6:62"|"6:63") cpu_arch="Haswell" ;;
        "6:61"|"6:71"|"6:79") cpu_arch="Broadwell" ;;
        "6:78"|"6:94") cpu_arch="Skylake" ;;
        "6:142") cpu_arch="Kaby Lake" ;;
        "6:158") cpu_arch="Coffee Lake" ;;
        "6:165") cpu_arch="Comet Lake" ;;
        "6:140") cpu_arch="Tiger Lake" ;;
        "6:151"|"6:154") cpu_arch="Alder Lake" ;;
        "6:183"|"6:186") cpu_arch="Raptor Lake" ;;
        *) cpu_arch="Unknown Intel ($cpu_family:$cpu_model_id)" ;;
    esac
elif [ "$cpu_vendor" = "AuthenticAMD" ]; then
    case "$cpu_family:$cpu_model_id" in
        "21:1"|"21:2") cpu_arch="Bulldozer" ;;
        "21:16"|"21:18"|"21:19") cpu_arch="Piledriver" ;;
        "21:48"|"21:56") cpu_arch="Steamroller" ;;
        "21:96"|"21:112") cpu_arch="Excavator" ;;
        "23:1") cpu_arch="Zen" ;;
        "23:8"|"23:17"|"23:24") cpu_arch="Zen+" ;;
        "23:49"|"23:71"|"23:96"|"23:113") cpu_arch="Zen 2" ;;
        "25:1"|"25:8") cpu_arch="Zen 3" ;;
        "25:33"|"25:44") cpu_arch="Zen 4" ;;
        *) cpu_arch="Unknown AMD ($cpu_family:$cpu_model_id)" ;;
    esac
fi

[ "$cpu_arch" != "Unknown" ] && log_info "CPU Architecture" "${CYAN}$cpu_arch${NC}"

# Physical Cores vs Threads
physical_cores=$(grep -c "core id" /proc/cpuinfo 2>/dev/null || echo "Unknown")
logical_cores=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "Unknown")

if [ "$physical_cores" != "Unknown" ] && [ "$logical_cores" != "Unknown" ]; then
    if [ "$physical_cores" -eq "$logical_cores" ]; then
        log_info "CPU Cores" "${GREEN}$physical_cores Physical Cores${NC}"
    else
        log_info "CPU Cores" "${GREEN}$physical_cores Physical, $logical_cores Logical${NC}"
    fi
else
    log_info "CPU Cores" "${GREEN}$logical_cores${NC}"
fi

# CPU Frequency - Current, Min, Max
cpu_freq="Unknown"
cpu_min_freq="Unknown"
cpu_max_freq="Unknown"

if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
    cpu_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
    cpu_freq=$(echo "scale=2; $cpu_freq/1000" | bc -l 2>/dev/null || echo "$cpu_freq/1000" | awk '{printf "%.2f", $1}')
    
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq" ]; then
        cpu_min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
        cpu_min_freq=$(echo "scale=2; $cpu_min_freq/1000" | bc -l 2>/dev/null || echo "$cpu_min_freq/1000" | awk '{printf "%.2f", $1}')
    fi
    
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" ]; then
        cpu_max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
        cpu_max_freq=$(echo "scale=2; $cpu_max_freq/1000" | bc -l 2>/dev/null || echo "$cpu_max_freq/1000" | awk '{printf "%.2f", $1}')
    fi
    
    if [ "$cpu_min_freq" != "Unknown" ] && [ "$cpu_max_freq" != "Unknown" ]; then
        freq_info="${GREEN}Current: ${cpu_freq} MHz${NC} (Min: ${cpu_min_freq} MHz, Max: ${cpu_max_freq} MHz)"
    else
        freq_info="${GREEN}${cpu_freq} MHz${NC}"
    fi
    
    log_info "CPU Frequency" "$freq_info"
else
    # Try to get frequency from /proc/cpuinfo
    cpu_freq=$(grep_info "/proc/cpuinfo" "cpu MHz")
    if [ -n "$cpu_freq" ]; then
        cpu_freq=$(echo "$cpu_freq" | sed 's/cpu MHz.*: //')
        log_info "CPU Frequency" "${GREEN}${cpu_freq} MHz${NC}"
    fi
fi

# CPU Governor
if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    log_info "CPU Governor" "${CYAN}$cpu_governor${NC}"
fi

# CPU Temperature (if available)
cpu_temp="Unknown"
if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    if [ -n "$cpu_temp" ]; then
        cpu_temp=$(echo "scale=1; $cpu_temp/1000" | bc -l 2>/dev/null || echo "$cpu_temp/1000" | awk '{printf "%.1f", $1}')
        log_info "CPU Temperature" "${RED}${cpu_temp}°C${NC}"
    fi
elif [ -d "/sys/class/hwmon" ]; then
    # Try to find temperature through hwmon
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/name" ] && (grep -q "coretemp\|k10temp" "$hwmon/name" 2>/dev/null); then
            if [ -f "$hwmon/temp1_input" ]; then
                cpu_temp=$(cat "$hwmon/temp1_input" 2>/dev/null)
                cpu_temp=$(echo "scale=1; $cpu_temp/1000" | bc -l 2>/dev/null || echo "$cpu_temp/1000" | awk '{printf "%.1f", $1}')
                log_info "CPU Temperature" "${RED}${cpu_temp}°C${NC}"
                break
            fi
        fi
    done
fi

# CPU Cache
cpu_cache=$(grep_info "/proc/cpuinfo" "cache size")
if [ -n "$cpu_cache" ]; then
    cpu_cache=$(echo "$cpu_cache" | sed 's/cache size.*: //')
    log_info "CPU Cache" "$cpu_cache"
fi

# CPU Load
if [ -f "/proc/loadavg" ]; then
    load_avg=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')
    log_info "CPU Load Avg" "1min: ${YELLOW}$(echo "$load_avg" | awk '{print $1}')${NC}, 5min: ${YELLOW}$(echo "$load_avg" | awk '{print $2}')${NC}, 15min: ${YELLOW}$(echo "$load_avg" | awk '{print $3}')${NC}"
fi

# CPU Important Flags
if grep -q " aes " /proc/cpuinfo 2>/dev/null; then
    log_info "AES-NI" "Enabled"
else
    log_info "AES-NI" "Disabled"
fi

if grep -q "vmx\|svm" /proc/cpuinfo 2>/dev/null; then
    log_info "VM-x/AMD-V" "Enabled"
else
    log_info "VM-x/AMD-V" "Disabled"
fi

# Check for AVX support
avx_flags=""
if grep -q " avx512 " /proc/cpuinfo 2>/dev/null; then
    avx_flags="AVX-512"
elif grep -q " avx2 " /proc/cpuinfo 2>/dev/null; then
    avx_flags="AVX2"
elif grep -q " avx " /proc/cpuinfo 2>/dev/null; then
    avx_flags="AVX"
fi

if [ -n "$avx_flags" ]; then
    log_info "AVX Support" "${GREEN}$avx_flags${NC}"
fi

# Memory information
if command -v free >/dev/null 2>&1; then
    # Try with --si flag first
    mem_info=$(free -m --si 2>/dev/null || free -m 2>/dev/null)
    
    if [ -n "$mem_info" ]; then
        mem_total=$(echo "$mem_info" | awk 'NR==2{print $2}')
        mem_used=$(echo "$mem_info" | awk 'NR==2{print $3}')
        mem_free=$(echo "$mem_info" | awk 'NR==2{print $4}')
        mem_shared=$(echo "$mem_info" | awk 'NR==2{print $5}')
        mem_cached=$(echo "$mem_info" | awk 'NR==2{print $6}')
        
        mem_used_percent=$(calc_percentage "$mem_used" "$mem_total")
        
        mem_total_fmt=$(echo "$mem_total" | awk '{printf "%.1f", $1/1024}')
        mem_used_fmt=$(echo "$mem_used" | awk '{printf "%.1f", $1/1024}')
        
        log_info "Memory" "${YELLOW}${mem_total_fmt} GB${NC} | Used: ${YELLOW}${mem_used_fmt} GB${NC} (${YELLOW}${mem_used_percent}${NC})"
    else
        # Fallback to /proc/meminfo
        if [ -f "/proc/meminfo" ]; then
            total_mem_kb=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
            free_mem_kb=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
            
            if [ -z "$free_mem_kb" ]; then
                free_mem_kb=$(grep "MemFree" /proc/meminfo | awk '{print $2}')
                buffers_kb=$(grep "Buffers" /proc/meminfo | awk '{print $2}')
                cached_kb=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
                free_mem_kb=$((free_mem_kb + buffers_kb + cached_kb))
            fi
            
            used_mem_kb=$((total_mem_kb - free_mem_kb))
            used_percent=$(calc_percentage "$used_mem_kb" "$total_mem_kb")
            
            total_mem=$(format_size $((total_mem_kb * 1024)))
            used_mem=$(format_size $((used_mem_kb * 1024)))
            
            log_info "Memory" "${YELLOW}$total_mem${NC} | Used: ${YELLOW}$used_mem${NC} (${YELLOW}${used_percent}${NC})"
        else
            log_info "Memory" "Unknown"
        fi
    fi
else
    log_info "Memory" "Unknown"
fi

# Memory Speed/Type (if available)
if command -v dmidecode >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
    mem_type=$(dmidecode -t memory 2>/dev/null | grep "Type:" | grep -v "Type Detail" | grep -v "Error" | head -n 1 | awk '{print $2}')
    mem_speed=$(dmidecode -t memory 2>/dev/null | grep -m 1 "Speed:" | grep -v "Configured" | awk '{print $2 $3}')
    
    if [ -n "$mem_type" ] && [ -n "$mem_speed" ]; then
        log_info "Memory Type" "${CYAN}$mem_type @ $mem_speed${NC}"
    fi
fi

# Swap information
if command -v free >/dev/null 2>&1; then
    # Try with --si flag first
    swap_info=$(free -m --si 2>/dev/null | awk 'NR==3{print $2, $3}' || free -m 2>/dev/null | awk 'NR==3{print $2, $3}')
    
    if [ -n "$swap_info" ]; then
        swap_total=$(echo "$swap_info" | awk '{print $1}')
        swap_used=$(echo "$swap_info" | awk '{print $2}')
        
        # Only display if swap exists and is not zero
        if [ -n "$swap_total" ] && [ "$swap_total" != "0" ]; then
            swap_used_percent=$(calc_percentage "$swap_used" "$swap_total")
            
            swap_total_fmt=$(echo "$swap_total" | awk '{printf "%.1f", $1/1024}')
            swap_used_fmt=$(echo "$swap_used" | awk '{printf "%.1f", $1/1024}')
            
            log_info "Swap" "${BLUE}${swap_total_fmt} GB${NC} | Used: ${BLUE}${swap_used_fmt} GB${NC} (${BLUE}${swap_used_percent}${NC})"
        fi
    else
        # Fallback to /proc/meminfo
        if [ -f "/proc/meminfo" ]; then
            total_swap_kb=$(grep "SwapTotal" /proc/meminfo | awk '{print $2}')
            if [ -n "$total_swap_kb" ] && [ "$total_swap_kb" != "0" ]; then
                free_swap_kb=$(grep "SwapFree" /proc/meminfo | awk '{print $2}')
                used_swap_kb=$((total_swap_kb - free_swap_kb))
                used_percent=$(calc_percentage "$used_swap_kb" "$total_swap_kb")
                
                total_swap=$(format_size $((total_swap_kb * 1024)))
                used_swap=$(format_size $((used_swap_kb * 1024)))
                
                log_info "Swap" "${BLUE}$total_swap${NC} | Used: ${BLUE}$used_swap${NC} (${BLUE}${used_percent}${NC})"
            fi
        fi
    fi
fi

# Disk information with type detection
log_info "Storage" "Mount points; Size; Used; Usage; Type:"
if command -v df >/dev/null 2>&1; then
    df -h | grep -v "tmpfs\|udev\|none\|overlay" | awk 'NR>1 {printf "%-20s %-10s %-10s %-10s %-10s %s\n", $6, $2, $3, $4, $5, $1}' | 
    while read -r mount_point total used avail use_percent device; do
        # Try to determine disk type (SSD/HDD)
        disk_type="Unknown"
        
        # Extract actual device without partition number
        base_device=$(echo "$device" | sed -E 's/p?[0-9]+$//' | sed -E 's/mapper\///')
        
        # Check if it's a known virtual device type
        if echo "$device" | grep -q "loop\|ram"; then
            disk_type="Virtual"
        elif [ -d "/sys/block/$(basename "$base_device")" ]; then
            # Try to detect if SSD or HDD
            if [ -f "/sys/block/$(basename "$base_device")/queue/rotational" ]; then
                if [ "$(cat "/sys/block/$(basename "$base_device")/queue/rotational")" = "0" ]; then
                    # It's an SSD, try to detect if NVMe
                    if echo "$base_device" | grep -q "nvme"; then
                        disk_type="NVMe SSD"
                    else
                        disk_type="SSD"
                    fi
                else
                    disk_type="HDD"
                fi
            fi
        fi
        
        if [ "$disk_type" != "Unknown" ]; then
            printf "  %-18s %-10s %-10s %-10s %-10s %s\n" "$mount_point" "$total" "$used" "$avail" "$use_percent" "[$disk_type]"
        else
            printf "  %-18s %-10s %-10s %-10s %s\n" "$mount_point" "$total" "$used" "$avail" "$use_percent"
        fi
    done
fi

# System uptime
if command -v uptime >/dev/null 2>&1; then
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
    if [ -z "$uptime_str" ]; then
        # Fallback to /proc/uptime
        if [ -f "/proc/uptime" ]; then
            uptime_sec=$(cut -d ' ' -f 1 /proc/uptime | cut -d '.' -f 1)
            
            uptime_days=$((uptime_sec / 86400))
            uptime_hours=$(((uptime_sec % 86400) / 3600))
            uptime_minutes=$(((uptime_sec % 3600) / 60))
            
            uptime_str=""
            if [ "$uptime_days" -gt 0 ]; then
                weeks=$((uptime_days / 7))
                days=$((uptime_days % 7))
                
                if [ "$weeks" -gt 0 ]; then
                    uptime_str="${weeks} week"
                    [ "$weeks" -gt 1 ] && uptime_str="${uptime_str}s"
                    
                    if [ "$days" -gt 0 ]; then
                        uptime_str="${uptime_str}, ${days} day"
                        [ "$days" -gt 1 ] && uptime_str="${uptime_str}s"
                    fi
                else
                    uptime_str="${uptime_days} day"
                    [ "$uptime_days" -gt 1 ] && uptime_str="${uptime_str}s"
                fi
            fi
            
            if [ "$uptime_hours" -gt 0 ]; then
                [ -n "$uptime_str" ] && uptime_str="${uptime_str}, "
                uptime_str="${uptime_str}${uptime_hours} hour"
                [ "$uptime_hours" -gt 1 ] && uptime_str="${uptime_str}s"
            fi
            
            if [ "$uptime_minutes" -gt 0 ] || [ -z "$uptime_str" ]; then
                [ -n "$uptime_str" ] && uptime_str="${uptime_str}, "
                uptime_str="${uptime_str}${uptime_minutes} minute"
                [ "$uptime_minutes" -gt 1 ] && uptime_str="${uptime_str}s"
            fi
        else
            uptime_str="Unknown"
        fi
    fi
    log_info "System uptime" "$uptime_str"
else
    log_info "System uptime" "Unknown"
fi

# OS info - similar to the get_opsy() function in the Python script
if [ -f "/etc/os-release" ]; then
    os_name=$(grep "PRETTY_NAME" /etc/os-release | sed 's/PRETTY_NAME=//' | sed 's/"//g')
    if [ -z "$os_name" ]; then
        os_name=$(grep "^NAME=" /etc/os-release | sed 's/NAME=//' | sed 's/"//g')
        os_version=$(grep "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//' | sed 's/"//g')
        [ -n "$os_version" ] && os_name="$os_name v$os_version"
    fi
elif [ -f "/etc/lsb-release" ]; then
    os_name=$(grep "DESCRIPTION=" /etc/lsb-release | sed 's/DESCRIPTION=//' | sed 's/"//g')
else
    os_name=$(uname -s)
fi
log_info "OS" "${MAGENTA}$os_name${NC}"

# Current Shell
current_shell="$(basename "$SHELL" 2>/dev/null || echo "Unknown")"
log_info "Current Shell" "$current_shell"

# Package Manager
pkg_manager="Unknown"
for pm in apt dnf yum pacman apk zypper; do
    if command -v "$pm" >/dev/null 2>&1; then
        pkg_manager="$pm"
        break
    fi
done
log_info "Package Manager" "$pkg_manager"

# Architecture
arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
    arch_full="x86_64 (64bit)"
elif [ "$arch" = "i686" ] || [ "$arch" = "i386" ]; then
    arch_full="$arch (32bit)"
else
    arch_full="$arch"
fi
log_info "Architecture" "$arch_full"

# Kernel
kernel=$(uname -r)
kernel_full="$(uname -s)-$kernel"
log_info "Kernel" "${MAGENTA}$kernel_full${NC}"

# Virtualization
if command -v systemd-detect-virt >/dev/null 2>&1; then
    virt=$(systemd-detect-virt 2>/dev/null)
    [ -z "$virt" ] && virt="none"
else
    virt="none"
    # Manual detection
    if [ -f "/sys/hypervisor/type" ]; then
        virt=$(cat /sys/hypervisor/type)
    elif grep -q "hypervisor" /proc/cpuinfo 2>/dev/null; then
        virt="Virtualized"
    elif dmesg 2>/dev/null | grep -qi "vmware\|qemu\|kvm\|xen\|hyper-v\|virtualbox"; then
        virt="Virtualized"
    elif [ -d "/proc/xen" ]; then
        virt="Xen"
    fi
fi
log_info "Virtualization" "${MAGENTA}$virt${NC}"

# Motherboard information (if available)
if command -v dmidecode >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
    mb_vendor=$(dmidecode -t 2 2>/dev/null | grep -m 1 "Manufacturer:" | sed 's/.*: //')
    mb_model=$(dmidecode -t 2 2>/dev/null | grep -m 1 "Product Name:" | sed 's/.*: //')
    
    if [ -n "$mb_vendor" ] && [ -n "$mb_model" ]; then
        log_info "Motherboard" "$mb_vendor $mb_model"
    fi
fi

# BIOS/UEFI Version (if available)
if command -v dmidecode >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
    bios_vendor=$(dmidecode -t 0 2>/dev/null | grep -m 1 "Vendor:" | sed 's/.*: //')
    bios_version=$(dmidecode -t 0 2>/dev/null | grep -m 1 "Version:" | sed 's/.*: //')
    bios_release=$(dmidecode -t 0 2>/dev/null | grep -m 1 "Release Date:" | sed 's/.*: //')
    
    if [ -n "$bios_vendor" ] && [ -n "$bios_version" ]; then
        log_info "BIOS/UEFI" "$bios_vendor $bios_version ($bios_release)"
    fi
fi

# GPU Information
gpu_info=""

# Try lspci first
if command -v lspci >/dev/null 2>&1; then
    gpu_info=$(lspci 2>/dev/null | grep -i "vga\|3d\|2d" | sed 's/.*: //')
fi

# If not found via lspci, try other methods
if [ -z "$gpu_info" ]; then
    # Check for NVIDIA GPU using nvidia-smi
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
    fi
    
    # Check for integrated Intel GPU
    if [ -z "$gpu_info" ] && grep -q "Intel Corporation" /proc/cpuinfo 2>/dev/null; then
        gpu_info="Intel Integrated Graphics"
    fi
    
    # Check for AMD GPU
    if [ -z "$gpu_info" ] && grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
        if command -v glxinfo >/dev/null 2>&1; then
            amd_gpu=$(glxinfo 2>/dev/null | grep -i "renderer string" | grep -i "amd\|radeon")
            [ -n "$amd_gpu" ] && gpu_info="AMD Integrated Graphics"
        fi
    fi
fi

# If we found GPU info, display it
if [ -n "$gpu_info" ]; then
    log_info "GPU" "${CYAN}$gpu_info${NC}"
    
    # Try to get GPU driver info
    if command -v lspci >/dev/null 2>&1; then
        gpu_driver=$(lspci -k 2>/dev/null | grep -A 3 -i "vga\|3d" | grep "Kernel driver in use" | sed 's/.*: //')
        [ -n "$gpu_driver" ] && log_info "GPU Driver" "$gpu_driver"
    fi
fi

# IPv4 (using ipify.org)
ipv4="Unknown"
if command -v curl >/dev/null 2>&1; then
    ipv4=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "Unknown")
elif command -v wget >/dev/null 2>&1; then
    ipv4=$(wget -qO- --timeout=3 https://api.ipify.org 2>/dev/null || echo "Unknown")
fi
log_info "Public IPv4" "$ipv4"

# IPv6 (using ipify.org)
ipv6="Unknown"
if command -v curl >/dev/null 2>&1; then
    ipv6=$(curl -s --max-time 3 https://api6.ipify.org 2>/dev/null || echo "Unknown")
elif command -v wget >/dev/null 2>&1; then
    ipv6=$(wget -qO- --timeout=3 https://api6.ipify.org 2>/dev/null || echo "Unknown")
fi
log_info "Public IPv6" "$ipv6"

# Hostname - both short and FQDN if available
short_hostname=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "Unknown")
fqdn_hostname=$(hostname -f 2>/dev/null || echo "$short_hostname")

if [ "$short_hostname" = "$fqdn_hostname" ]; then
    log_info "Hostname" "${MAGENTA}$short_hostname${NC}"
else
    log_info "Hostname" "${MAGENTA}$short_hostname${NC} ($fqdn_hostname)"
fi


# Network Interfaces
log_info "Network Interfaces" "Interface stats:"
if command -v ip >/dev/null 2>&1; then
    ip -o link show up 2>/dev/null | grep -v "lo:" | 
    while read -r line; do
        if_name=$(echo "$line" | awk -F': ' '{print $2}')
        
        # Get IP address
        if_ip=$(ip -o -4 addr show dev "$if_name" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
        [ -z "$if_ip" ] && if_ip="No IPv4"

        # Get interface type
        if_type="Unknown"
        if [ -d "/sys/class/net/$if_name/wireless" ]; then
            if_type="Wireless"
        elif [ -d "/sys/class/net/$if_name/bridge" ]; then
            if_type="Bridge"
        elif [ -L "/sys/class/net/$if_name/device/driver" ] && 
             [ -n "$(readlink "/sys/class/net/$if_name/device/driver" 2>/dev/null | grep -i "ethernet")" ]; then
            if_type="Ethernet"
        fi
        
        printf "  %-12s %-20s %-15s %s\n" "$if_name" "$if_ip" "[$if_type]"
    done
fi

# TCP Congestion Control
if [ -f "/proc/sys/net/ipv4/tcp_congestion_control" ]; then
    tcp_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)
    log_info "TCP CC" "$tcp_cc"
fi

# Current Logged-in Users
if command -v who >/dev/null 2>&1; then
    user_count=$(who | wc -l)
    if [ "$user_count" -gt 0 ]; then
        log_info "Logged-in Users" "$user_count user(s)"
    fi
fi

# Container/Virtualization Tools
for container in docker podman lxc; do
    if command -v "$container" >/dev/null 2>&1; then
        container_version=$("$container" --version 2>/dev/null | head -n 1)
        [ -n "$container_version" ] && log_info "Container System" "$container_version"
    fi
done
