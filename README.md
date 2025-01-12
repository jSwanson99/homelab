# Homelab!

## Description
- This repository contains the terraform files necessary to rebuilt my homelab

## The Bootstrap Problem
### Description of the problem
- The bootstrap problem describes the issue that arises when first setting up a project. I have a tool I want to use
  such as terraform, and it has dependencies (state and secret management). In an ideal world, I would provision these 
  dependencies with terraform.
- Accomplishing the above in a reasonable manner would allow you to quickly rebuild from scratch if necessary
- Ignoring the bootstrap problem introduces the possibility that you may need to untangle this mess after something 
  went wrong (and you are trying to rebuild)
### Solution 
- Separate your infrastructure into layers:
    1. Bootstrap
        - The bootstrap layer is the minimal set of dependencies required to bootstrap you infrastructure such that you
        can use terraform to the extent that you desire. In the case of this repo, this means a VM for vault and postgres.
        - This is a fairly concrete separation, in the sense that this terraform project starts off pointed at local storage. Once
        you are bootstrapped you should sync this state to your remote storage solution
    2. Operational
        - The operational layer describes the required infrastructure to maintain your applications
        - VMs are provisioned here, seperately from their applications
        - This points at the remote storage in step 1, and should only be used after the bootstrap phase is complete
    3. Application
        - The application layer is the most volatile
        - It is only used after the bootstrap and operational layers are setup
        - Config for applications in k8s, source code (possibly submodules), etc
        - VMs not included here

## Repository Structure
./<layer>
  ./deploy
  ./<service_name>
    - config for service here
  ./<service_name>
    - config for service here
  ./<service_name>
    - config for service here
./docs
./templates

## Resource Planning

### Current Constraints
- 16 vcpu
- 24 gb mem
- 1tb ssd

### Plan
- 3x 4vcpu 6gb mem agents
- 1x 2vcpu 2gb mem server
- 1x 2vcpu 4gb mem VM for pg and vault
