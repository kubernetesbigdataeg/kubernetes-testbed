#
# VERSION NOTES:
# For checking CRI-O available versions take a look to:
# https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/
#
# For checking Kubeadm available versions take a look to:
# https://github.com/kubernetes/kubernetes/releases
# https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64

# kubeadm version
KUBEADM_VERSION=1.22.15

# cri-o version
CRIO_MAYOR_MINOR=1.24
CRIO_PATCH_LEVEL=3
OS=CentOS_8
CRIO_VERSION=${CRIO_MAYOR_MINOR}.${CRIO_PATCH_LEVEL}

export KUBEADM_VERSION CRIO_MAYOR_MINOR CRIO_VERSION

function install_packages() {
    sudo dnf --quiet install \
        vim \
        tree \
        nfs-utils\
        rpcbind \
        iproute-tc \
        bind-utils -y 2> /dev/null
}

function kernel_tunning() {
    echo "kernel tunning"

    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    sudo swapoff -a
    sudo sed -i '/swap/s/^/#/' /etc/fstab

    #echo $(hostname).kubernetes.lan | sudo tee /etc/hostname

    sudo systemctl restart systemd-hostnamed

    sudo modprobe br_netfilter
    sudo modprobe overlay

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

    sudo sysctl --system

    #
    # CRI-O
    #
    sudo curl -L -o \
        /etc/yum.repos.d/kubic-libcontainers.repo \
        https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo

    sudo curl -L -o \
        /etc/yum.repos.d/kubic-libcontainers-cri-o.repo \
        https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${CRIO_MAYOR_MINOR}:/${CRIO_VERSION}/${OS}/devel:kubic:libcontainers:stable:cri-o:${CRIO_MAYOR_MINOR}:${CRIO_VERSION}.repo

    sudo dnf install cri-o -y -q
    sudo systemctl stop crio
    sudo rm -fr /etc/cni/net.d/*
    sudo systemctl restart crio
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now
}

function bootstrap_nfs() {
    sudo mkdir /mnt/export
    sudo chmod 777 /mnt/export
    echo "/mnt/export 10.0.0.2/24(rw,sync,all_squash,no_wdelay)" | sudo tee -a /etc/exports
    sudo systemctl start nfs-server
    sudo systemctl enable nfs-server 
}

#
# To avoid GPG connection problems I have just disabled it
#
function install_kubelet() {
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    sudo yum install -y -q kubelet-${KUBEADM_VERSION} \
        kubeadm-${KUBEADM_VERSION} \
        kubectl-${KUBEADM_VERSION} \
        --disableexcludes=kubernetes

    sudo systemctl enable --now kubelet
}

function bootstrap_host() {
    echo "kubernetes host $1 bootstrapping."
    kernel_tunning
    install_kubelet
}

function setup_local_storage() {
    for i in $(lsblk -l | grep -v -E "vda|NAME" | cut -d' ' -f1); do 
        DISK_UUID=$(hostname -s)
        sudo mkfs.xfs /dev/$i
        sudo mkdir -p /mnt/disks/${DISK_UUID}_${i}
        sudo mount /dev/$i /mnt/disks/${DISK_UUID}_${i}
        echo "/dev/$i /mnt/disks/${DISK_UUID}_${i} xfs rw,seclabel,relatime,attr2,inode64,noquota 0 0" | sudo tee -a /etc/fstab
    done
}

function log() {
    echo "##################### .${1}."
}

case $1 in
  master)
    log "master installation WORKING IN $(hostname)"
    install_packages 
    bootstrap_nfs
    bootstrap_host master
    ;;
  worker)
    log "worker installation WORKING IN $(hostname)"
    install_packages 
    bootstrap_host worker
    ;;
  *)
    echo "wtf! what is't $1!"
    exit 1
    ;;
esac
