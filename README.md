# Kubernetes Vagrant Libvirt Testbed Environment

This is the environment in which we test this project, the idea is to have a 
simple environment that allows us to eliminate as much as possible the moving 
parts that can interfere with our objectives. We will complicate the environment 
as we need more specialized components. In the following section we outline the 
architecture of this virtual environment.

Vagrant installation notes [here](VAGRANT.md).

# Big Picture

# Technology used in this testbed
## Kubeadm

Kubeadm is a tool built to provide kubeadm init and kubeadm join as 
best-practice "fast paths" for creating Kubernetes clusters. We are
using kubeadm as the basis of all deployments will make it easier to 
create conformant clusters.

The kubeadm version matches the Kubernetes version realeasing:
https://github.com/kubernetes/kubernetes/releases

Kubeadm is an "in-tree" development within kubernetes source code.
https://github.com/kubernetes/kubernetes/tree/master/cmd/kubeadm

## CRI: cri-o version

The CRI-O container engine provides a stable, more secure, and performant 
platform for running Open Container Initiative (OCI) compatible runtimes. 
You can use the CRI-O container engine to launch containers and pods by 
engaging OCI-compliant runtimes like runc, the default OCI runtime, or 
Kata Containers. CRI-O’s purpose is to be the container engine that 
implements the Kubernetes Container Runtime Interface (CRI) for CRI-O 
and Kubernetes follow the same release cycle and deprecation policy. 

CRI-O’s stability comes from the facts that it is developed, tested, and 
released in tandem with Kubernetes major and minor releases and that it 
follows OCI standards. For example, CRI-O 1.11 aligns with Kubernetes 1.11. 
The scope of CRI-O is tied to the Container Runtime Interface (CRI). CRI 
extracted and standardized exactly what a Kubernetes service (kubelet) 
needed from its container engine. The CRI team did this to help stabilize 
Kubernetes container engine requirements as multiple container engines 
began to be developed.

For more information visit the Kubernetes versioning documentation. CRI-O 
follows the Kubernetes release cycles with respect to its minor versions 
(1.x.0). Patch releases (1.x.y) for CRI-O are not in sync with those from 
Kubernetes, because those are scheduled for each month, whereas CRI-O provides 
them only if necessary. If a Kubernetes release goes End of Life, then the 
corresponding CRI-O version can be considered in the same way.

This means that CRI-O also follows the Kubernetes n-2 release version skew 
policy when it comes to feature graduation, deprecation or removal. This also 
applies to features which are independent from Kubernetes.



## CNI: Flannel

In this lab we will use as CNI the Flannel project, the CNI is independent of 
our tests in the first instance. However, we use this one for simplicity and we 
will leave more sophisticated CNIs for future tests.

kube-flannel.yaml has some features that aren't compatible with older versions 
of Kubernetes, though flanneld itself should work with any version of Kubernetes.

## Manual Steps

```
sudo kubeadm init \
        --control-plane-endpoint=k8s-master.kubernetes.lan \
        --upload-certs \
        --apiserver-advertise-address=10.0.0.3 \
        --pod-network-cidr 10.244.0.0/16
```

```
sudo kubeadm join k8s-master.kubernetes.lan:6443 --token <TOKEN_GIVEN_IN_INIT> \
        --discovery-token-ca-cert-hash <HASH_GIVEN_IN_INIT>
```

```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

```
[root@k8s-master ~]# kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes
NAME                          STATUS   ROLES           AGE     VERSION
k8s-master.kubernetes.lan     Ready    control-plane   7m22s   v1.24.6
k8s-worker01.kubernetes.lan   Ready    <none>          5m30s   v1.24.6
k8s-worker02.kubernetes.lan   Ready    <none>          5m3s    v1.24.6
k8s-worker03.kubernetes.lan   Ready    <none>          4m39s   v1.24.6
k8s-worker04.kubernetes.lan   Ready    <none>          4m15s   v1.24.6
```

```
[root@k8s-master ~]# kubectl --kubeconfig /etc/kubernetes/admin.conf get pod -A
NAMESPACE      NAME                                                READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-gvmjw                               1/1     Running   0          2m57s
kube-flannel   kube-flannel-ds-hpjrt                               1/1     Running   0          2m57s
kube-flannel   kube-flannel-ds-ppms7                               1/1     Running   0          2m57s
kube-flannel   kube-flannel-ds-r6vzp                               1/1     Running   0          2m57s
kube-flannel   kube-flannel-ds-wpkpt                               1/1     Running   0          2m57s
kube-system    coredns-6d4b75cb6d-jnrrm                            1/1     Running   0          7m35s
kube-system    coredns-6d4b75cb6d-qh7mj                            1/1     Running   0          7m35s
kube-system    etcd-k8s-master.kubernetes.lan                      1/1     Running   0          7m49s
kube-system    kube-apiserver-k8s-master.kubernetes.lan            1/1     Running   0          7m49s
kube-system    kube-controller-manager-k8s-master.kubernetes.lan   1/1     Running   0          7m50s
kube-system    kube-proxy-5xstz                                    1/1     Running   0          7m35s
kube-system    kube-proxy-67zh7                                    1/1     Running   0          5m10s
kube-system    kube-proxy-b645r                                    1/1     Running   0          5m34s
kube-system    kube-proxy-mmx9w                                    1/1     Running   0          6m1s
kube-system    kube-proxy-wjr5j                                    1/1     Running   0          4m46s
kube-system    kube-scheduler-k8s-master.kubernetes.lan            1/1     Running   0          7m50s
```
