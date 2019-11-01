# Distributing Bookinfo services across clusters with Skupper

This tutorial demonstrates how to distribute 
[Istio Bookinfo Application](https://istio.io/docs/examples/bookinfo/)
microservices across multiple public and private clusters.
The services require no coding changes to work in
the distributed application environment. With Skupper the application
behaves as if all the services are running in the same cluster.

This example further illustrates how services in a
public cluster may access services in a private cluster when the private cluster 
will not accept incoming network connections and the private cluster 
has no ingress routes. 
Skupper infrastructure securely provides this connectivity and it does so
without special user permissions, firewall rules, VPNs, sidecars, or system administrator
actions.

In this tutorial you will deploy 
the _productpage_ and _ratings_ services on a remote, public cluster
in namespace `aws-eu-west`
and
the _details_ and _reviews_ services in a local, on-premises cluster in namespace `laptop`.

Watch a video demonstrating this tutorial:

[![Distributing Bookinfo services across clusters with Skupper](<img src="graphics/video-thumbnail.png" width="640"/>)](https://youtu.be/MO12bk_nczM)

### Table of contents
* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Step 1: Deploy the Bookinfo application](#step-1-deploy-the-bookinfo-application)
* [Step 2: Expose the public productpage service](#step-2-expose-the-public-productpage-service)
* [Step 3: Observe that the application does not work](#step-3-observe-that-the-application-does-not-work)
* [Step 4: Set up Skupper](#step-4-set-up-skupper)
* [Step 5: Connect your Skupper installations](#step-5-connect-your-skupper-installations)
* [Step 6: Virtualize the services you want shared](#step-6-virtualize-the-services-you-want-shared)
* [Step 7: Observe that the application works](#step-7-observe-that-the-application-works)
* [Clean up](#clean-up)
* [Next steps](#next-steps)
* [Credits](#credits)


## Overview

<img src="graphics/skupper-example-bookinfo-deployment.gif" width="640"/>

This picture shows how the services will be deployed.

* Each cluster runs two of the application services.

* An ingress route to the _productpage_ service provides internet user
access to the application.

If all the services were installed on the public cluster then the application
would work as originally designed. However, since two of the services are on
the _laptop_ cluster the application fails. _productpage_ can not send requests
to _details_ or to _reviews_.

This demo will show how Skupper can solve the connectivity problem presented
by this arrangement of service deployments.

<img src="graphics/skupper-example-bookinfo-details.gif" width="640"/>

This picture shows how the clusters appear after Skupper has been set up.

Skupper is a distributed system with installations running
in one or more clusters or namespaces. Connected Skupper installations share
information about what services each installation exposes. Each Skupper installation learns 
which
services are exposed on every other installation. Skupper then runs proxy service endpoints
in each namespace to properly route requests to or from every exposed service.

* In the public namespace the _details_ and _reviews_ proxies intercept requests for their 
services and forward them to the Skupper
network.

* In the private namespace the _details_ and _reviews_ proxies receive requests from the
Skupper network and send them to the related service. 

* In the private namespace the _ratings_ proxy intercepts requests for its service and 
forwards them to the Skupper network.

* In the public namespace the _ratings_ 
proxy receives requests from the Skupper network and sends them to the related service.

## Prerequisites

To run this tutorial you will need:

* The `kubectl` command-line tool, version 1.15 or later ([installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
* The `skupper` command-line tool, the latest version ([installation guide](https://skupper.io/start/index.html#step-1-install-the-skupper-command-line-tool-in-your-environment))
* Two Kubernetes namespaces, from any providers you choose, on any clusters you choose
* The yaml files from https://github.com/skupperproject/skupper-examples-bookinfo.git
* Two logged-in console terminals, one for each cluster

## Step 1: Deploy the Bookinfo application

This step creates a service and a deployment for each of the four Bookinfo microservices.

Console for namespace `aws-eu-west`:

    $ kubectl apply -f public-cloud.yaml
    service/productpage created
    deployment.extensions/productpage-v1 created
    service/ratings created
    deployment.extensions/ratings-v1 created

Console for namespace `laptop`:

    $ kubectl apply -f private-cloud.yaml 
    service/details created
    deployment.extensions/details-v1 created
    service/reviews created
    deployment.extensions/reviews-v3 created

## Step 2: Expose the public productpage service

Console for namespace `aws-eu-west`:

    kubectl expose deployment/productpage-v1 --port 9080 --type LoadBalancer

The Bookinfo application is accessed from the public internet through this ingress port to the _productpage_ service.

## Step 3: Observe that the application does not work

The web address for the Bookinfo app can be discovered from 
the console for namespace `aws-eu-west` cluster: 

    $ echo $(kubectl get service/productpage -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:9080')

Open the address in a web browser. The productpage responds but the page will show errors because the 
back-end services are not yet available.

Let's fix that now.

## Step 4: Set up Skupper

This step initializes the Skupper environment on each cluster.

Console for namespace `laptop`:

    skupper init

Console for namespace `aws-eu-west`:

    skupper init

Now the Skupper infrastructure is running. 
Use `skupper status` in each console to see that Skupper is
available.

    $ skupper status
    Namespace '<ns>' is ready.  It is connected to 0 other namespaces.

As you move through the steps that follow, you can use `skupper
status` at any time to check your progress.

## Step 5: Connect your Skupper installations

Now you need Skupper to connect your namespaces. This is a two step process. 

* The ```skupper connection-token``` command generates a secret token that signifies permission 
to connect to this namespace. The token also carries the network connection details so
that a connecting Skupper can find the Skupper that generated the token. 

    Note: Protect this file as you would 
          any file that holds login credentials.

* The ```skupper connect``` command uses the connection token to establish a connection to the 
Skupper that generated it.

The console sessions in this demo are run by the same user on the same host.
This makes the token file in the ${HOME} directory available to both consoles.
If your console sessions are on different machines then you may need to
use `scp` or a similar tool to transfer the token file to the system
hosting the `laptop` console.

### Generate a connection token

Console for namespace `aws-eu-west`:
 
    skupper connection-token ${HOME}/PVT-to-PUB-connection-token.yaml
    
### Use the token to form a connection

Console for namespace `laptop`:

    skupper connect ${HOME}/PVT-to-PUB-connection-token.yaml

### Check the connection

Console for namespace `aws-eu-west`:

    $ skupper status
    Skupper enabled for "aws-eu-west". It is connected to 1 other sites.

Console for namespace `laptop`:

    $ skupper status
    Skupper enabled for "laptop". It is connected to 1 other sites.

## Step 6: Virtualize the services you want shared

You now have a Skupper network capable of multi-cluster communication 
but no services are yet associated with it. This step uses the ```kubectl annotate``` 
command to notify Skupper that a service is to be included in the Skupper network.

Skupper uses the annotation as the indication that a service must be virtualized.
The service that receives the annotation is the physical target for network requests
and the proxies that Skupper deploys in the other namespaces are the virtual targets
for network requests. The Skupper infrastructure then routes requests between the 
virtual services and the target service.

Console for namespace `aws-eu-west`:

    $ kubectl annotate service ratings skupper.io/proxy=http
    service/ratings annotated

Console for namespace `laptop`:

    $ kubectl annotate service details skupper.io/proxy=http
    service/details annotated
    
    $ kubectl annotate service reviews skupper.io/proxy=http
    service/reviews annotated

Skupper is now making the annotated services available to every namespace in the Skupper
network. The Bookinfo application will work because the _productpage_ service
on the public cluster has access to the _details_ and _reviews_ services on
the private cluster and because the _reviews_ service on the private cluster
has access to the _ratings_ service on the public cluster.

## Step 7: Observe that the application works

The web address for the Bookinfo app can be discovered from 
the console for namespace `aws-eu-west` cluster: 

    $ echo $(kubectl get service/productpage -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:9080')

Open the address in a web browser.

The _productpage_ now shows the entire application working with no errors.

## Clean up

Skupper and the Bookinfo services may be removed from the clusters.

Console for namespace `aws-eu-west`:

    skupper delete
    kubectl delete -f public-cloud.yaml

Console for namespace `laptop`:

    skupper delete
    kubectl delete -f private-cloud.yaml 

## Next steps

* [Try our MongoDB database replica set example](https://github.com/skupperproject/skupper-example-mongodb-replica-set)
* [Find more examples](https://skupper.io/examples/)

## Credits

This demo uses public Bookinfo images provided by _docker.io/maistra_. 

