# Argo CD on Amazon EKS + Load Balancer + Prometheus & Grafana Setup

This guide walks you through installing Argo CD on an Amazon Elastic Kubernetes Service (EKS) cluster in two ways: with Helm and without Helm (using plain manifests). It also covers setting up a Load Balancer for external access and integrating Prometheus and Grafana for monitoring, including adding an Argo CD graph in Grafana.

# Table of Contents

- [Option 1: Installing Argo CD on EKS Without Helm (Using Manifests)](#option-1-installing-argo-cd-on-eks-without-helm-using-manifests)
- [Option 2: Installing Argo CD on EKS With Helm](#option-2-installing-argo-cd-on-eks-with-helm)
- [Option 3: Setting Up a Load Balancer for Argo CD](#option-3-setting-up-a-load-balancer-for-argo-cd)
- [Option 4: Setting Up Prometheus and Grafana with Argo CD Graph](#option-4-setting-up-prometheus-and-grafana-with-argo-cd-graph)
- [License](#license)

## Option 1: Installing Argo CD on EKS Without Helm (Using Manifests)

### Step 1: Create a Namespace

Argo CD components will be deployed into a dedicated namespace called `argocd`.

```bash
kubectl create namespace argocd
```
### Step 2: Apply Argo CD Manifests
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
### Step 3: Verify Installation
```bash
kubectl get pods -n argocd
```
## Option 2: Installing Argo CD on EKS With Helm
### Step 1: Add the Argo CD Helm Repository
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```
### Step 2: Install Argo CD Using Helm
```bash
helm install argocd argo/argo-cd --namespace argocd --create-namespace
```
### Step 3: Verify Installation
```bash
kubectl get pods -n argocd
```
## Option 3: Setting Up a Load Balancer for Argo CD
Open up Argo CD UI by using Port Forwarding on the ArgoCD service type NodePort:
```bash
kubectl port-forward -n argocd service/argocd-server 8080:80
```
### Step 1: Edit the Argo CD Server Service
```bash
kubectl patch svc argocd-server -n argocd --type='merge' -p '{"spec": {"type": "LoadBalancer"}}'
```
### Step 2: Get the Load Balancer URL
```bash
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
### Step 3: Access the Argo CD UI
Open the URL in your browser:
```bash
https://localhost:8080
```
Or use the Load Balancer URL.

### Step 4: Collect Connection Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
## Option 4: Setting Up Prometheus and Grafana with Argo CD Graph
### Step 1: Install Prometheus
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
kubectl apply -f consumeMetric.yaml
```

### Step 2: Expose Grafana with a Load Balancer
```bash
kubectl port-forward svc/prometheus-stack-kube-prometheus-prometheus 9090 -n monitoring
```
Open http://localhost:9090

Grafana Dashboard
```bash
kubectl port-forward svc/prometheus-stack-grafana 3000 -n monitoring
```
Open http://localhost:3000

Username: admin
Password: (Retrieve using the command below)
```bash
kubectl get secret prometheus-stack-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```
### Add argocd dashboard
Dashboard --> Browse --> Import consumeMetric.json file

License
This project is licensed under the MIT License. See the LICENSE file for more details.