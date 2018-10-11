# Powershell Module for Kubernetes

Powershell module for Kubernetes kubectl command line tool. This module calls kubectl as json output and converts Powershell objects from the json response. This is a work in progress module but basic functionality works.

## Prerequisites

- kubectl command line tool
- authenticated kubernetes cluster
  - GKE example: `gcloud container clusters get-credentials <clusterName> --zone <zone> --project <projectId>`

## Functions

- Enter-KubernetesPod
- Remove-KubernetesPod
- Get-KubernetesPod
- Get-KubernetesNamespace
- ConvertFrom-Base64
- ConvertTo-Base64
- Get-KubernetesSecret
- Get-KubernetesPodPublicIP
- Get-KubernetesNode
- Get-KubernetesPodResource
- Get-KubernetesNodeResource

## Dynamic function parameters

Many of these functions has dynamic `ValidateSet` for parameters based on the Kubernetes cluster resource content (pods). For example in `Enter-KubernetesPod -Namespace <string> -PodName <string>` you can just tab for the `PodName` argument and the function dynamically gets all pods from that namespace.

## Installation

### `kubectl`

Install kubectl and authenticate to your Kubernetes cluster

#### Kubernetes help

`https://kubernetes.io/docs/tasks/tools/install-kubectl/`

### Powershell module

Create this folder structure if it doesn't exist and put these two files there:

- `Kubernetes.psm1` (Powershell module file)
- `Kubernetes.psd1` (Powershell manifest file)

`C:\Users\<username>\Documents\WindowsPowerShell\Modules\Kubernetes`
