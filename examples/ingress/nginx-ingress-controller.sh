#!/bin/bash
cat > nginx-ingress-controller.yaml <<EOF
kind: Service
apiVersion: v1
metadata:
  name: nginx-default-backend
  namespace: kube-system
  labels:
    k8s-addon: ingress-nginx.addons.k8s.io
spec:
  ports:
  - port: 80
    targetPort: http
  selector:
    app: nginx-default-backend

---

kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nginx-default-backend
  namespace: kube-system
  labels:
    k8s-addon: ingress-nginx.addons.k8s.io
spec:
  replicas: 1
  template:
    metadata:
      labels:
        k8s-addon: ingress-nginx.addons.k8s.io
        app: nginx-default-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-http-backend
        image: gcr.io/google_containers/defaultbackend:1.0
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: ingress-nginx
  namespace: kube-system
  labels:
    k8s-addon: ingress-nginx.addons.k8s.io
data:
  use-proxy-protocol: "true"
  enable-vts-status: "true"

---

kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx
  namespace: kube-system
  labels:
    k8s-addon: ingress-nginx.addons.k8s.io
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: '*'
    external-dns.alpha.kubernetes.io/hostname: nginx.k8s.$public_domain.
spec:
  type: LoadBalancer
  selector:
    app: ingress-nginx
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: https
    port: 443
    targetPort: https
  - name: status
    port: 18080
    targetPort: status

---

kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: ingress-nginx
  namespace: kube-system
  labels:
    k8s-addon: ingress-nginx.addons.k8s.io
spec:
  replicas: 2
  template:
    metadata:
      labels:
        namespace: kube-system
        app: ingress-nginx
        k8s-addon: ingress-nginx.addons.k8s.io
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - image: gcr.io/google_containers/nginx-ingress-controller:0.9.0-beta.11
        name: ingress-nginx
        imagePullPolicy: Always
        ports:
          - name: http
            containerPort: 80
            protocol: TCP
          - name: https
            containerPort: 443
            protocol: TCP
          - name: status
            containerPort: 18080
            protocol: TCP
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        args:
        - /nginx-ingress-controller
        - --default-backend-service=\$(POD_NAMESPACE)/nginx-default-backend
        - --configmap=\$(POD_NAMESPACE)/ingress-nginx
        - --publish-service=\$(POD_NAMESPACE)/ingress-nginx
EOF

kubectl apply -f nginx-ingress-controller.yaml
