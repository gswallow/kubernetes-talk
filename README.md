# kubernetes-talk
Quick talk to the Indy DevOps group about discovery sessions with Kubernetes (k8s)

## Get started
Check the contents of env.sh.  At a minimum, run:

    export AWS_ACCESS_KEY_ID=<my_AWS_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<my_AWS_SECRET_ACCESS_KEY>
    source env.sh
    
If you don't have the aws-sdk-core gem installed, install it with bundler:

    bundle install

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

## Launching a cluster

There are two []network topologies](https://github.com/kubernetes/kops/blob/master/docs/topology.md): public and private.  We will launch a private kubernetes cluster, meaning that all of the nodes -- masters and minions -- will be located within private subnets.  This is the most secure way to create your own kubernetes cluster.

We will demonstrate how to launch a cluster [within our own VPC](https://github.com/kubernetes/kops/blob/master/docs/run_in_existing_vpc.md).  Currently there's a bug in kops 1.6.x where it ignores the tags it's supposed to use to identify shared subnets, so we'll work around that:

    cd k8s && eval $(./kcc.sh)
    bundle exec ./get-subnets.rb

Copy the output of get-subnets.rb, and then run:

    kops edit cluster k8s.gregonaws.net

Replace the contents of the "subnets" key with the output from get-subnets.rb.

kcc.sh is simply a wrapper around "kops create cluster."  The "kops create cluster" command will lay out a cluster in the S3 bucket; in order to create it, we need to update the cluster:

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

