# kubernetes.tf

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "af-south-1"]
  }
}

resource "kubernetes_deployment_v1" "flask_app" {
  metadata {
    name = "flask-crud-deployment"
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "flask-crud"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask-crud"
        }
      }

      spec {
        container {
          image = "clintonpillay7/flask-hello:v16"
          name  = "flask-container"
          port {
            container_port = 5000 # Adjust if your Flask app uses a different port
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "flask_service" {
  metadata {
    name = "flask-service"
  }
  spec {
    selector = {
      app = "flask-crud"
    }
    port {
      port        = 80
      target_port = 5000
    }
    type = "LoadBalancer"
  }
}

output "load_balancer_hostname" {
  value = kubernetes_service_v1.flask_service.status.0.load_balancer.0.ingress.0.hostname
}