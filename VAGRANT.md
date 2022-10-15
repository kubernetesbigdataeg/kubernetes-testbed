# Vagrant Installation

According with [Vagrant Libvirt Documentation](https://vagrant-libvirt.github.io/vagrant-libvirt/installation.html):

> Due to the number of issues encountered around compatibility between the ruby 
runtime environment that is part of the upstream vagrant installation and the 
library dependencies of libvirt that this project requires to communicate with 
libvirt, there is a docker image built and published.
This should allow users to execute vagrant with vagrant-libvirt without needing 
to deal with the compatibility issues, though you may need to extend the image 
for your own needs should you make use of additional plugins.

Long story short, put in your ```.bashrc``` this shell function:

```
vagrant(){
 podman run -it --rm --name vagrantlibvirt \
    -e LIBVIRT_DEFAULT_URI \
    -v /var/run/libvirt/:/var/run/libvirt/ \
    -v ~/.vagrant.d/boxes:/vagrant/boxes \
    -v ~/.vagrant.d/data:/vagrant/data \
    -v ~/.vagrant.d/tmp:/vagrant/tmp \
    -v $(realpath "${PWD}"):${PWD} \
    -w $(realpath "${PWD}") \
    --network host \
    --entrypoint /bin/bash \
    --security-opt label=disable \
    docker.io/vagrantlibvirt/vagrant-libvirt:latest \
    vagrant $@
}
```
