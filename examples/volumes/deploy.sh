#!/bin/bash

fs=$(aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output text)

kubectl create configmap efs-provisioner \
  --from-literal=file.system.id=$fs \
  --from-literal=aws.region=$AWS_DEFAULT_REGION \
  --from-literal=provisioner.name=$public_domain/aws-efs

cat > provisioner.yaml <<EOF
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: efs-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: efs-provisioner
    spec:
      containers:
        - name: efs-provisioner
          image: quay.io/external_storage/efs-provisioner:v0.1.0
          env:
            - name: FILE_SYSTEM_ID
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: file.system.id
            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: aws.region
            - name: PROVISIONER_NAME
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: provisioner.name
          volumeMounts:
            - name: pv-volume
              mountPath: /k8s
      volumes:
        - name: pv-volume
          nfs:
            server: ${fs}.efs.${AWS_DEFAULT_REGION}.amazonaws.com
            path: /k8s

---
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: efs-gp2
provisioner: ${public_domain}/aws-efs
parameters:
  gidMin: "40000"
  gidMax: "50000"
EOF

kubectl create -f provisioner.yaml


