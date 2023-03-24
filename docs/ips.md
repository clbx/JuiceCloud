### JuiceCloud VLAN 192.168.3.0/24
| IP | Hostname |Device | Notes |
|----|----------|-------|-------|
| 192.168.3.1 | | Gateway | |
| 192.168.3.3 | `ilo.dl380g8.juicecloud.org`| DL380 G8 iLO | |
| 192.168.3.4 | `ilo.dl380g10.juicecloud.org`| DL380 G10 iLO | |
| 192.168.3.5 | `sputnik.juicecloud.org` | Raspberry Pi 4 | DNS Server |
| 192.168.3.6 | | Raspberry Pi 4 | TBD |
| 192.168.3.7 | | Raspberry Pi 4 | TBD |
| 192.168.3.8 | `homeassistant.juicecloud.org` | Raspberry Pi 4 | Home Assistant
| 192.168.3.11 | `pve1.juicecloud.org` | DL380 G8  | Proxmox |
| 192.168.3.40 | `kubernetes.juicecloud.org` | keepalived + HAProxy | In Cluster Load Balancer |
| 192.168.3.50 | `mercury.juicecloud.org` | Optiplex 7050 | Kubernetes Master Node |
| 192.168.3.51 | `artemis.juicecloud.org` | Optiplex 3050 | Kubernetes Worker Node | 
| 192.168.3.52 | `juptier.juicecloud.org` | DL380 G8 | Kubernetes Worker Node VM |
