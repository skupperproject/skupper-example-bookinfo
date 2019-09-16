# Distributing Bookinfo Web Services across Kubernetes Clusters with Skupper

This tutorial demonstrates how to distribute 
[Istio Bookinfo Application](https://istio.io/docs/examples/bookinfo/)
web microservices application between public and private cluster project
namespaces. The application requires no special coding to adapt to
the distributed environment. With Skupper it 
behaves as if all the services are running in the same cluster namespace.

This example further illustrates how with Skupper services in a
public cluster may access services in a private cluster that has no ingress routes and
will not accept incoming network connections. 
The Skupper infrastructure securely provides this connectivity
with no special user permissions, firewall rules, VPNs, sidecars, or system administrator
actions.

In this tutorial you will deploy 
the _productpage_ and _ratings_ services on a remote, public cluster
and
the _details_ and _reviews_ services in a local, on-premises cluster.

### Bookinfo Skupper Deployment

![Bookinfo Skupper deployment](https://github.com/skupperproject/skupper-example-bookinfo/blob/master/graphics/skupper-example-bookinfo-deployment.gif)

User access to the application is via an ingress route to the _productpage_ service.
The remaining services are not publicly accessible but are available to
the _productpage_ and to each other through the Skupper network.

In the Bookinfo application the _productpage_ service sends requests to the
_details_ and _reviews_ services, and the _reviews_ service sends requests
to the _ratings_ service. Skupper manages routing the requests between
the services regardless of the cloud instance or namespace in which the services
are running.

This demo uses public Bookinfo images provided by _docker.io/maistra_. The _maistra_ images
constrain filesystem access to common directories and provide a
successful demo on a wider variety of Kubernetes platforms.

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Install demo source files and Skupper tool](#step-1-install-demo-source-files-and-skupper-tool)
* [Step 2. Set up target namespaces](#step-2-set-up-target-namespaces)
* [Step 3: Install Skupper resources](#step-3-install-skupper-resources)
* [Step 4: Connect your namespaces](#step-4-connect-your-namespaces)
* [Step 5: Deploy Bookinfo application](#step-5-deploy-bookinfo-application)
* [Step 6: Expose your internal services via Skupper](#step-6-expose-your-internal-services-via-skupper)
* [Step 7: Expose main Bookinfo productpage application](#step-7-expose-main-bookinfo-productpage-application)
* [Step 8: Open Bookinfo application](#step-8-open-bookinfo-application)
* [Next steps](#next-steps)


## Prerequisites

* You should have access to two Kubernetes clusters:

  * A private cloud cluster running on your local machine
  * A public cloud cluster running in a public cloud provider

* You must be logged in to each cluster project namespace.

In this example the private cluster will be called *PVT* and the public cluster will
be called *PUB*.

This example illustrates the greatest value of Skupper by enabling communications
between two clusters. However, if you have only one cluster
then simply create two  namespaces on that cluster
and proceed with the demo.

## Step 1: Install demo source files and Skupper tool

1. Make a directory for this tutorial and clone the example repo into it. 

    ```
    mkdir bookinfo-demo
    cd bookinfo-demo
    git clone https://github.com/skupperproject/skupper-example-bookinfo.git
    cd skupper-example-bookinfo
    ```

2. Install the Skupper command line executable in your current directory:
    
    ```
    curl -fL https://github.com/skupperproject/skupper-cli/releases/download/0.0.1-beta/linux.tgz | tar -xzf -
    ```

To test your installation, check the Skupper version


    $ skupper --version
    skupper version <version>

## Step 2. Set up target namespaces

1. Console session for *PUB*

      ```bash
      oc new-project bookinfo-pub
      ```

2. Console session for *PVT*

      ```bash
      oc new-project bookinfo-pvt
      ```

Although this example shows different project namespaces on each cluster, you could 
just as well use the same project namespace. Use different namespaces if you are
running the demo on a single cluster.

## Step 3: Install Skupper resources

### Install the resources

1. Console session for *PUB*

    ```bash
    $ skupper init --id PUB
    Skupper is now installed in 'bookinfo-pub'.  Use 'skupper status' to get more information.
    ```

2. Console session for *PVT*

    ```bash
    $ skupper init --id PVT
    Skupper is now installed in 'bookinfo-pvt'.  Use 'skupper status' to get more information.
    ```

### Check the installation

1. Console session for *PUB*

    ```bash
    $ skupper status
    Skupper enabled for "bookinfo-pub". It is not connected to any other sites.   
    ```

2. Console session for *PVT*

    ```bash
    skupper status
    Skupper enabled for "bookinfo-pvt". It is not connected to any other sites.
    ```

## Step 4: Connect your namespaces

After installation, you have the infrastructure you need, but your namespaces 
are not connected. 

The ```skupper connection-token``` command generates a secret token that signifies permission 
to connect to this namespace. The token also carries the network connection details so
that a connecting Skupper namespace can find originating namespace. 

The ```skupper connect``` command uses the connection token to establish a connection to the 
namespace that generated it.

### Generate a connection token

1. Console session for *PUB*
 
   ```bash
   skupper connection-token PVT-to-PUB-connection-token.yaml
   ```

### Use the token to form a connection

2. Console session for *PVT*

   ```bash
   skupper connect PVT-to-PUB-connection-token.yaml
   ```
### What just happened?

The console session for *PUB* created the PVT-to-PUB-connection-token.yaml file 
that defines a Secret Skupper connection token. . 

You may need to transport the connection token file to another system or to another site
so that it is readable by the _skupper connect_ command in the console session for *PVT*. 

    NOTE: The generated connection token file enables any Skupper installation 
          to connect into the Skupper installation that generated the file. 
          Protect the file as you would any file that holds login credentials.

A connection token generated by one Skupper namespace can not be modified to redirect its
connection to another Skupper namespace. The credentials in the token are honored only
by the Skupper that generated the token. 

In this example Skupper is configured to connect from the private network to the public network.
This connection direction is the preferred direction because
it minimizes the number of ingress ports open on the private cluster. 
In this example the private cluster has _no_ exposed routes.

Once a Skupper connection is established Skupper can access services and 
transfer data in either direction between the clusters.

### Check the connection

1. Console session for *PUB*

    ```
    $ skupper status
   Skupper enabled for "bookinfo-pub". It is connected to 1 other sites.
   ```
2. Console session for *PVT*

    ```
    $ skupper status
    Skupper enabled for "bookinfo-pvt". It is connected to 1 other sites.
    ```

## Step 5: Deploy Bookinfo application

This step creates a service and a deployment for each of the four Bookinfo microservices.

1. Console session for *PUB*

    ```buildoutcfg
    $ kubectl apply -f public-cloud.yaml
    service/productpage created
    deployment.extensions/productpage-v1 created
    service/ratings created
    deployment.extensions/ratings-v1 created
    ```

2. Console session for *PVT*

    ```buildoutcfg
    $ kubectl apply -f private-cloud.yaml 
    service/details created
    deployment.extensions/details-v1 created
    service/reviews created
    deployment.extensions/reviews-v3 created
    ```

### Verify the deployment

1. Console session for *PUB*

    ```
    $ kubectl get pods
    NAME                                        READY     STATUS    RESTARTS   AGE
    productpage-v1-84d47b6ddb-nrjbz             1/1       Running   0          2m53s
    ratings-v1-6647d5c748-zgmtp                 1/1       Running   0          2m52s
    skupper-proxy-controller-5fcf86bc8d-rggn8   1/1       Running   0          40m
    skupper-router-7d7fccfc99-t4n47             1/1       Running   0          40m
    ```

2. Console session for *PVT*

    ```
    $ kubectl get pods
    NAME                                       READY     STATUS    RESTARTS   AGE
    details-v1-5bbf7fc97c-zhpf8                1/1       Running   0          4m
    reviews-v3-5b5df576d4-mjprb                1/1       Running   0          4m
    skupper-proxy-controller-94cfcd597-lwb67   1/1       Running   0          29m
    skupper-router-f94b6759f-bqs2t             1/1       Running   0          14m
    ```

Commodity _maistra_ Bookinfo pods have been created:

| Namespace         | Pods                    |
| ------------------|-------------------------|
| bookinfo-pub      | _productpage_ _ratings_ |
| bookinfo-pvt      | _details_ _reviews_     |

## Step 6: Expose your internal services via Skupper

You now have a Skupper network capable of multi-cluster communication 
but no services are yet associated with it. This step uses the ```kubectl annotate``` 
command to notify Skupper that a service is to be included in the Skupper network.

1. Console session for *PUB*

    ```buildoutcfg
    $ kubectl annotate service ratings skupper.io/proxy=http
    service/ratings annotated
    ```

2. Console session for *PVT*

```buildoutcfg
    $ kubectl annotate service details skupper.io/proxy=http
    service/details annotated
    
    $ kubectl annotate service reviews skupper.io/proxy=http
    service/reviews annotated
```

In this example the Skupper proxy type is _http_. Skupper also supports proxy
type _tcp_. 

Upon observing the annotation Skupper propagates the annotated service to
the Skupper network. The service on the hosting namespace is now available to all the 
Skupper-connected namespaces.

### Verify the Skupper service deployment

1. Console session for *PUB*

    ```
    $ kubectl get services
    NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)               AGE
    details             ClusterIP   172.30.82.92     <none>        9080/TCP              4m28s
    productpage         ClusterIP   172.30.20.70     <none>        9080/TCP              41m
    ratings             ClusterIP   172.30.122.185   <none>        9080/TCP              41m
    reviews             ClusterIP   172.30.137.2     <none>        9080/TCP              3m22s
    skupper-internal    ClusterIP   172.30.55.53     <none>        55671/TCP,45671/TCP   79m
    skupper-messaging   ClusterIP   172.30.156.41    <none>        5671/TCP              79m
    ```

2. Console session for *PVT*

    ```
    $ kubectl get services
    NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)               AGE
    details             ClusterIP   172.30.134.169   <none>        9080/TCP              38m
    ratings             ClusterIP   172.30.177.56    <none>        9080/TCP              4m
    reviews             ClusterIP   172.30.180.107   <none>        9080/TCP              38m
    skupper-internal    ClusterIP   172.30.60.78     <none>        55671/TCP,45671/TCP   1h
    skupper-messaging   ClusterIP   172.30.106.92    <none>        5671/TCP              1h
    ```

Skupper proxies are now in place to route the _reviews_, _details_, and
_ratings_ http requests to the appropriate microservice instance from 
anywhere in the Skupper network.

## Step 7: Expose main Bookinfo productpage application

1. Console session for *PUB*

```buildoutcfg
    oc expose service productpage
```

The _productpage_ service is exposed through an ingress route on a public cluster port.
_productpage_ has no Skupper proxy annotation. Http requests to _productpage_
cannot be routed across the Skupper network.

Now the Bookinfo app is fully functional.

## Step 8: Open Bookinfo application

Open the Bookinfo app at a web address that can be discovered from 
the terminal for the PUB cluster: 

```buildoutcfg
    $ echo $(oc get route productpage -o=jsonpath='http://{.spec.host}:{.spec.port.targetPort}')
    http://productpage-bookinfo-pub.apps.user-instance.public-cluster.net:http  <example address>
```

## Next steps

