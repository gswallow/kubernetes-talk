#!/bin/bash
# See https://github.com/kubernetes/kops/blob/master/docs/addons.md

kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.6.1.yaml
kops get secrets kube --type secret -oplaintext

#Visit https://api.k8s.gregonaws.net/ui/
# admin / ^^


kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.6.0.yaml
