for i in $(kubectl  get pv --no-headers -o custom-columns=NAME:.metadata.name)
do 
    kubectl get pv $i \
        --no-headers \
        -o=jsonpath='{.metadata.name} mount point {.spec.local.path}{"\n"}'
done
