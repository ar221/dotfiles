#!/bin/bash

echo "========================================="
echo "VM Configuration Pre-Flight Check"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_passed=0
check_failed=0
check_warning=0

# Function to print status
print_status() {
    if [ "$1" == "PASS" ]; then
        echo -e "${GREEN}[✓] $2${NC}"
        ((check_passed++))
    elif [ "$1" == "FAIL" ]; then
        echo -e "${RED}[✗] $2${NC}"
        ((check_failed++))
    else
        echo -e "${YELLOW}[!] $2${NC}"
        ((check_warning++))
    fi
}

echo "1. Checking CPU Information..."
cpu_model=$(lscpu | grep "Model name" | sed 's/Model name: *//')
if [[ "$cpu_model" == *"5900X"* ]] || [[ "$cpu_model" == *"Ryzen 9"* ]]; then
    print_status "PASS" "CPU detected: $cpu_model"
else
    print_status "WARN" "CPU detected: $cpu_model (Expected Ryzen 9 5900X)"
fi

cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
if [ "$cpu_cores" == "24" ]; then
    print_status "PASS" "CPU threads: $cpu_cores (12 cores / 24 threads)"
else
    print_status "FAIL" "CPU threads: $cpu_cores (Expected 24)"
fi

echo ""
echo "2. Checking IOMMU Status..."
if [ -d "/sys/kernel/iommu_groups" ]; then
    iommu_groups=$(find /sys/kernel/iommu_groups -mindepth 1 -maxdepth 1 -type d | wc -l)
    print_status "PASS" "IOMMU enabled ($iommu_groups groups found)"
else
    print_status "FAIL" "IOMMU not enabled or not accessible"
fi

# Check kernel parameters
cmdline=$(cat /proc/cmdline)
if [[ "$cmdline" == *"amd_iommu=on"* ]]; then
    print_status "PASS" "Kernel parameter: amd_iommu=on"
else
    print_status "FAIL" "Missing kernel parameter: amd_iommu=on"
fi

if [[ "$cmdline" == *"iommu=pt"* ]]; then
    print_status "PASS" "Kernel parameter: iommu=pt"
else
    print_status "WARN" "Missing kernel parameter: iommu=pt (recommended)"
fi

echo ""
echo "3. Checking GPU (RX 9070 XT)..."
gpu_check=$(lspci -nn | grep "1002:7550")
if [ -n "$gpu_check" ]; then
    print_status "PASS" "GPU found: $gpu_check"
    
    # Check if GPU is bound to vfio-pci
    gpu_driver=$(lspci -nnk -d 1002:7550 | grep "Kernel driver in use" | awk '{print $5}')
    if [ "$gpu_driver" == "vfio-pci" ]; then
        print_status "PASS" "GPU bound to vfio-pci"
    elif [ "$gpu_driver" == "amdgpu" ]; then
        print_status "WARN" "GPU bound to amdgpu (will be handled by libvirt managed='yes')"
    else
        print_status "WARN" "GPU driver: $gpu_driver"
    fi
else
    print_status "FAIL" "GPU not found (1002:7550)"
fi

gpu_audio_check=$(lspci -nn | grep "1002:ab40")
if [ -n "$gpu_audio_check" ]; then
    print_status "PASS" "GPU Audio found: $gpu_audio_check"
else
    print_status "FAIL" "GPU Audio not found (1002:ab40)"
fi

echo ""
echo "4. Checking vBIOS ROM..."
if [ -f "/var/lib/libvirt/vgabios/vbios.rom" ]; then
    vbios_size=$(stat -c%s "/var/lib/libvirt/vgabios/vbios.rom")
    print_status "PASS" "vBIOS ROM exists (${vbios_size} bytes)"
else
    print_status "FAIL" "vBIOS ROM not found at /var/lib/libvirt/vgabios/vbios.rom"
fi

echo ""
echo "5. Checking Hugepages..."
hugepage_total=$(grep "HugePages_Total:" /proc/meminfo | awk '{print $2}')
hugepage_size=$(grep "Hugepagesize:" /proc/meminfo | awk '{print $2}')

if [ "$hugepage_total" -gt 0 ]; then
    hugepage_mb=$((hugepage_total * hugepage_size / 1024))
    print_status "PASS" "Hugepages allocated: $hugepage_total pages (${hugepage_mb} MB)"
else
    print_status "WARN" "No static hugepages allocated (will be allocated by hook scripts)"
fi

# Check for transparent hugepages
thp_enabled=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
if [[ "$thp_enabled" == *"[always]"* ]] || [[ "$thp_enabled" == *"[madvise]"* ]]; then
    print_status "PASS" "Transparent Hugepages: enabled"
else
    print_status "WARN" "Transparent Hugepages: $thp_enabled"
fi

echo ""
echo "6. Checking Libvirt Hook Scripts..."
if [ -f "/etc/libvirt/hooks/kvm.conf" ]; then
    print_status "PASS" "kvm.conf found"
    memory_conf=$(grep "^MEMORY=" /etc/libvirt/hooks/kvm.conf 2>/dev/null | cut -d'=' -f2)
    if [ -n "$memory_conf" ]; then
        print_status "PASS" "Memory configured: ${memory_conf} MB"
    else
        print_status "WARN" "MEMORY variable not found in kvm.conf"
    fi
else
    print_status "WARN" "kvm.conf not found (hugepage scripts may not work)"
fi

echo ""
echo "7. Checking Required PCI Devices..."
devices=(
    "0b:00.0:GPU"
    "0b:00.1:GPU_Audio"
    "06:00.1:USB_Controller_1"
    "06:00.3:USB_Controller_2"
    "0d:00.3:USB_Controller_3"
    "0d:00.4:Chipset_Audio"
    "05:00.0:NVMe_or_Additional"
)

for device in "${devices[@]}"; do
    addr=$(echo "$device" | cut -d':' -f1-2)
    name=$(echo "$device" | cut -d':' -f3)
    if lspci | grep -q "^$addr"; then
        print_status "PASS" "PCI Device $addr ($name) found"
    else
        print_status "WARN" "PCI Device $addr ($name) not found (may be optional)"
    fi
done

echo ""
echo "8. Checking Virtualization Support..."
if grep -q -E 'svm|vmx' /proc/cpuinfo; then
    virt_type=$(grep -o -E 'svm|vmx' /proc/cpuinfo | head -1)
    print_status "PASS" "CPU virtualization: $virt_type"
else
    print_status "FAIL" "CPU virtualization not enabled in BIOS"
fi

if lsmod | grep -q kvm_amd; then
    print_status "PASS" "KVM AMD module loaded"
elif lsmod | grep -q kvm; then
    print_status "WARN" "KVM module loaded (but not kvm_amd)"
else
    print_status "FAIL" "KVM module not loaded"
fi

echo ""
echo "9. Checking OVMF/UEFI Firmware..."
if [ -f "/usr/share/edk2/x64/OVMF_CODE.4m.fd" ]; then
    print_status "PASS" "OVMF_CODE.4m.fd found"
else
    print_status "FAIL" "OVMF_CODE.4m.fd not found"
fi

if [ -f "/usr/share/edk2/x64/OVMF_VARS.4m.fd" ]; then
    print_status "PASS" "OVMF_VARS.4m.fd found"
else
    print_status "FAIL" "OVMF_VARS.4m.fd not found"
fi

if [ -f "/var/lib/libvirt/qemu/nvram/win11_VARS.fd" ]; then
    print_status "PASS" "VM NVRAM found"
else
    print_status "WARN" "VM NVRAM not found (will be created on first boot)"
fi

echo ""
echo "10. Checking Disk Images..."
if [ -f "/var/lib/libvirt/images/win11.qcow2" ]; then
    disk_size=$(stat -c%s "/var/lib/libvirt/images/win11.qcow2" | numfmt --to=iec-i --suffix=B)
    print_status "PASS" "Primary disk found: $disk_size"
else
    print_status "FAIL" "Primary disk not found: /var/lib/libvirt/images/win11.qcow2"
fi

if [ -f "/mnt/hdd/VMStorage/win11storage.img" ]; then
    storage_size=$(stat -c%s "/mnt/hdd/VMStorage/win11storage.img" | numfmt --to=iec-i --suffix=B)
    print_status "PASS" "Storage disk found: $storage_size"
else
    print_status "FAIL" "Storage disk not found: /mnt/hdd/VMStorage/win11storage.img"
fi

echo ""
echo "11. Checking Network Bridge..."
if ip link show vbir0 &>/dev/null; then
    bridge_state=$(ip link show vbir0 | grep -o "state [A-Z]*" | awk '{print $2}')
    print_status "PASS" "Network bridge 'vbir0' exists (state: $bridge_state)"
else
    print_status "FAIL" "Network bridge 'vbir0' not found"
fi

echo ""
echo "========================================="
echo "Summary:"
echo "========================================="
echo -e "${GREEN}Passed: $check_passed${NC}"
echo -e "${YELLOW}Warnings: $check_warning${NC}"
echo -e "${RED}Failed: $check_failed${NC}"
echo ""

if [ $check_failed -eq 0 ]; then
    echo -e "${GREEN}✓ System is ready for VM optimization!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Backup current VM: virsh dumpxml win11 > ~/win11-backup-\$(date +%Y%m%d).xml"
    echo "2. Stop VM: virsh shutdown win11"
    echo "3. Undefine VM: virsh undefine win11 --nvram"
    echo "4. Apply new config: virsh define win11-optimized.xml"
    echo "5. Start VM: virsh start win11"
else
    echo -e "${RED}⚠ Please fix the failed checks before applying new configuration${NC}"
fi

echo ""
