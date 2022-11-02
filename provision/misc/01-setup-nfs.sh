sudo yum install rpcbind nfs-utils  -y

#sudo mkdir -p /opt/export/pv00{1..9}
#
#for volume in pv00{1..9} ; do
#   echo "/opt/export/${volume} 10.0.0.2/24(rw,sync,all_squash,no_wdelay)" | sudo tee -a /etc/exports;
#done

# Notes: With NFS storage class (dynamic provisioning) we don't need
# create the exported folders, the storage class will create the exported
# folders on the fly.
#
# Notes: no_root_squash: This option basically gives authority to the root 
# user on the client to access files on the NFS server as root. And this can 
# lead to serious security implications. However for applications such as
# MySQL the container has to chown files, and this configuraion is a constrain
# for easy configuration (non production)
sudo mkdir /mnt/export
sudo chmod 777 /mnt/export
echo "/mnt/export 10.0.0.2/24(rw,sync,no_root_squash,no_wdelay)" | sudo tee -a /etc/exports
sudo systemctl start rpcbind nfs-server nfs-lock nfs-idmap
sudo systemctl enable nfs-server 

# Check:
# sudo exportfs -s
# sudo showmount -e

# sudo showmount -e k8s-dns.kubernetes.lan
# sudo mount k8s-dns.kubernetes.lan:/opt/export/pv001 /srv


