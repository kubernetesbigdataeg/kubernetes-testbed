sudo mkdir -p /opt/export/pv00{1..9}

for volume in pv00{1..9} ; do
    echo "/opt/export/${volume} 10.0.0.2/24(rw,sync,all_squash,no_wdelay)" | sudo tee -a /etc/exports;
done

sudo systemctl start rpcbind nfs-server nfs-lock nfs-idmap
sudo systemctl enable nfs-server 

# Check:
# sudo exportfs -s
# sudo showmount -e

# sudo showmount -e k8s-dns.kubernetes.lan
# sudo mount k8s-dns.kubernetes.lan:/opt/export/pv001 /srv


