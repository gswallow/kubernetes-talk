# kubernetes-talk
Quick talk to the Indy DevOps group about discovery sessions with Kubernetes

## Get started

Check the contents of env.sh.  At a minimum, run:

    export AWS_ACCESS_KEY_ID=<my_AWS_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<my_AWS_SECRET_ACCESS_KEY>
    export org=<arbitrary>
    source env.sh

## things

    kubectl get nodes
    kubectl -n kube-system get pods
    kubectl run nginx --image nginx:1.10.0·
    kubectl describe deployments nginx
    kubectl expose deployments nginx --port 80 --type LoadBalancer
    kubectl scale --replicas=3 deployment/nginx
    kubectl describe deployments nginx
