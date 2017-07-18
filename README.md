# kubernetes-talk
Quick talk to the Indy DevOps group about discovery sessions with Kubernetes

## things

    kubectl get nodes
    kubectl -n kube-system get pods
    kubectl run nginx --image nginx:1.10.0·
    kubectl describe deployments nginx
    kubectl expose deployments nginx --port 80 --type LoadBalancer
    kubectl scale --replicas=3 deployment/nginx
    kubectl describe deployments nginx
