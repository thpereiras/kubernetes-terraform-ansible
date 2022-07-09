# Kubernetes on AWS (v1.22.11)

[![Version](https://img.shields.io/badge/Kubernetes-v1.22.11-informational.svg)](VERSION)

This repository contains scripts for deploying Kubernetes cluster on Amazon AWS using Terraform and Ansible. It should be used for testing purposes and not for production.

## Table of Contents

<!-- TOC -->

  - [Prerequisites](#prerequisites-and-dependencies)
  - [Limitations](#limitations)
  - [Usage](#usage)
    - [1. Creating AWS credential](#1-creating-aws-credential)
    - [2. Selecting OS image (AMI) and number of nodes](#2-selecting-os-image-ami-and-number-of-nodes)
    - [3. Configuring AWS access and secret for terraform](#3-configuring-aws-access-and-secret-for-terraform)
    - [4. Creating AWS infrastructure with terraform](#4-creating-aws-infrastructure-with-terraform)
    - [5. Installing the cluster](#5-installing-the-cluster)
    - [6. Accessing the cluter](#6-accessing-the-cluter)
  - [Extra](#extra)
    - [Adding dashboard and other tools](#adding-dashboard-and-other-tools)
    - [Disabling Kubernetes Dashboard Authentication and HTTPS](#disabling-kubernetes-dashboard-authentication-and-https)

<!-- /TOC -->

## Prerequisites and dependencies

* AWS cli
* Ansible (v2.10.8)
* Terraform (v1.1.4)

## Limitations

* Only one master node (control plane) is allowed in this configuration. To add more you need to do the process manually and also add a load balancer.

## Usage

### 1. Creating AWS credential

Create a programmatic access user in AWS:

1. *My Security Credentials > Users*.
2. Click on the Add user button to add a new user.
3. Select: *Access key - Programmatic access*.
4. Add permission: *AmazonEC2FullAccess*.
5. Save the key  `./aws_key_pair/k8s-key.pem`.

### 2. Selecting OS image (AMI) and number of nodes

Choose one of the images below: 

 * ``ami-0a4f4704a9146742a`` &rarr; Ubuntu 18.04 (Bionic Beaver)
 * ``ami-0f84c9a9348f9f857`` &rarr; Ubuntu 20.04 (Focal Fossa)
 * ``ami-0890d22b1ed1cf8c7`` &rarr; Debian 10.10 (Buster)
 * ``ami-095c002d845935ff5`` &rarr; Debian 11 (Bullseye)

And change to target image in ``terraform/variables.tf``, like this:

```tf
variable "ami" {
  default = "ami-095c002d845935ff5" # Debian 11 (Bullseye)
}
```

You can also change the number of nodes:

```tf
variable "node_count" {
  default = "2"
}
```

### 3. Configuring AWS access and secret for terraform

Create a copy of the ``secrets.tfvars.example`` file and change the variables according to yours AWS access key:

```sh
cd terraform
cp secrets.tfvars.example secrets.tfvars
vi secrets.tfvars
cd ..
```

> How do I create an AWS access key? https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/

### 4. Creating AWS infrastructure with terraform

```sh
cd terraform
terraform apply -var-file=secrets.tfvars
cd ..

## The output should look like:
## Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
```

> After creating the VM's with terraform, the `inventories` directory will be automatically populated with the *hosts-k8s.yaml* file. 


### 5. Installing the cluster

Run the playbooks below to configure the cluster:

```sh
cd ansible

# Export the `AWS_USER` variable with the correct user, according to the AMI used:
# 'ubuntu' para AMI Ubuntu e 'admin' para AMI Debian
export AWS_USER=ubuntu

# Preventing host key checking:
export ANSIBLE_HOST_KEY_CHECKING=false

# Install dependencies
ansible-playbook -u $AWS_USER --private-key ../aws_key_pair/k8s-key.pem \
  -i ./inventories/hosts-k8s.yml ./playbooks/01-kube-dependencies.yml

# Setup master
ansible-playbook -u $AWS_USER --private-key ../aws_key_pair/k8s-key.pem \
  -i ./inventories/hosts-k8s.yml ./playbooks/02-setup-master.yml

# Setup workers
ansible-playbook -u $AWS_USER --private-key ../aws_key_pair/k8s-key.pem \
  -i ./inventories/hosts-k8s.yml ./playbooks/03-setup-workers.yml
```

### 6. Accessing the cluter

Access the master node (look for the ip in ``ansible/inventories/hosts-k8s``):

```sh
$ ssh $AWS_USER@<MASTER0-IP> -i aws_key_pair/k8s-key.pem
```

Check that the nodes are fine:

```sh
admin@k8s-cluster-master-0:~$ k get nodes

## The output should look like:
# NAME                   STATUS   ROLES                  AGE   VERSION
# k8s-cluster-master-0   Ready    control-plane,master    3m   v1.22.11
# k8s-cluster-node-0     Ready    <none>                  2m   v1.22.11
# k8s-cluster-node-1     Ready    <none>                  1m   v1.22.11
```

## Extra

### Adding dashboard and other tools

``Optional step``

To add Kubernetes Dashboard, Metrics Server and other cli tools (k9s, jq, bat, helm), run the following playbook:

```sh
cd ansible

ansible-playbook -u $AWS_USER --private-key ../aws_key_pair/k8s-key.pem \
  -i ./inventories/hosts-k8s.yml ./playbooks/04-extra-apps.yml
```

### Disabling Kubernetes Dashboard Authentication and HTTPS

Edit the deployment and make the following changes:

```sh
k -n kubernetes-dashboard edit deployment kubernetes-dashboard
```

Remove the arg ``--auto-generate-certificates`` and add the following:
* ``--enable-skip-login``
* ``--disable-settings-authorizer``
* ``--enable-insecure-login``
* ``--insecure-bind-address=0.0.0.0``
* ``--insecure-port=9090``

And change the LivenessProbe port to 9090, as well the ContainerPort to 9090. 

Create a service and expose a NodePort

```sh
k -n kubernetes-dashboard expose deployment kubernetes-dashboard --type=NodePort --name=kubernetes-dashboard-nodeport --target-port=9090
```

Access AWS console (Security Groups > k8s-security-group) and edit the Inbound Rules. Add your external ip (`$ curl ifconfig.me`) to `All TCP`.


Search for the generated port (*30000-32767 range*):

```sh
k -n kubernetes-dashboard get svc kubernetes-dashboard-nodeport
```

And access the dashboard with the master node IP. For example: http://<MASTER-IP>:<PORT>/

Kubernetes Dashboard will need full admin rights, so provide ``clusterrole=cluster-admin`` to your service account.

```sh
k create clusterrolebinding dashboard-access \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:kubernetes-dashboard
```

Finally, copy the token and sign in with it.

```sh
k -n kubernetes-dashboard describe secrets kubernetes-dashboard-token-<TAB>
```
