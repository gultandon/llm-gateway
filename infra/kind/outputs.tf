output "cluster_name" {
  value = kind_cluster.this.name
}

output "kube_context" {
  description = "kind adds this context to your kubeconfig and switches to it."
  value       = "kind-${kind_cluster.this.name}"
}

output "cluster_endpoint" {
  value = kind_cluster.this.endpoint
}

output "kubeconfig_path" {
  value = kind_cluster.this.kubeconfig_path
}

output "load_image" {
  description = "Run this after docker build so the node has the image (there is no registry)."
  value       = "kind load docker-image llm-gateway:dev --name ${kind_cluster.this.name}"
}

output "gateway_url" {
  value = "http://localhost${var.http_port == 80 ? "" : ":${var.http_port}"}/v1"
}
