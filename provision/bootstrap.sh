#
# VERSION NOTES:
# For checking CRI-O available versions take a look to:
# https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/
#
# For checking Kubeadm available versions take a look to:
# https://github.com/kubernetes/kubernetes/releases
# https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64

# kubeadm version
KUBEADM_VERSION=1.24.6

# cri-o version
CRIO_MAYOR_MINOR=1.24
CRIO_PATCH_LEVEL=3
OS=CentOS_7
CRIO_VERSION=${CRIO_MAYOR_MINOR}.${CRIO_PATCH_LEVEL}

export KUBEADM_VERSION CRIO_MAYOR_MINOR CRIO_VERSION

function kernel_tunning() {
    echo "kernel tunning"

    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    sudo swapoff -a
    sudo sed -i '/swap/s/^/#/' /etc/fstab

    echo $(hostname).kubernetes.lan | sudo tee /etc/hostname
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

    sudo yum install cri-o -y -q
    sudo systemctl stop crio
    sudo rm -fr /etc/cni/net.d/*
    sudo systemctl restart crio
    sudo systemctl daemon-reload
    sudo systemctl enable crio --now
}

function bootstrap_dns() {
    echo "Kubernetes external DNS bootstrapping."
    echo "installing bind ..."
    sudo yum install bind -y --quiet 2> /dev/null
    echo "setting up bind ..."

    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    DOMAIN="kubernetes.lan"

    DNS=k8s-dns
    MASTER=k8s-master
    WORKER01=k8s-worker01
    WORKER02=k8s-worker02
    WORKER03=k8s-worker03
    WORKER04=k8s-worker04

    HOST_DNS="$DNS.$DOMAIN"
    HOST_MASTER="$MASTER.$DOMAIN"
    HOST_WORKER01="$WORKER01.$DOMAIN"
    HOST_WORKER02="$WORKER02.$DOMAIN"
    HOST_WORKER03="$WORKER03.$DOMAIN"
    HOST_WORKER04="$WORKER04.$DOMAIN"

    # 10.0.0.0/24 10.0.0.255
    IP_DNS="10.0.0.2"
    IP_DNS_INV="2"
    IP_MASTER="10.0.0.3"
    IP_MASTER_INV="3"
    IP_WORKER01="10.0.0.4"
    IP_WORKER01_INV="4"
    IP_WORKER02="10.0.0.5"
    IP_WORKER02_INV="5"
    IP_WORKER03="10.0.0.6"
    IP_WORKER03_INV="6"
    IP_WORKER04="10.0.0.7"
    IP_WORKER04_INV="7"

    IP_INV="0.0.10"
    IP_REV="10.0.0"

    sudo mkdir -p /etc/named/zones
    sudo mkdir -p /etc/dhcp

sudo tee /etc/named.conf <<! 
options {
    listen-on port 53 { any; };
    directory   "/var/named";
    dump-file   "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    querylog yes;
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

/* 
 * custom
 */
include "/etc/named/named.conf.local";
!

sudo tee /etc/named/named.conf.local <<! 
zone "${DOMAIN}" IN {
    type master;
    file "/etc/named/zones/db.${DOMAIN}"; 
};

zone "${IP_INV}.in-addr.arpa" IN {
    type master;
    file "/etc/named/zones/db.${IP_REV}"; 
};
!

sudo tee /etc/named/zones/db.${DOMAIN} <<!
\$TTL    604800
@       IN      SOA     ${HOST_DNS}. admin.${DOMAIN}. (
             3          ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL

; name servers - NS records
    IN      NS      ${HOST_MN}.

; name servers - A records
${HOST_DNS}.   IN      A       ${IP_DNS}

; 10.0.0.0/24 - A records
${HOST_MASTER}.  IN A ${IP_MASTER}
${HOST_WORKER01}.  IN A ${IP_WORKER01}
${HOST_WORKER02}.  IN A ${IP_WORKER02}
${HOST_WORKER03}.  IN A ${IP_WORKER03}
${HOST_WORKER04}.  IN A ${IP_WORKER04}
!

sudo tee /etc/named/zones/db.${IP_REV} <<!
\$TTL 604800 ; 1 week
@ IN SOA ${HOST_DNS}. admin.${DOMAIN}. (
    3         ; Serial
    604800    ; Refresh
    86400     ; Retry
    2419200   ; Expire
    604800 )  ; Negative Cache TTL

; name servers
@    IN      NS     ${HOST_DNS}. 

; PTR Records
${IP_DNS_INV}     IN        PTR     ${HOST_DNS}. 
${IP_MASTER_INV} IN        PTR     ${HOST_MASTER}.     
${IP_WORKER01_INV} IN        PTR     ${HOST_WORKER01}.     
${IP_WORKER02_INV} IN        PTR     ${HOST_WORKER02}.     
${IP_WORKER03_INV} IN        PTR     ${HOST_WORKER03}.     
${IP_WORKER04_INV} IN        PTR     ${HOST_WORKER04}.     
!

sudo tee /etc/dhcp/dhclient.conf <<!
# The custom DNS server IP
prepend domain-name-servers ${IP_DNS};
!
    echo "starting bind ..."
    sudo systemctl restart named
    sudo systemctl enable named
    sudo systemctl restart NetworkManager
    echo "done."
}

function bootstrap_kerberos() {
    sudo yum install krb5-server krb5-libs krb5-workstation -y
}

function bootstrap_nfs() {
    sudo mkdir /mnt/export
    sudo chmod 777 /mnt/export
    echo "/mnt/export 10.0.0.2/24(rw,sync,all_squash,no_wdelay)" | sudo tee -a /etc/exports
    sudo systemctl start rpcbind nfs-server nfs-lock nfs-idmap
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
    install_dhclient
    install_kubelet
}

function install_dhclient() {
    sudo tee /etc/dhcp/dhclient.conf <<!
# The custom DNS server IP
prepend domain-name-servers 10.0.0.2;
!
    sudo systemctl restart NetworkManager
}

function install_packages() {
    sudo yum --quiet install \
        vim \
        tree \
        nfs-utils\
        rpcbind \
        bind-utils -y 2> /dev/null
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

case $(hostname) in
  k8s-dns)
    log "WORKING IN $(hostname)"
    install_packages 
    bootstrap_dns
    bootstrap_nfs
    bootstrap_kerberos
    ;;
  k8s-master)
    log "WORKING IN $(hostname)"
    install_packages 
    bootstrap_host master
    ;;
  k8s-worker*)
    log "WORKING IN $(hostname)"
    install_packages 
    bootstrap_host worker
    setup_local_storage
    ;;
  *)
    echo "wtf!"
    exit 1
    ;;
esac
