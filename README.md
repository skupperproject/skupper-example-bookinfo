# Distributing Bookinfo Web Services across Kubernetes Clusters

This tutorial demonstrates how to distribute 
[Istio Bookinfo Application](https://istio.io/docs/examples/bookinfo/)
web microservices between public and private cluster projects or
namespaces. The application requires no special coding to adapt to
the distributed environment yet it still
behaves as if all the services are running in the same cluster namespace.

This example further illustrates how
services running in a private cluster are made available to services in a
public cluster even when the public cluster cannot make any network connections
to the private cluster. The Skupper network securely provides this connectivity
with no special user permissions, firewall rules, vpns, or system administrator
actions.

In this tutorial you will deploy the example _details_ and _reviews_ services 
in a local, on-premises cluster and
deploy the _productpage_ and _ratings_ services on a remote, public cluster.

    #####################         #####################
    # local cluster PVT #         # public cloud PUB  #
    #                   #         #                   #
    # +--------------+  #         #  +-------------+  #
    # | skupper      |<=============>| skupper     |  #
    # +--------------+  #         #  +-------------+  #
    #                   #         #                   #
    # +--------------+  #         #  +-------------+  #  route
    # | details      |<--------------| productpage |<=========
    # |              |  #    +-------|             |  #
    # +--------------+  #    |    #  +-------------+  # 
    #                   #    |    #                   #
    # +--------------+  #    |    #  +-------------+  #
    # | reviews      |<------+    #  | ratings     |  #
    # |              |-------------->|             |  #
    # +--------------+  #         #  +-------------+  #
    #                   #         #                   #
    #####################         #####################
    
    <====== network connection
    <------ Skupper network request routing

Access to the application is via an OpenShift Route to the _productpage_ service.
The reamining services are not publicly accessible but are available to
the _productpage_ and to each other through the Skupper network.

In the Bookinfo application the _productpage_ service sends requests to the
_details_ and _reviews_ services, and the _reviews_ service sends requests
to the _ratings_ service. Skupper manages routing the requests between
the services regardless of the cloud instance or namespace in which the services
are running.

This demo uses bookinfo example images provided by _docker.io/maistra_. These images
constrain filesystem access to locations that are available in OpenShift.

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Prepare OpenShift clusters](#step-2-prepare-openshift-clusters)
* [Step 3: Deploy Skupper network](#step-3-deploy-skupper-network)
* [Step 4: Deploy bookinfo application](#step-4-deploy-bookinfo-application)
* [Step 5: Add annotations to link microservices to Skupper network](#step-5-add-annotations-to-link-microservices-to-skupper-network)
* [Step 6: Expose productpage service](#step-6-expose-productpage-service)
* [Step 7: Step 7: Open bookinfo app](#step-7-open-bookinfo-app)
* [Next steps](#next-steps)


## Prerequisites

* You should have access to two OpenShift clusters:

  * A private cloud cluster running on your local machine
  * A public cloud cluster running in a public cloud provider

* You must be logged in to each cluster project namespace.

In this example the private cluster will be called *PVT* and the public cluster will
be called *PUB*.

This example illustrates the greatest value of Skupper by using two clusters
and enabling intercluster communications. However, if you have only one cluster
then simply create two projects with different namespaces on that cluster
and proceed with the demo.
Skupper will route service requests between namespaces on a single cluster just as well.

## Step 1: Set up the demo

1. On your local machine, make a directory for this tutorial, clone the example repo, and install the Skupper command:

    ```
    mkdir bookinfo-demo
    cd bookinfo-demo
    git clone https://github.com/skupperproject/skupper-example-bookinfo.git
    curl -fL https://github.com/skupperproject/skupper-cli/releases/download/dummy3/linux.tgz -o skupper.tgz
    mkdir -p $HOME/bin
    tar -xf skupper.tgz --directory $HOME/bin
    export PATH=$PATH:$HOME/bin
    ```

To test your installation, run the _skupper_ command with no arguments.
You should see a usage summary.


    $ skupper
    Usage:
      skupper [command]
    [...]

## Step 2. Prepare OpenShift clusters

1. In the terminal for the public *PUB* cluster:

      ```bash
      $ oc new-project bookinfo-public
      ```

2. In the terminal for the private *PVT* cluster

      ```bash
      $ oc new-project bookinfo-private
      ```

Although this example shows different project namespaces on each cluster, you could 
just as well use the same project namespace. Use different namespaces if you are
running the demo on a single cluster.

## Step 3: Start Skupper network

1. In the terminal for the public *PUB* cluster, install Skupper and create a connection token to be used by cluster *PVT*.

   ```bash
   skupper init --id PUB
   skupper connection-token PVT-to-PUB-connection-token.yaml
   ```

2. In the terminal for the private *PVT* cluster, install Skupper and connect it to the *PUB* cluster:

   ```bash
   skupper init --id PVT
   skupper connect PVT-to-PUB-connection-token.yaml
   ```

The PVT-to-PUB-connection-token.yaml file defines a Secret that holds the Skupper 
connection target and authentication certificate. For your installations the
generated file may need to be transported to another system or to another site
so that it is readable by the _skupper connect_ command on the private network. 

    NOTE: With the PVT-to-PUB-connection-token.yaml file 
          any Skupper installation can connect into your public 
          Skupper installation. Protect the file as you would any 
          file that holds login credentials in plain text.

In this example Skupper is configured to connect from the private network to the public network.
This direction is chosen to minimize the number of ports open on the private cluster. In this
example the private cluster has no exposed routes at all.
Once a Skupper connection is established Skupper can transfer data in either direction between
the clusters.

3. Check the Skupper infrastructure

In the terminal for the public *PUB* cluster:

    $ skupper status
    skupper enabled for bookinfo. It is not connected to any other sites.

In the terminal for the private *PVT* cluster:


    $ skupper status
    skupper enabled for bookinfo . and connected to:
    skupper-inter-router-bookinfo.apps.yourhost.yourcluster.net:443  (name=conn1)

## Step 4: Deploy bookinfo application

This step creates a service and a deployment for each of the four bookinfo microservices.

In the terminal for the private *PVT* cluster:

```buildoutcfg
    oc apply -f private-cloud.yaml
```

In the terminal for the public *PUB* cluster:

```buildoutcfg
    oc apply -f public-cloud.yaml
```

TODO: Show the services at this poing

## Step 5: Add annotations to link microservices to Skupper network

In the terminal for the private *PVT* cluster:

```buildoutcfg
    oc annotate service details skupper.io/proxy=http
    oc annotate service reviews skupper.io/proxy=http
```

In the terminal for the public *PUB* cluster:

```buildoutcfg
    oc annotate service ratings skupper.io/proxy=http
```

Skupper proxies are now in place to route the _reviews_, _details_, and
_ratings_ http requests to the appropriate microservice instance from 
anywhere in the Skupper network.

## Step 6: Expose productpage service

In the terminal for the *PUB* cluster:

```buildoutcfg
    $ oc expose service productpage
```

The _productpage_ service is exposed through a route on a public cluster port.
_productpage_ is not annotated to be a Skupper proxy and so http requests to
it cannot be routed across the Skupper network.

Now the Bookinfo app is fully functional.

## Step 7: Open bookinfo app

The bookinfo app is available at a web address that can be discovered from 
the terminal for the PUB cluster: 

```buildoutcfg
    echo $(oc get route productpage -o=jsonpath='http://{.spec.host}:{.spec.port.targetPort}')
```

## Next steps

