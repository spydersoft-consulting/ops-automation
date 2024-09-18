# Automation Tools #

This repository contains tools and scripts used for automated management of resources within the home lab.

## What's Inside? ##

* Terraform Projects
  * [azuread](./terraform/azuread/) - Resources for my Azure Active Directory
  * [devops](./terraform/devops/) - Resources for my [Azure DevOps Instance](https://dev.azure.com/spydersoft/Public%20Projects).
  * [geregalab](./terraform/geregalab/) - Resources for my lab subscription in Azure.
* [Scripts](./scripts/)
* [Build Pipelines](./.devops)

## Terraform Projects ##

The Terraform projects reflect the current state of the various infrastructure pieces.  All secrets are stored in a local instance of Hashicorp Vault, and the Terraform state is stored in a local MinIO instance, using the S3 backend provider in Terraform.

## Scripts ##

The `scripts` directory contains scripts used in the pipelines in this repository.

## Build Pipelines ##

There are a number of Azure DevOps pipeline definitions in this repository, including some template pipelines.  More documentation will be published with details for each.

## Contribution ##

This project is public for reference.  External PRs for changes will be highly scrutizined and most likely not accepted.
