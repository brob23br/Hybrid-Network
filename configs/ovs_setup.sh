#!/bin/bash
# ============================================================
# Summit Ridge Engineering — OVS (Open vSwitch) Setup Script
# Run inside the OVS appliance after boot in GNS3.
# Interfaces: eth0 = trunk to L3-Switch | eth1 = VLAN10 access
#             eth2 = VLAN20 access       | eth3 = VLAN10 access (2nd host)
# ============================================================

set -e

BRIDGE="br0"

echo "[1/5] Creating OVS bridge..."
ovs-vsctl add-br $BRIDGE

echo "[2/5] Adding trunk port to L3-Core-Switch (eth0)..."
ovs-vsctl add-port $BRIDGE eth0
ovs-vsctl set port eth0 trunks=10,20,30

echo "[3/5] Adding VLAN10 access ports (eth1, eth3) for Engineering PCs..."
ovs-vsctl add-port $BRIDGE eth1
ovs-vsctl set port eth1 tag=10

ovs-vsctl add-port $BRIDGE eth3
ovs-vsctl set port eth3 tag=10

echo "[4/5] Adding VLAN20 access port (eth2) for Admin PC..."
ovs-vsctl add-port $BRIDGE eth2
ovs-vsctl set port eth2 tag=20

echo "[5/5] Bringing up all interfaces..."
ip link set $BRIDGE up
ip link set eth0 up
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up

echo ""
echo "=== OVS Bridge Summary ==="
ovs-vsctl show
echo ""
echo "=== OVS Port VLAN Tags ==="
ovs-vsctl list port eth0 eth1 eth2 eth3 | grep -E "name|tag|trunks"
echo ""
echo "OVS setup complete."
