# Multi node install on IONOS cloud

## Pre-requisites

* [terraform](https://www.terraform.io/) to provision resources
* [aicli](https://github.com/karmab/aicli) to interact with the assisted installer at the [Red Hat Hybrid Cloud Console](https://console.redhat.com/openshift)
* One public IP address with [DNS entries](https://docs.openshift.com/container-platform/4.11/installing/installing_bare_metal_ipi/ipi-install-prerequisites.html#network-requirements_ipi-install-prerequisites)
* 5 nodes with [minimum requirements](https://docs.openshift.com/container-platform/4.11/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-minimum-resource-requirements_installing-platform-agnostic) for the control plane and compute nodes

## prepare the cluster

* Download your [OpenShift pull secret](https://console.redhat.com/openshift/install/pull-secret)
into `openshift_pull.json` in this directory. 
* Edit [aicli-params.yaml](aicli-params.yaml)

Now create the cluster and download the ISO boot image

```
aicli create cluster --paramfile aicli-params.yaml <clustername>
aicli download iso <clustername>
```

Upload the iso image to [ftps://ftp-txl.ionos.com/iso-images](ftps://ftp-txl.ionos.com/iso-images)

Visit the [Red Hat Hybrid Cloud Console](https://console.redhat.com/) and you should see your cluster in "draft" state.


## IONOS infrastructure

See [variables.tf](variables.tf) for available variables.

```
terraform init
terraform apply -var ionos_username='username@example.com' -var ionos_password="xxx" -var ai_image=<clustername>.iso -var cluster_ip=<public_ip>
```

*NOTE* After creating the infrastructure, visit [dcd](https://dcd.ionos.com/) and set every
server to boot from the storage instead from the boot CDROM

## install the cluster

Wait until all hosts show up and select the appropriate roles for each host. This can be done at [Red Hat Hybrid Cloud Console](https://console.redhat.com/openshift) or by
* `aicli list host`
* `aicli update host control-0 -P role=master`

Now start the installation 
* `aicli start cluster <clustername>` 
* `watch aicli get events <clustername>`
