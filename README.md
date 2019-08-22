# Sharing Bookinfo Web Services across Cloud Clusters

This tutorial demonstrates how to share [Istio Bookinfo Application](https://istio.io/docs/examples/bookinfo/)
web microservices running in several public and private clouds.

In this tutorial you will deploy the _product page_ and _reviews_ services in a local, on-premises cluster and
deploy the _details_ and _ratings_ services on a remote, public cluster. You will also deploy a Skupper
router network that enables communication between the two clusters, along with service proxies that intercept web
requests and forward them across the router network to the cluster that is hosting the targeted microservice.

```
  +-----------------------+         +---------------------+
  | local cluster         |         | public cloud        |
  |                       |         |                     |
  | +----------------+    |         | +-------------+     |
  | | product page   |    |         | | details     |     |
  | +----------------+    |         | +-------------+     |
  |                       |         |                     |
  | +----------------+    |         | +-------------+     |
  | | reviews        |    |         | | ratings     |     |
  | +----------------+    |         | +-------------+     |
  |                       |         |                     |
  +-----------------------+         +---------------------+
```

The application is accessed through an Openshift Route to 
the product page exposed on the local cluster. This is a
normal http web port that you can open with your browser. 
The other services are accessed through proxies on the
application router network.

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Define environment](#step-1-define-environment)
* [Step 2: Create custom yaml](#step-2-create-custom-yaml)
* [Step 3: Deploy bookinfo app](#step-3-deploy-bookinfo-app)
* [Step 4: Open web app](#step-4-open-web-app)
* [Next steps](#next-steps)


## Prerequisites

* You must have access to two OpenShift clusters:

  * A private cloud cluster running on your local machine
  * A public cloud cluster running in a public cloud provider

* A Skupper application router network service must be up and running
on each cluster.

* You must be logged in to each cluster with suitable credentials.

## Step 1: Define environment

Define the following environment variables to customize your deployment:

| Environment variable               | Setting                                  |
|------------------------------------|------------------------------------------|
| SKUPPER_PRIVATE_CLUSTER_FILE_NAME  | Name for private yaml deployment file    |
| SKUPPER_PRIVATE_ROUTER_NETWORK_NAME| Name of private Skupper router deployment|
| SKUPPER_PRIVATE_PROJECT_NAMESPACE  | Exposed productpage route namesapce      |
| SKUPPER_PRIVATE_CLUSTER_IP         | Exposed pooductpage route nip.io address |
| SKUPPER_PUBLIC_CLUSTER_FILE_NAME   | Name for public yaml deployment file     |
| SKUPPER_PUBLIC_ROUTER_NETWORK_NAME | Name of public Skupper router deployment |

For example:

```bash
$ export SKUPPER_PRIVATE_CLUSTER_FILE_NAME=PVT
$ export SKUPPER_PRIVATE_ROUTER_NETWORK_NAME=messaging
$ export SKUPPER_PRIVATE_PROJECT_NAMESPACE=bookinfo
$ export SKUPPER_PRIVATE_CLUSTER_IP=127.0.0.1
$ export SKUPPER_PUBLIC_CLUSTER_FILE_NAME=AWS
$ export SKUPPER_PUBLIC_ROUTER_NETWORK_NAME=messaging
```

## Step 2: Create custom yaml

Create the custom yaml by executing the _bookinfo.sh_ script.

```bash
$ ./bookinfo.sh
```

This script applies the environment variables to the template script and 
produces two yaml file in ./yaml/.

For example:

```buildoutcfg
$ ./bookinfo.sh 
To deploy the bookinfo application in the private cluster:
    oc apply -f yaml/PVT.yaml
To deploy the bookinfo application in the public cluster:
    oc apply -f yaml/AWS.yaml
Access the bookinfo application by browsing to:
    https://productpage-bookinfo.127.0.0.1.nip.io
```

## Step 3: Deploy bookinfo app

From a console logged in to the private cluster:

```buildoutcfg
    oc apply -f yaml/PVT.yaml
```

From a console logged in to the public cluster:

```buildoutcfg
    oc apply -f yaml/AWS.yaml
```

## Step 4: Open web app

From a browser open the web address displayed during custom
yaml creation:

```buildoutcfg
    https://productpage-bookinfo.127.0.0.1.nip.io
```

## Next steps

As descrubed this demonstration requires a local cluster and a public cluster. There is no
reason that the bookinfo application could not be deployed on two public clusters. The only requirement
for that to work is that the public cloud Skupper router networks must be connected. Then the _PVT.yaml_
file could be deployed to the second public cluster.

If there are three cloud clusters connected by a Skupper router network then there are more options.
A single instance of the public services defined in _AWS.yaml_ could service requests from two instances of
the _PVT.yaml_ deployed on the other two cloud clusters.
