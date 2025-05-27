
# 🚀Creating EKS Cluster Using Terraform 

## 📥 Installation Required

- Terraform
- Kubectl
- Helm
- Docker
- AWS CLI


## 🖥️ Server Requirements

| Resource | Minimum   | Recommended |
|----------|-----------|-------------|
| vCPU     | 2 Cores   | 4+ Cores    |
| RAM      | 4 GB      | 8+ GB       |
| Storage  | 20 GB SSD | 40+ GB SSD  |


## 👉 Follow these steps to Create EKS Cluster

1. Install Helm:

```bash
curl -O https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz
tar xvf helm-v3.16.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
rm helm-v3.16.2-linux-amd64.tar.gz
rm -rf linux-amd64
helm version
sudo apt update && sudo apt install unzip
```

2. Install Terraform:

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

```

3. Install AWS CLI:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

4. Install Docker:

```bash

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo usermod -aG docker $USER
newgrp docker


```


5. Install Kubectl:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" 
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check 
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

```

6. Clone Repo:

```bash
git clone https://github.com/prAKhar0819/EKS-Terraform-Deployment.git && cd EKS-Terraform-Deployment
```

7. Edit terraform.tfvars:

```bash
vim terraform.tfvars
```

Assign Values correctly and for Number of instance manually edit modules/node/node.tf

8. Configure AWS CLI:

```bash
aws configure
```

9. Run Terraform Code from EKS-Terraform-Deployment directory

```bash
terraform init
terraform plan
terraform apply
```
if any error occures then follow step 10 and update kubeconfig

10. Update kubeconfig file

```bash
aws eks update-kubeconfig --name <cluster-name> --region <cluster-region>
```




