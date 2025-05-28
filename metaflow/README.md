# Metaflow Infrastructure

This directory contains the GCP infrastructure and K8s services terraform for running [Metaflow](https://metaflow.org/).

To create the infrastructure in this repo, perform the following:

1. Create a file in the root of this directory named `FILE.tfvars`, renaming it to the desired name. 
2. In this file, set the GCP project and region.
3. Plan the changes in this module:
```bash
terraform plan -target="module.infra" -var-file=FILE.tfvars
```
4. Apply th changes:
```bash
terraform apply -target="module.infra" -var-file=FILE.tfvars
```

## Changes from Outerbounds Template

This directory is heavily inspired by the template Outerbounds provide [here](https://github.com/outerbounds/metaflow-tools/tree/master/gcp/terraform). 

Below we list significant changes.

### Autopilot K8s Cluster
In GCP, the managed K8s offering has two types:

1. Standard: The typical deployment of K8s, which creates a cluster from manually managed node pools. Platform owners manage the nodes, specifying the types of nodes in these node pools and various constraints on them. If monitoring software is required to run in a pod on each node (eg. nvidia-smi), the platform owners will need to manually configure DaemonSets for this purpose. Billing is done based on the node pools, depending on the types of instances used.
2. Autopilot: GKE handles the management of nodes. Workloads then request to use a certain class of machines where Google configures. A noticeable gain of this approach for learning is that GKE handles the management of node pools. **In addition, billing is done based on the requested resources for workloads**.

This repo diverges from the template in that it uses autopilot instead of standard. As a result, some of the cluster configuration is different.
