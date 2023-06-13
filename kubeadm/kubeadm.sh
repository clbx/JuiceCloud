#!/bin/bash

# Variables

CRIO_VERSION=1.25

echo "REMOVE ZRAM AND REBOOT FIRST"
echo "dnf remove -y zram-generator-defaults"

read 

# kubeadm fedora install script
echo "-- Installing Packages"
dnf update -y
dnf install -y vim net-tools bridge-utils nfs-utils

echo "-- Enabled firewall rules"
firewall-cmd --zone=public --add-port=10250/tcp --permanent
firewall-cmd --reload

echo "-- Install iscsi"
dnf -y --setopt=tsflags=noscripts install iscsi-initiator-utils
echo "InitiatorName=$(/sbin/iscsi-iname)" > /etc/iscsi/initiatorname.iscsi
systemctl enable iscsid
systemctl start iscsid

echo "-- Disable Swap"
swapoff -a

echo "Enable IpTables Bridged Traffic"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo "-- disable selinux"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


echo "-- Install CRI-O"

dnf module -y enable cri-o:$CRIO_VERSION
dnf install -yq cri-o
systemctl enable crio
systemctl start crio

echo "-- Add kubernetes repo"

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

echo "-- Install kubelet, kubeadm, and kubectl"

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet
systemctl start kubelet


echo "-- Install Keepalived and haproxy"
dnf install -y haproxy keepalived


echo "Basic install finished. Configure keepalived and haproxy, add to cluster"