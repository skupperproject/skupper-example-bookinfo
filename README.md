### Easily have any service in the private cloud access services in the public cloud and vice versa.

Let's take the well known istio's bookinfo example and use it to illustrate how skupper easily enables a public service to access a private service and vice versa without having the need to
setup complex firewall or networking rules. Take a look at topology3/topology3.jpg for an easy to understand diagram.

The bookinfo example has four services namely productpage, reviews, ratings and details. These services are written in python, javascript, ruby etc. The productpage service calls the other
services and displays the response from all services in a single unified web page. In this example, the productpage and reviews services reside in private cloud while the
details and ratings services reside in the public cloud (AWS, Azure, Google Cloud etc). The productpage is able to easily talk to the ratings and the details services and display a unitified
web page. This is possible because skupper forms a high level application network which is easily able to communicate with services across cloud clusters. For network geeks, this application network is a
Layer 7 network formed with Application Routers (Apache Qpid Dispatch project).

Presently, this example runs only on Openshift.

As a prerequisite, you should have two openshift clusters provisioned, one in your private cloud and one in the public cloud. For ease, please use identical project names on both clouds, e.g. bookinfo

To run the example,
* Export environment variables NAMESPACE, OPENSHIFT_CLUSTER_NAME, and LOCAL_CLUSTER_IP
  * export NAMESPACE=bookinfo
  * export OPENSHIFT_CLUSTER_NAME=mycluster.devcluster.openshift.com (this is just an example, use your own public OpenShift cluster name)
  * export LOCAL_CLUSTER_IP=192.168.42.228 (this is just an example, use your own private OpenShift IP address)
* Substitute environment variables in the public-cloud.yaml and private-cloud.yaml
  * (envsubst < public-cloud.yaml) >> my-public-cloud.yaml
  * (envsubst < private-cloud.yaml) >> my-private-cloud.yaml
* Deploy my-public-cloud.yaml in the public (AWS, Azure, Google Cloud) OpenShift cluster
  * oc apply -f my-public-cloud.yaml
* Deploy my-private-cloud.yaml in your private OpenShift cluster
  * oc apply -f my-private-cloud.yaml
* From the OpenShift console, click on the pre-created Route to the productpage and Select a User and you will see the final product web page in the browser that consists of the reviews, ratings and details.

Done! Your productpage service from the private cloud just communicated with the ratings and details service in the public cloud via a application network.
Cross cloud/cluster service commuication has never been this easy. 