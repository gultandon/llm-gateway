terraform {
  required_version = ">= 1.10"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11"
    }
  }

  # State is local: the cluster lives on this machine, so there is nothing to share.
}

provider "kind" {}
