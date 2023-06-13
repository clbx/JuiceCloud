# Remove Node from Cluster

1. Drain node ``kubectl drain node <node>``
2. Delete node ``kubectl delete node <node>``
3. Kubeadm reset ``kubeadm reset``