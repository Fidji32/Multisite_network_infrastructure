rm -rf /etc/containerd/*
systemctl restart containerd

kubeadm init --control-plane-endpoint 192.168.0.2:6443 \
  --pod-network-cidr 192.168.100.0/24

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
