cat <<! | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
spec:
    accessModes:
        - ReadWriteOnce
    capacity:
        storage: 5Gi
    nfs:
        server: k8s-dns.kubernetes.lan
        path: /opt/export/pv001
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
spec:
    accessModes:
        - ReadWriteOnce
    capacity:
        storage: 10Gi
    nfs:
        server: k8s-dns.kubernetes.lan
        path: /opt/export/pv002
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv003
spec:
    accessModes:
        - ReadWriteOnce
    capacity:
        storage: 15Gi
    nfs:
        server: k8s-dns.kubernetes.lan
        path: /opt/export/pv003
!
