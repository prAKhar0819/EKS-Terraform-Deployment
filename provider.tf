# Configure the AWS Provider
provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0" # Use the latest stable version
    }

  }
}


data "aws_eks_cluster" "demo" {
  name = var.cluster_name

  depends_on = [module.eks]
}
data "aws_eks_cluster_auth" "demo" {
  name = var.cluster_name

  depends_on = [module.eks]
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.demo.endpoint
    token                  = data.aws_eks_cluster_auth.demo.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority.0.data)
  }
}


# Data source to fetch the OIDC certificate thumbprint dynamically
data "tls_certificate" "demo" {
  url = data.aws_eks_cluster.demo.identity[0].oidc[0].issuer

  depends_on = [module.eks]
}

# IAM OIDC Provider resource, using the dynamically fetched thumbprint
resource "aws_iam_openid_connect_provider" "demo" {
  url             = data.aws_eks_cluster.demo.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.demo.certificates[0].sha1_fingerprint]
}

# installing metrics-server for hpa
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }
}




# install karpenter

provider "kubernetes" {
  host                   = data.aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.demo.token
 # token                  = data.aws_eks_cluster_auth.eks_auth.demo.token
}


resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = "https://charts.karpenter.sh/"
  chart      = "karpenter"
  create_namespace = true

  values = [<<EOF
controller:
  env:
    - name: AWS_REGION
      value: "${var.region}"   # Set your AWS region dynamically
EOF
  ]

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

    set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_role.arn
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.demo.name
  }

  set {
    name  = "clusterEndpoint"
    value = data.aws_eks_cluster.demo.endpoint
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}

# ******************************************************************************************************

# grafana , promtail , loki installtion 





# Create the monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_logging == "yes" ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "loki_stack" {
  count = var.enable_logging == "yes" ? 1 : 0
  name       = "loki-stack"
  namespace = kubernetes_namespace.monitoring[count.index].metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.0"

  values = [
    file("./loki/loki-custom-values.yaml")
  ]

  wait = true
}


# ******************************************************************************************************

# cert-manager installation


# resource "helm_release" "cert_manager" {
#   count      = var.enable_ssl ? 1 : 0
#   name       = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   namespace  = "cert-manager"

#   create_namespace = true

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
# }

# resource "kubernetes_manifest" "cluster_issuer" {
#   count = var.enable_ssl == "true" ? 1 : 0

#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "ClusterIssuer"
#     metadata = {
#       name = "letsencrypt-prod"
#     }
#     spec = {
#       acme = {
#         server = "https://acme-v02.api.letsencrypt.org/directory"
#         email  =  var.email  # Replace with your email
#         privateKeySecretRef = {
#           name = "letsencrypt-prod"
#         }
#         solvers = [{
#           http01 = {
#             ingress = {
#               class = "nginx"
#             }
#           }
#         }]
#       }
#     }
#   }
# }



# ---------------------------------------------------------------------------------------

# creating acm certificate for your domain

resource "aws_acm_certificate" "cert" {
   
  count      = var.enable_ssl ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# output "certificate_arn" {
#   description = "The ARN of the issued certificate"
#   value       = aws_acm_certificate.cert.arn
# }

#-----------------------------------------------------------------------------------------------------------------------------------------------

# nginx-ingress controller installation


resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true

  set {
    name  = "controller.ingressClass"
    value = "nginx"
  }

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  # Ensure Nginx is accessible only inside the cluster
  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  # Set the internal target ports for HTTP and HTTPS traffic
  set {
    name  = "controller.service.targetPorts.http"
    value = "80"
  }

}


################## argocd installation ####################################3

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  depends_on = [kubernetes_namespace.argocd]
  chart      = "argo-cd"
  version    = "5.51.6" # specify version based on your compatibility needs

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePortHttp"
    value = "32080"
  }

  set {
    name  = "server.service.nodePortHttps"
    value = "32443"
  }

  # You can optionally enable ingress here if needed later
}
