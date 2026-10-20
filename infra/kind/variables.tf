variable "name" {
  description = "Cluster name. kubectl gets a context called kind-<name>."
  type        = string
  default     = "llm-gateway"
}

variable "node_image" {
  description = "kindest/node image, which sets the Kubernetes version. The default is the image built for the kind release inside the provider (0.31) and matches the EKS minor version."
  type        = string
  default     = "kindest/node:v1.35.0"
}

variable "worker_count" {
  description = "Worker nodes besides the control plane. 0 runs everything on the control plane, which is enough for K1."
  type        = number
  default     = 0

  validation {
    condition     = var.worker_count >= 0 && var.worker_count <= 3
    error_message = "worker_count must be between 0 and 3."
  }
}

variable "http_port" {
  description = "Host port that reaches the ingress controller over HTTP."
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Host port that reaches the ingress controller over HTTPS."
  type        = number
  default     = 443
}

variable "listen_address" {
  description = "Host address the ingress ports bind to. 127.0.0.1 keeps the gateway off the network; 0.0.0.0 exposes it."
  type        = string
  default     = "127.0.0.1"
}
