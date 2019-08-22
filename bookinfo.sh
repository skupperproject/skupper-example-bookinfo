#!/bin/bash
#
# Create custom bookinfo deployment yaml files from templates
#
# Usage: ./bookinfo.sh
set -e

# define variables
SKUPPER_PRIVATE_CLUSTER_FILE_NAME=${SKUPPER_PRIVATE_CLUSTER_FILE_NAME:-"private-cluster"}
SKUPPER_PRIVATE_ROUTER_NETWORK_NAME=${SKUPPER_PRIVATE_ROUTER_NETWORK_NAME:-"messaging"}
SKUPPER_PRIVATE_PROJECT_NAMESPACE=${SKUPPER_PRIVATE_PROJECT_NAMESPACE:-"bookinfo"}
SKUPPER_PRIVATE_CLUSTER_IP=${SKUPPER_PRIVATE_CLUSTER_IP:-"127.0.0.1"}

SKUPPER_PUBLIC_CLUSTER_FILE_NAME=${SKUPPER_PUBLIC_CLUSTER_FILE_NAME:-"public-cluster"}
SKUPPER_PUBLIC_ROUTER_NETWORK_NAME=${SKUPPER_PUBLIC_ROUTER_NETWORK_NAME:-"messaging"}

# instantiate the templates into deployable yaml
mkdir -p yaml
(envsubst < private-cloud.yaml) >> yaml/${SKUPPER_PRIVATE_CLUSTER_FILE_NAME}.yaml
(envsubst < public-cloud.yaml)  >> yaml/${SKUPPER_PUBLIC_CLUSTER_FILE_NAME}.yaml

# report
echo "To deploy the bookinfo application in the private cluster:"
echo "    oc apply -f yaml/${SKUPPER_PRIVATE_CLUSTER_FILE_NAME}.yaml"
echo "To deploy the bookinfo application in the public cluster:"
echo "    oc apply -f yaml/${SKUPPER_PUBLIC_CLUSTER_FILE_NAME}.yaml"
echo "Access the bookinfo application by browsing to:"
echo "    http://productpage-${SKUPPER_PRIVATE_PROJECT_NAMESPACE}.${SKUPPER_PRIVATE_CLUSTER_IP}.nip.io"
