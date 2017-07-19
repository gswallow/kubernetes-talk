# kubernetes-talk
Quick talk to the Indy DevOps group about my recent discovery sessions with Kubernetes (k8s)

## Get started
Check the contents of `env.sh`.  At a minimum, run:

    export AWS_ACCESS_KEY_ID=<my_AWS_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<my_AWS_SECRET_ACCESS_KEY>
    source env.sh
    
If you don't have the aws-sdk-core gem installed, install it with bundler:

    bundle install
    
This repo contains a git submodule (Thanks to Kelsey Hightower!).  Initialize it:

    git submodule update --init

## Pre-requisites to running your own kubernetes cluster
We will stand up our own kubernetes cluster using the [kops](https://github.com/kubernetes/kops/)
tool.  kops requires two or three resources in order to create a fresh kubernetes cluster:

- An S3 bucket.
- A Route53 (or other) hosted zone.
- Optionally, an NS record delegating the hosted zone to a separate set of namservers than its 
  parent zone.

We're going to create these resources using Cloudformation.  The intent is to demonstrate how to tie a kubernetes cluster into a pre-existing VPC.  See the cloudformation directory for an example VPC and S3 bucket.

To create these resources, run: 

    cd cloudformation && ./launch.sh
    
Once the VPC gets spun up (about three minutes), link your two zones together with an NS record:

    cd cloudformation && bundle exec ./create-ns-records.rb

### Let's get sidetracked: minikube

Rather than crack jokes through what would be three awkward minutes of silence, let's spin up a local kubernetes cluster using [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/).

    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.20.0/minikube-darwin-amd64 \
     && chmod +x minikube && sudo mv minikube /usr/local/bin/
    minikube start --vm-driver=virtualbox
    kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
    kubectl expose deployment hello-minikube --type=NodePort
    minikube service hello-minikube --url
    curl $(minikube service hello-minikube --url)

Then let's tear it down:

    minikube stop
    # for fun here, you could restart it but meh
    minikube delete

#### Contexts

Switch between k8s clusters by using the `kubectl config use-context` command: 

    kubectl config use-context k8s.gregonaws.net
    
## Launching a cluster

There are two []network topologies](https://github.com/kubernetes/kops/blob/master/docs/topology.md): public and private.  We will launch a private kubernetes cluster, meaning that all of the nodes -- masters and minions -- will be located within private subnets.  This is the most secure way to create your own kubernetes cluster.

We will demonstrate how to launch a cluster [within our own VPC](https://github.com/kubernetes/kops/blob/master/docs/run_in_existing_vpc.md).  Currently there's a bug in kops 1.6.x where it ignores the tags it's supposed to use to identify shared subnets, so we'll work around that:

    cd k8s && eval $(./kcc.sh)
    bundle exec ./get-subnets.rb

Copy the output of `get-subnets.rb`, and then run:

    kops edit cluster k8s.gregonaws.net

Replace the contents of the "subnets" key with the output from `get-subnets.rb`.

`kcc.sh` is simply a wrapper around `kops create cluster`.  The `kops create cluster` command will lay out a cluster in the S3 bucket.  In order to actually create the resources comprising the cluster, we need to run the `kops update cluster` command:

    kops update cluster k8s.gregonaws.net --yes
    
This command will actually provision the resources and bootstrap each node.

### Inspect the cluster

    kubectl get nodes
    kubectl -n kube-system get pods
    
### Install add-ons
kops supports [add-ons](https://github.com/kubernetes/kops/blob/master/docs/addons.md), which include things like monitoring tools and management dashboards.

## Run a very basic app

    kubectl run nginx --image nginx:1.10.0·
    kubectl describe deployments nginx
    kubectl expose deployments nginx --port 80 --type LoadBalancer
    
### Scale a deployment

    kubectl scale --replicas=3 deployment/nginx
    kubectl describe deployments nginx

## Concepts
#### Kubernetes core components
Kubernetes core components include:

| module | location | responsibility |
|--------|----------|----------------|
| apiserver | masters | handles kubectl requests<br>communicates with node kubelets, kube-scheduler, kube-controller-manager|
| kubelet | all | **DOES NOT RUN IN A CONTAINER**<br>starts pods in /etc/kubernetes/manifests<br>|registers itself as a node with the API server<br>sets up the Docker cbr0 bridge interface<br>monitors and restarts pods scheduled by the kube-scheduler|
| kube-proxy | all | forwards ports through iptables |
| etcd | masters | stores configuration, secrets, and pod manifests for retrieval by the API server |
| etcd-events | masters | stores k8s cluster event logs |
| kube-controller-manager | masters | "runs various controllers" |
| kube-scheduler | masters | schedules pods on nodes |
| kube-dns | all | sort of like DNSmasq |
| dns-controller | masters | makes changes to external DNS (e.g. route53) |
| protokube (kops only) | masters | bootstraps etcd, acts as an installation script / config management system |

*note: I have a shallow understanding of k8s components and I am likely wrong on many counts*

#### Pods
A pod is the atomic unit managed by k8s.  It is a namespace, with a single IP address, a set of volumes, and one or more containers that share the volumes / IP address.

#### Secrets

#### Config maps

#### Deployments

#### Services

#### Ingresses(?)

#### Namespaces(??)

#### TODO