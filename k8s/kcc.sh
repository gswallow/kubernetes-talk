#!/bin/bash

export VPC=$(aws ec2 describe-vpcs --filters "Name=tag-key,Values=Environment" --filters "Name=tag-value,Values=$environment" --query 'Vpcs[].VpcId' --output text)
export ZONES=$(echo $(aws ec2 describe-availability-zones --query AvailabilityZones[].ZoneName --output text) | tr -s ' ' ',')

export DNS_ZONE=${DNS_ZONE:=k8s.$public_domain}
export NODE_COUNT=${NODE_COUNT:-3}
export NODE_SIZE=${NODE_SIZE:-t2.large}
export NODE_VOLUME_SIZE=${NODE_VOLUME_SIZE:-20}
export MASTER_SIZE=${MASTER_SIZE:-t2.small}
export MASTER_VOLUME_SIZE=${MASTER_VOLUME_SIZE:-20}
export K8S_VERSION=${K8S_VERSION:=1.7.5}
export KOPS_STATE_STORE=s3://${org}-${environment}-kops-state-store
export SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:-~/.ssh/id_rsa.pub}

kops create cluster $DNS_ZONE \
 --cloud=aws \
 --cloud-labels="Environment=${environment}" \
 --zones="$ZONES" \
 --master-zones="$ZONES"\
 --vpc="$VPC" \
 --node-count="$NODE_COUNT" \
 --node-size="$NODE_SIZE" \
 --node-volume-size="$NODE_VOLUME_SIZE" \
 --master-size="$MASTER_SIZE" \
 --master-volume-size="$MASTER_VOLUME_SIZE" \
 --kubernetes-version="$K8S_VERSION" \
 --state="$KOPS_STATE_STORE" \
 --dns-zone="$DNS_ZONE" \
 --ssh-public-key="$SSH_PUBLIC_KEY" \
 --topology=private \
 --networking=weave \
 --bastion="true" \
 --api-loadbalancer-type=public
