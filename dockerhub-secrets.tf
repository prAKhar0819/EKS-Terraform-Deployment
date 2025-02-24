resource "kubernetes_secret" "dockerhub_secret" {
  count = var.use_docker_auth ? 1 : 0  # Create only if Docker authentication is enabled

  metadata {
    name      = "dockerhub-credentials"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.docker_username
          password = var.docker_password
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
