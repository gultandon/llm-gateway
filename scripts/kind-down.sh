#!/usr/bin/env bash
# Delete the local kind cluster, and with it the gateway and its SQLite volume.
set -euo pipefail
kind delete cluster --name llm-gateway
