# ~/.config/fish/functions/whatsmyip.fish (smart version - fixed)
function whatsmyip --description "Show internal and external IP addresses"
    # Try to find the active network interface automatically
    set interface ""
    
    if command -q ip
        # Get the default route interface
        set interface (ip route | grep '^default' | awk '{print $5}' | head -1)
        
        if test -n "$interface"
            echo -n "Internal IP ($interface): "
            # Fixed: Better parsing to get just the IP address
            ip addr show $interface | grep "inet " | grep -v "inet6" | awk '{print $2}' | cut -d/ -f1 | head -1
        else
            echo -n "Internal IP: "
            echo "No active interface found"
        end
    else
        # Fallback to ifconfig method - try common interfaces
        for iface in enp4s0 wlan0 eth0 ens33 eno1
            if ifconfig $iface >/dev/null 2>&1
                set interface $iface
                break
            end
        end
        
        if test -n "$interface"
            echo -n "Internal IP ($interface): "
            ifconfig $interface | grep "inet " | grep -v "inet6" | awk '{print $2}' | head -1
        else
            echo -n "Internal IP: "
            echo "No active interface found"
        end
    end

    # External IP Lookup
    echo -n "External IP: "
    curl -s ifconfig.me
    echo # Add newline
end
