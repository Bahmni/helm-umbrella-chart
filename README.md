# helm-umbrella-chart
Helm Umbrella Chart for Bahmni India Distro

## Setting Kubernetes cluster using Minikube (Development / Non-production)

1. Install [docker](https://docs.docker.com/engine/install/)
2. Install [minikube](https://minikube.sigs.k8s.io/docs/start/) >=1.25.2
3. Install [Helm-3](https://helm.sh/docs/intro/install/#through-package-managers)
4. Increase resources of your docker to a memory of atleast 8GB.
   ([Mac](https://docs.docker.com/desktop/mac/) /
   [Windows](https://docs.docker.com/desktop/windows/))

Note: You can also run minikube without using docker. Look
[here](https://minikube.sigs.k8s.io/docs/drivers/).

### Start minikube with decent resources

```
minikube start --driver=docker --memory 7000 --cpus=4
```

you should see

```
😄  minikube v1.25.2 on Darwin 10.15.7
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=4, Memory=7000MB) ...\
```

### Enable Ingress

Ingress would act as a controller to route between various applicaitons

`minikube addons enable ingress`

### Add nginx ingress host entry to etc host

_MacOS / Linux_

```
sudo vi /etc/hosts

# bahmni kubernetes nginx-ingress
127.0.0.1 bahmni.local

# bahmni crater kubernetes nginx-ingress
127.0.0.1 payments-bahmni.local
```

_Windows_

```
    Press the Windows key.

    Type Notepad in the search field.

    In the search results, right-click Notepad and select Run as administrator.

    From Notepad, open the following file:

    c:\Windows\System32\Drivers\etc\hosts

    Make the necessary changes to the file.

    Select File > Save to save your changes.
```

### Run minikube tunnel in seperate terminal

minikube tunnel runs as a process, creating a network route on the host to the
service CIDR of the cluster using the cluster’s IP address as a gateway. The
tunnel command exposes the external IP directly to any program running on the
host operating system.

`sudo minikube tunnel --alsologtostderr -v=1`

Note: Run this in a seperate terminal and keep it open

### Running MySQL DB Server
`helm install --repo https://charts.bitnami.com/bitnami mysql mysql --set auth.rootPassword=root --set image.tag=5.7`

### Running Database setup helm chart
```shell
helm install db-setup db-setup --repo https://bahmni.github.io/helm-charts --devel --wait --wait-for-jobs --atomic --timeout 1m \
          --set DB_HOST=mysql \
          --set DB_ROOT_USERNAME=root \
          --set DB_ROOT_PASSWORD=root \
          --set databases.openmrs.DB_NAME=openmrs \
          --set databases.openmrs.USERNAME=openmrs-user \
          --set databases.openmrs.PASSWORD=password \
          --set databases.crater.DB_NAME=crater \
          --set databases.crater.USERNAME=crater-user \
          --set databases.crater.PASSWORD=password \
          --set databases.reports.DB_NAME=bahmni_reports \
          --set databases.reports.USERNAME=reports-user \
          --set databases.reports.PASSWORD=password
```
This command takes a while to complete. Once it is completed run the following command to remove datbase root credentials from the cluster.
```shell
helm uninstall db-setup
```

### Installing the application Helm-Umbrella Chart
Navigate to the directory where you cloned this repository
```shell
helm dependency update
helm upgrade bahmni-local . --values=values/local.yaml --install
```
### Notes
- Toggle on the services in local.yaml based on your local setup requirements. Add any missing environment variables either in local.yaml or `--set`. Check [`helm upgrade ...`](https://github.com/BahmniIndiaDistro/helm-umbrella-chart/blob/2179120ef21acfd8f8332436c341e2f106dfa558/.github/workflows/deploy.yaml#L92) for list of variable needed by each service.
- To uninstall a release use `helm uninstall [release name]` which will uninstall all the resources under that release e.g. `helm uninstall db-setup`
- Your local might be setup to query cloud K8s clusters e.g. aws. You need to ensure that you are in the minikube context for local development. Minikube bootstrap should take care of updating the kubectl current-context. You can verify and update the context using
```
//verify current context
$ kubectl config current-context
(or)
$ kubectl config view --minify

//Update current context to minikube
$ minikube update-context
```
- Minikube runs in a VM (such as docker) and wont see your local built docker images. If you need to use your local docker images to be picked up while provisioning the pods on minikube you can use `eval $(minikube docker-env)` to actually configure your environment to utilise minikube's docker daemon for docker images. [docs](https://minikube.sigs.k8s.io/docs/commands/docker-env/)

### Accessing Applications

Once the pods and servies are running you can access it from the browser on

1. Bahmni EMR --> https://bahmni.local/bahmni/home
2. OpenMRS --> https://bahmni.local/openmrs
4. Crater --> https://payments-bahmni.local/
## Setup Developer Access to the Cluster

### Creating a User Group for EKS Cluster Admin Access

Create a new IAM group for developers
```
aws iam create-group --group-name bahmni_eks_developers
```
When IAM users are added to this group then they will get full access to resources in the EKS cluster.
### Create an IAM role
Create Role with trust policy (first time)
```
aws iam create-role --role-name BahmniEKSDeveloperRoleForIAMUsers --assume-role-policy-document file://aws/roles/BahmniEKSDeveloperRoleForIAMUsers.json
```

### Create Policies
`aws/policies` folder contains all custom policies applied to the AWS account.

Create a `AssumeRole` policy:
```
 aws iam create-policy --policy-name BahmniEKSDeveloperAssumeRolePolicy --policy-document file://aws/policies/BahmniEKSDeveloperAssumeRolePolicy.json
```
Create a `BahmniEKSDeveloper` policy:
```
aws iam create-policy --policy-name BahmniEKSDeveloper --policy-document file://aws/policies/BahmniEKSDeveloper.json
```
Note the policy arns 


Next, Attach the `BahmniEKSDeveloperAssumeRolePolicy`  to `bahmni_eks_developers` group.
```
aws iam attach-group-policy --group-name bahmni_eks_developers --policy-arn <POLICY_ARN>
```
Attach the `BahmniEKSDeveloper`  to `BahmniEKSDeveloperRoleForIAMUsers` role.
```
aws iam attach-role-policy --policy-arn <POLICY_ARN> --role-name BahmniEKSDeveloperRoleForIAMUsers
```
### Authorise kubectl with EKS
```
aws eks update-kubeconfig --name bahmni-cluster-dev
```
### Apply Kubernetes Developer Cluster Role
```
kubectl apply -f k8s-rbac/eks-developer.yaml
```
### Create Identity Mapping
```
eksctl create iamidentitymapping \
--cluster bahmni-cluster-nonprod \
--arn  arn:aws:iam::{YourAccountNumber}:role/BahmniEKSDeveloperRoleForIAMUsers \
--group eks-developer-group \
--username assume-role-user \
--no-duplicate-arns
```

## Access RDS databases
To access RDS databases:

Navigate to the project root directory and run the script `connectmysqlrds.sh`
```
./connectmysqlrds.sh <environment-name> <application-name>

e.g
./connectmysqlrds.sh dev openmrs
```
