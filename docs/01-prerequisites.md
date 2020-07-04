# Prerequisites

## Digital Ocean

This tutorial leverages [Digital Ocean](https://www.digitalocean.com/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up. It would cost less then $2 for a 24 hour period that would take to complete this exercise.

> There is no free tier for Digital Ocean. Make sure that you clean up the resource at the end of the activity to avoid incurring unwanted costs. 

## Digital Ocean CLI

### Install the DO CLI

Follow the DO CLI [documentation](https://github.com/digitalocean/doctl) to install and configure the `doctl` command line utility.

Verify the DO CLI version using:

```
doctl version
```

### Set a Default Compute Region and Zone

This tutorial assumes a default compute region.

Go ahead and set a default compute region:

- for a list of Digital Ocean regions, check [here](https://www.digitalocean.com/docs/platform/availability-matrix/), though *NOTE* that for cli usage, all the regions need to be LOWERCASE

```
DO_REGION=lon1

```

### configure the CLI tool to interact with your account

Follow along with the [documentation](https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/) to generate an access token, then use:

```
doctl auth init
```

to be prompted to enter it so you can interact with the DO API


## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with `synchronize-panes` enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable `synchronize-panes`: `ctrl+b` then `shift :`. Then type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](02-client-tools.md)
