#!/bin/sh

# Start OpenVPN in the background
nohup sudo openvpn --config server.conf 2>&1 &

# Wait for the TUN interface to be ready
while ! sudo ip link show tun0 > /dev/null 2>&1; do
    echo "Waiting for tun0 to come up..."
    sleep 1
done
# Set up routing rules
sudo ip rule add from 10.8.0.0/24 table 10
sudo ip route add 10.8.0.0/24 dev tun0 table 10
