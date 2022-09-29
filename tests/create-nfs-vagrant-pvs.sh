for volume in {1..20}; do
    cat <<! | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv00${volume}
spec:
    accessModes:
        - ReadWriteOnce
    capacity:
        storage: 20Gi
    nfs:
        server: k8s-dns.kubernetes.lan
        path: /opt/export/pv00${volume}
!
done
