# A local cluster in Docker. kind brings the rest of the M1.5 baseline that EKS Auto Mode needs
# manifests for: a default StorageClass (local-path, "standard") and a CNI that enforces
# NetworkPolicy (kindnet). The ingress controller is in deploy/k8s/cluster/kind.

resource "kind_cluster" "this" {
  name           = var.name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # The ingress controller runs here with hostPorts 80/443 (it selects ingress-ready=true),
    # and these mappings carry the host's ports into this node's container.
    node {
      role   = "control-plane"
      labels = { "ingress-ready" = "true" }

      extra_port_mappings {
        container_port = 80
        host_port      = var.http_port
        listen_address = var.listen_address
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = var.https_port
        listen_address = var.listen_address
        protocol       = "TCP"
      }
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}
