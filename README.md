# 🚀 EKS Cluster with Managed Node Group — Terraform Reference Implementation

This project demonstrates how to provision a **production-grade Amazon EKS cluster** using **Terraform**, following AWS best practices for security, networking, and high availability.

Perfect for learning, experimentation, or as a foundation for production workloads.

---

## 📦 What This Project Deploys

✅ **EKS Control Plane** (v1.30)  
✅ **VPC with 1 public + 2 private subnets** (multi-AZ for HA)  
✅ **NAT Gateway** for secure outbound internet access from private subnets  
✅ **IAM Roles** for EKS control plane and worker nodes  
✅ **Managed Node Group** (2–4 `t3.medium` nodes, ON_DEMAND)  
✅ **Proper tagging & security group configuration**  
✅ **Public + private API endpoint access** (for flexible connectivity)

All resources are defined in **modular, reusable Terraform code**.

---

## 🌐 Architecture Overview

<img width="1536" height="1024" alt="eks-cluster-arch" src="https://github.com/user-attachments/assets/7b13f937-d778-492c-aeb3-b29d96c19ce3" />


> 🔒 **Security**: Worker nodes run in **private subnets only** — no public IPs. All outbound traffic flows through the NAT Gateway.

<img width="1162" height="637" alt="vpc" src="https://github.com/user-attachments/assets/61af924c-fe80-4690-818e-43ac9c9549d5" />

<img width="1573" height="640" alt="resource-map" src="https://github.com/user-attachments/assets/3c062eca-8718-4613-8a1f-ed96a9ed3b66" />

---

## 🔐 IAM Roles & Permissions

### 1. **EKS Cluster Role** (`*-cluster-role`)
Used by the EKS control plane to manage AWS resources.

**Policies attached**:
- `AmazonEKSClusterPolicy`
- `AmazonEKSServicePolicy`

### 2. **EKS Node Role** (`*-node-role`)
Used by EC2 worker nodes to interact with AWS services.

**Policies attached**:
- `AmazonEKSWorkerNodePolicy` → Join cluster, manage node lifecycle
- `AmazonEKS_CNI_Policy` → Manage pod networking (ENIs)
- `AmazonEC2ContainerRegistryReadOnly` → Pull images from ECR
- *(Optional)* `AmazonSSMManagedInstanceCore` → Remote debugging via SSM

> ✅ All roles follow **least privilege** principles.

---

## 🛡️ Security Groups

- **Cluster Security Group**: Automatically created by EKS.
  - Allows inbound from node security group on:
    - TCP 443 (API server)
    - TCP 10250 (kubelet)
    - UDP 8472 (VXLAN for CNI)
- **Node Security Group**: Automatically managed by EKS node group.
  - Allows outbound to internet (via NAT Gateway)
  - Allows inbound from cluster SG

> 🔧 No manual SG rules needed — EKS handles this securely by default.

---

## 📁 Project Structure

```bash
.
├── main.tf                 # Root module: calls eks-cluster + eks-node-group
├── terraform.tfstate       # (Never commit this!)
├── .gitignore              # Ignores .terraform/, state files, etc.
├── modules/
│   ├── eks-cluster/        # VPC, IAM, EKS control plane
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks-node-group/     # Managed node group
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```
<img width="422" height="318" alt="image" src="https://github.com/user-attachments/assets/ed231224-822b-4bae-bb42-e50f4ab3cc18" />

> ✅ Clean separation of concerns: **networking/IAM/cluster** vs **compute**.

---

## 🛠️ How to Deploy

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform v1.6+
- IAM user/role with sufficient permissions (e.g., `AdministratorAccess` for learning)

### Steps

1. **Clone & Initialize**
   ```bash
   git clone <your-repo>
   cd EKS-Cluster
   terraform init
   ```

2. **Review Plan**
   ```bash
   terraform plan
   ```

3. **Apply**
   ```bash
   terraform apply
   ```
   > ⏱️ Takes **6–10 minutes**.

- ##### After apply, this is the created resources you will have

<img width="1915" height="440" alt="Screenshot 2026-01-30 020919" src="https://github.com/user-attachments/assets/c1c961fc-0c82-4801-801d-2c7afab4ed04" />

<img width="1503" height="493" alt="eks" src="https://github.com/user-attachments/assets/ccd01430-e6f9-4bde-a493-50f257788243" />

<img width="1892" height="545" alt="worker" src="https://github.com/user-attachments/assets/1b3ba77b-f822-452b-81cf-cc5fc5549997" />

<img width="1591" height="360" alt="nodes-ec2" src="https://github.com/user-attachments/assets/35a9194b-96f8-413b-8820-cd9c2d410ca8" />


4. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name ayman-eks --region us-east-1
   ```

5. **Verify Nodes**
   ```bash
   kubectl get nodes
   # Should show 2 Ready nodes
   ```
<img width="1291" height="125" alt="terminal testing" src="https://github.com/user-attachments/assets/a39da2c6-9c93-4a48-a805-bf9e51e1e585" />

6. **Test Workload (Optional)**
   ```bash
   kubectl run test --image=nginx
   kubectl get pods
   kubectl delete pod test
   ```
   ##### Double-check with worker ip as shown 
<img width="1001" height="398" alt="same private-ip" src="https://github.com/user-attachments/assets/ef84c613-ab59-4898-8318-5cd26a54e7f2" />

<img width="1577" height="372" alt="private-ip" src="https://github.com/user-attachments/assets/262dbc19-d5a7-4e90-bc0a-635121b6e722" />

---

> 💡 **Destroy when done** to avoid unnecessary charges:
> ```bash
> terraform destroy
> ```

---

## 🧪 Validation Checklist

Before destroying, confirm:

✅ `kubectl get nodes` shows **2+ Ready nodes**  
✅ Test pod runs successfully (`kubectl run test --image=nginx`)  
✅ No errors in AWS Console → EKS → Node group → Events  
✅ You can access the cluster from outside the VPC (proves public endpoint works)

---

## 🧹 Cleanup

```bash
# Destroy all AWS resources
terraform destroy

# Optional: Remove kubeconfig context
kubectl config delete-context arn:aws:eks:us-east-1:ACCOUNT:cluster/[#your_user]
```

> ✅ Leaves **zero resources** behind — no hidden costs.

---

## 📚 Best Practices Implemented

- ✅ **Multi-AZ private subnets** for high availability
- ✅ **No public IPs on worker nodes**
- ✅ **Least-privilege IAM roles**
- ✅ **Managed node groups** (not self-managed)
- ✅ **ON_DEMAND instances** (avoid Spot interruptions during learning)
- ✅ **Modular Terraform design**
- ✅ **Proper VPC tagging** for EKS (`kubernetes.io/cluster/* = shared`)
