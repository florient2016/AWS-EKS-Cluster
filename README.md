# Custom EKS Cluster with Terraform 🚀

![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?style=flat-square) ![AWS](https://img.shields.io/badge/AWS-EKS-orange?style=flat-square) ![GitHub](https://img.shields.io/badge/GitHub-README-blue?style=flat-square)

This repository contains Terraform code to deploy an Amazon EKS (Elastic Kubernetes Service) cluster named `custom-eks` in the `us-east-1` region. It includes a VPC, subnets, IAM roles, a node group with SSH access via your local `~/.ssh/id_rsa.pub` key, and outputs for cluster details plus a `kubectl` configuration command. 🎉

## Features 🌟

- **EKS Cluster**: Named `custom-eks`, running Kubernetes 1.29 (customizable).
- **Networking**: VPC with public and private subnets, NAT Gateway, and Internet Gateway.
- **Node Group**: 2 `t3.medium` instances (scalable to 3) in private subnets.
- **SSH Access**: Uses your local `~/.ssh/id_rsa.pub` for node access.
- **Outputs**: Cluster endpoint, CA certificate, name, and kubeconfig update command.

## Prerequisites ✅

Before you begin, ensure you have:

- [Terraform](https://www.terraform.io/downloads.html) installed (v1.5+ recommended) 🛠️
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`) 🔑
- SSH key pair at `~/.ssh/id_rsa.pub` (generate with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa` if needed) 🔐
- Permissions to create AWS resources (VPC, EKS, IAM, etc.) ⚙️

## Usage 🚀

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/florient2016/AWS-EKS-Cluster.git
   cd AWS-EKS-Cluster
   ```
2. **Initialize Terraform**:
   ```bash
   terraform init
   ```
3. **Review the Plan**:
   ```bash
   terraform plan
   ```
4. **Deploy the Cluster**:
   ```bash
   terraform apply
   ```
Type yes to confirm. This takes ~10-15 minutes ⏳.
5. **Check Outputs :** After deployment, Terraform displays:
- **cluster_endpoint :** EKS endpoint 🌐
- **cluster_ca_certificate :** Certificate authority data 📜
- **cluster_name:** custom-eks 🏷️
- **kubeconfig_update_command :** Command to configure kubectl 🖥️

6. **Configure kubect :** Run the output command, e.g.:
   ```bash
   aws eks --region us-east-1 update-kubeconfig --name custom-eks
   ```
Verify with:
   ```bash
   kubectl get nodes
   ```

