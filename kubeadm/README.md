# Kubeadm Installation

One day I'll automate this

# 1. Pre-Install Steps

These steps are run on a fresh install of Debian 11. Steps are run as root. 

Install some useful tools + longhorn dependencies.
```
apt update
apt install -y vim net-tools bridge-utils open-iscsi nfs-common
```

Add ``/sbin`` to path 
```bash
# ~/.bashrc
export PATH="/sbin:$PATH"
```
 
```
source ~/.bashrc
```


Disable Swap
```bash
swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
```

Enable iptables bridged traffic

```
echo "Enable IpTables Bridged Traffic"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

```
modprobe overlay
modprobe br_netfilter
```

```
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

```
sysctl --system
```


# 2. Install kube*
Install ``kubelet``,``kubeadm``, and ``kubectl``


Install required packages
``` bash
apt-get update
apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
```

Install kubelet, kubeadm, and kubectl
``` bash
mkdir -p /etc/apt/keyrings/

curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet kubeadm kubectl

# This prevents kubelet, kubeadm, and kubectl being updated with the rest  of the packages.
apt-mark hold kubelet kubeadm kubectl
```

# 3. Install CRI-O
You may install any container runtime here, I had issues with containerd so I chose CRI-O

```bash
export OS=Debian_11
export VERSION=1.26 # Or whatever the current major version of CRI-O is

# Add the CRI-O repositories
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

mkdir -p /usr/share/keyrings

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

# Install CRI-O
apt-get update
apt-get install cri-o cri-o-runc cri-tools -y
apt-mark hold cri-o cri-o-runc cri-tools

# Start CRI-O
systemctl daemon-reload
systemctl enable crio --now
```

# 4. Create HAProxy and keepalived configuration

Install packages:
```
apt-get install -y keepalived haproxy
```

**keepalived**

Using `keepalived.conf` create a file at `/etc/keepalived/keepalived.conf` replace the following values
- `STATE`: MASTER or BACKUP
- `INTERFACE`: The interface being used, probably eth0
- `PRIORITY`: Higher Number = Higher Priority, 101 for control plane & 100 for worker
- `AUTH_PASS`: same as all of the others

**HAProxy**

Using `haproxy.cfg` create a file at `/etc/haproxy/haproxy.cfg` add the servers to the end of the file 

**Start Services**

```
systemctl enable haproxy --now
systemctl enable keepalived --now
```

# 5. Initialize Cluster
```
kubeadm init --control-plane-endpoint=kubernetes.juicecloud.org:6443  --pod-network-cidr=10.0.0.0/16 
```

Once finished a message will print out with join instructions for additional nodes and how to copy the kubeconfig. Take note of the join instruction for additonal nodes.

# 5. Install Calico
You can choose any CNI Plugin, Calico seemed like it was the simplest to deal with and also had capability for BGP memes.

Install the operator:
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
```

Edit `calico.yaml` to use the appropriate encapsulation and CIDR of your cluster

Apply the Calico resources:
```
kubectl apply -f calico.yaml
```

# 6. Remove the control-plane taint. 
By default no pods are scheduled to the control nodes. This is technically the proper way to do it, but in a homelab it's probably more beneifical to allow scheduling to control nodes since your cluster is not going to be doing nearly as much as a in-use production cluster and I don't have the hardware/desire to pay for the power for machines that arn't doing much work. 

You do need to be careful to not overwork your cluster though or bad things will happen.

``kubectl taint nodes <node> node-role.kubernetes.io/control-plane:NoSchedule-``


# Adding More Nodes
For both worker and control nodes repeat steps 1-3. and once CRI-O is running the node can be added using ``kubeadm join``. 

``kubeadm init`` has options to upload the certs to the cluster to make it easier to join nodes. This can also be done after the cluster is created by running:

```
kubeadm init phase upload-certs --upload-certs
```

This will upload all of the certs required and delete them in 2 hours. The output of that command will give you a certificate key. add the ``--certificate-key`` argument of the ``kubeadm join`` command to automatically download the certs.


If you missed the command you can print it out again with 
```
kubeadm token create --print-join-command
```

```
kubeadm join <control node>:6443 --token <token>  --discovery-token-ca-cert-hash <ca-cert hash> --certificate-key <certificate key> (--control-plane)
```


# All Done!

All finished. If you're following along specifically for my cluster and setup, check out the ``/base`` directory since that holds a lot of the underlying services that I use to facilitate the applications you probably want to set up. 

Things like:
- A method for persistent storage `/base/longhorn`
- A load balancer `/base/metallb` and ingress controller `/base/ingress-nginx`