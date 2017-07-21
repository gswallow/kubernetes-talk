# kubernetes-talk
Quick talk to the Indy DevOps group about my recent discovery sessions with Kubernetes (k8s)

## Get started
Check the contents of `env.sh`.  At a minimum, run:

    export AWS_ACCESS_KEY_ID=<my_AWS_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<my_AWS_SECRET_ACCESS_KEY>
    source env.sh
    
If you don't have the aws-sdk-core gem installed, install it with bundler:

    bundle install
    

## Prerequisites to running your own kubernetes cluster
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

    kubectl config use-context k8s.$public_domain
    
## Launching a cluster

There are two [network topologies](https://github.com/kubernetes/kops/blob/master/docs/topology.md): public and private.  We will launch a private kubernetes cluster, meaning that all of the nodes -- masters and minions -- will be located within private subnets.  Kubernetes will create an ELB that provides access to the API server and a bastion SSH host, if configured.  This is the most secure way to create your own kubernetes cluster.

We will demonstrate how to launch a cluster [within our own VPC](https://github.com/kubernetes/kops/blob/master/docs/run_in_existing_vpc.md).  Currently there's a bug in kops 1.6.x where it ignores the tags it's supposed to use to identify shared subnets, so we'll work around that.

Remember to create the NS records delegating k8s.$public_domain to different nameservers:

    bundle exec ./create-ns-records.rb
    cd ../k8s && eval $(./kcc.sh)
    bundle exec ./get-subnets.rb

Copy the output of `get-subnets.rb`, and then run:

    kops edit cluster k8s.$public_domain

Optionally, add the contents of the "bugfix" file, after "etcdClusters," in the in-memory copy of the cluster maniftest.  This enables an alpha version of the batch API, which is required to run cron jobs.  See [https://github.com/kubernetes/kops/issues/618](https://github.com/kubernetes/kops/issues/618).

Replace the contents of the "subnets" key with the output from `get-subnets.rb`.

`kcc.sh` is simply a wrapper around `kops create cluster`.  The `kops create cluster` command will lay out a cluster in the S3 bucket.  In order to actually create the resources comprising the cluster, we need to run the `kops update cluster` command:

    kops update cluster k8s.$public_domain --yes
    
This command will actually provision the resources and bootstrap each node.

### Inspect the cluster

    kubectl get nodes
    kubectl describe node <X>
    kubectl -n kube-system get pods

**An interesting troubleshooting tip is to get events:**

    kubectl get events
    
### Install add-ons
kops supports [add-ons](https://github.com/kubernetes/kops/blob/master/docs/addons.md), which include things like monitoring tools and management dashboards.

## Concepts
### Kubernetes components
Kubernetes core components include:

| module | location | responsibility |
|--------|----------|----------------|
| apiserver | masters | handles kubectl (UI) requests<br>central point of contact for all master services<br>communicates with kubelets, pods (logging, kubectl exec sessions, etc.)|
| kubelet | all | **DOES NOT RUN IN A CONTAINER**<br>starts pods in /etc/kubernetes/manifests<br>registers itself as a node with the API server<br>sets up the Docker cbr0 bridge interface<br>monitors and restarts pods scheduled by the kube-scheduler|
| kube-proxy | all | forwards ports for containers through iptables |
| etcd | masters | stores configuration and secrets for retrieval by the API server |
| etcd-events | masters | stores k8s cluster event logs |
| kube-controller-manager | masters | "runs various controllers" |
| kube-scheduler | masters | schedules pods on nodes |
| kube-dns | all | sort of like DNSmasq |
| dns-controller | masters | makes changes to external DNS (e.g. route53) |
| cloud-controller-manager | masters | creates EBS volumes, adds routes to routing tables, etc. |
| protokube (kops only) | masters | bootstraps etcd, acts as an installation script / config management system |

*note: I have a shallow understanding of k8s components and I am likely wrong on many counts*

### Objects

#### Pods
**You will likely not manage pods directly.**

A pod is the smallest, simplest unit managed by k8s.  It consists of one or more application containers, a single IP address in its own network namespace, volumes which are shared by all containers in the pod, and options on how to run each container in the pod.

Usually, you will run just one container in a pod.

"In general, users shouldn’t need to create pods directly. They should almost always use controllers (e.g., Deployments), even for singletons." ([source](https://kubernetes.io/docs/concepts/workloads/pods/pod/))

##### Aliveness and readiness tests
[See here](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

#### Secrets
[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) can be used in two ways:

- As a volume, which can be mounted by a container in a pod
- By kubelet, when pulling images for a pod

Honestly, secrets aren't really that secure.  Then again, nothing in the container age is secure.

#### Config maps
Config maps are like secrets, except they're not in anyway secret.  You mount a config map like you would mount a volume in a container.

#### Deployments
The [deployment object](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) is the most common object you will work with on a k8s cluster.

Provides a spec for [replicasets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) / [replication controllers](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/), and pods.  

Common management tasks include:

  - creating a deployment
  - updating the deployment
  - rolling back the deployment
  - scaling the deployment
  - pausing the deployment (putting several fixes in place and pausing updates, or having a bad day)

#### Jobs
Jobs control pods that are expected to run once and die.

    cd ../examples/jobs
    kubectl create -f ./pi.yaml
    kubectl describe jobs/pi
    pods=$(kubectl get pods  --show-all --selector=job-name=pi --output=jsonpath={.items..metadata.name})
    kubectl logs $pods

#### Cron jobs
Cron jobs are what they sound like: jobs that run once or repeatedly at a specified time.

    kubectl create -f cronpi.yaml
    kubectl describe cronjob cronpi
    for job in $(kubectl get jobs -a --output=jsonpath='{.items..labels..job-name}') ; do \
     echo $job ;\
     echo ;\
     pod=$(kubectl get pods  --show-all --selector=job-name=$job --output=jsonpath={.items..metadata.name}) ;\
     kubectl logs $pod ;\
     done  
     
#### Daemonsets
Daemonsets control pods that are supposed to run on every single node, e.g. a monitoring agent, log collector, or clustered storage daemon (e.g. Ceph, glusterFS).

#### Services
Because pods are ephemeral, their IP addresses may change.  [Services](https://kubernetes.io/docs/concepts/services-networking/service/) tie pods to cluster IPs by the pods' selectors (labels) in one of three modes:

- userspace
- iptables (layer 4; requires readiness probes for each pod in a deployment to be useful)
- "ingress" (layer 7)

Publishing a service is done through:

| Publishing mechanism | How it works |
|----------------------|--------------|
|ClusterIP | Exposes the service on a cluster-internal IP.  The service is only reachable from within the cluster. |
| NodePort | Exposes the service on each node's IP at a static port.  Automatically creates a ClusterIP and forwards TCP traffic through either userspace or IPtables. |
| LoadBalancer | Magically creates a load balancer using the cloud controller (e.g. an ELB).  Automatically creates a NodePort and a ClusterIP. |
| ExternalName | Maps the service to a DNS name through a CNAME record.  No proxying is set up. |

##### DNS

NONE of these touch external DNS, which means you have to set up CNAME/Alias records yourself. or use a DNS controller.  We will use the [external-dns](https://github.com/kubernetes-incubator/external-dns) kubernetes-incubator project.

## Demo: guestbook

    cd ../guestbook
    kubectl create -f redis-master-deployment.yaml
    kubectl create -f redis-master-service.yaml
    kubectl describe deployment redis-master
    master=$(kubectl get pods --selector=app=redis,role=master --output=jsonpath='{.items..metadata.name}')
    kubectl logs $master
    
    kubectl create -f redis-slave-deployment.yaml
    kubectl create -f redis-slave-service.yaml
    kubectl describe deployment redis-slave
    for slave in $(kubectl get pods --selector=app=redis,role=slave --output=jsonpath='{.items..metadata.name}') ; do \
     kubectl logs $slave ; \
     done
    
    kubectl logs $master
    
    kubectl create -f frontend-deployment.yaml
    for frontend in $(kubectl get pods --selector=app=guestbook --output=jsonpath='{.items..metadata.name}') ; do \
     kubectl logs $frontend; \
     done
     
    kubectl create -f frontend-service.yaml
    
    kubectl describe service frontend
    
Hit the load balancer with your browser.  

This is fine and dandy, but having to create ALIAS or CNAME records is sort of annoying.  Let's try this again with the external DNS add-on installed.

    kubectl annotate service frontend "external-dns.alpha.kubernetes.io/hostname=guestbook.k8s.$public_domain."
    kubectl describe service frontend
    cd ../external-dns
    ./dns.sh
    kubectl describe deployment external-dns
    dns=$(kubectl get pods --selector=app=external-dns --output=jsonpath='{.items..metadata.name}')
    kubectl logs $dns

#### TODO A few debugging tricks?

- port forward a pod
- execute a shell on a pod
- helm charts
