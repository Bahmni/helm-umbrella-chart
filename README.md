# helm-umbrella-chart

Helm Umbrella Chart for Bahmni India Distro

## Setting Bahmni K8s cluster using Minikube for development

- [Developers Guide](https://bahmni.atlassian.net/wiki/spaces/BAH/pages/3073245197/Bahmni+K8s+with+Minikube+for+Development)

## Setup Developer Access to the Cluster on AWS EKS

> **_NOTE:_** Below details are only relevant for cluster running on AWS EKS

#### Creating a User Group for EKS Cluster Admin Access

Create a new IAM group for developers

```
aws iam create-group --group-name bahmni_eks_developers
```

When IAM users are added to this group then they will get full access to
resources in the EKS cluster.

#### Create an IAM role

Create Role with trust policy (first time)

```
aws iam create-role --role-name BahmniEKSDeveloperRoleForIAMUsers --assume-role-policy-document file://aws/roles/BahmniEKSDeveloperRoleForIAMUsers.json
```

#### Create Policies

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

Next, Attach the `BahmniEKSDeveloperAssumeRolePolicy` to `bahmni_eks_developers`
group.

```
aws iam attach-group-policy --group-name bahmni_eks_developers --policy-arn <POLICY_ARN>
```

Attach the `BahmniEKSDeveloper` to `BahmniEKSDeveloperRoleForIAMUsers` role.

```
aws iam attach-role-policy --policy-arn <POLICY_ARN> --role-name BahmniEKSDeveloperRoleForIAMUsers
```

#### Authorise kubectl with EKS

```
aws eks update-kubeconfig --name bahmni-cluster-dev
```

#### Apply Kubernetes Developer Cluster Role

```
kubectl apply -f k8s-rbac/eks-developer.yaml
```

#### Create Identity Mapping

```
eksctl create iamidentitymapping \
--cluster bahmni-cluster-nonprod \
--arn  arn:aws:iam::{YourAccountNumber}:role/BahmniEKSDeveloperRoleForIAMUsers \
--group eks-developer-group \
--username assume-role-user \
--no-duplicate-arns
```

## Access RDS databases on AWS

> **_NOTE:_** Below details are only relevant for cluster using database on AWS
> RDS

#### Prerequisite:

This is a one time setup. Configure your AWS CLI by following the steps
[here](https://bahmni.atlassian.net/wiki/spaces/BAH/pages/3023011844/AWS+Access+for+Developers).

#### Connecting to Database:

1. Navigate to the project root directory
2. Set your AWS Profile: `export AWS_PROFILE=bahmni-eks-developers` (Change the
   profile name if you have configured aws credentials with a different profile)
3. Set your AWS Region: `export AWS_REGION=ap-south-1`
4. Run the script `connectmysqlrds.sh`

```shell
./connectmysqlrds.sh <environment-name> <application-name>

e.g
./connectmysqlrds.sh dev openmrs
```

## View JVM metrics in Grafana
The JVM metrics for OpenMRS is fetched and displayed on route `/metrics` in port `8280`
with the help of [jmx-exporter](https://github.com/prometheus/jmx_exporter). Information related to heap space, GC count CPU load are provided in this route, which is visualised in Grafana with the help of [JVM dashboard](https://grafana.com/grafana/dashboards/8563-jvm-dashboard/).
- Sign in to monitoring environment
- Open Dashboards &rarr; Import
- Add the following ID (`8563`) to use JVM dashboard
- Click `load` button
- This would bring up the JVM dashboard containing visualised information of the JVM metrices.