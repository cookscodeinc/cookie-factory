---
layout: "default"
title: "Container Workflow"
description: "Develop and verify Cookie Factory through its Compose services."
author: "Jared W. Cook"
nav_order: 1
parent: "Tutorials"
---

## Container workflow

The Compose model uses one pinned toolchain image with services that apply
different permissions and network boundaries.

| Service     | Purpose                                        | Network  |
| ----------- | ---------------------------------------------- | -------- |
| `dev`       | Interactive VS Code and formatting environment | Enabled  |
| `hooks`     | Full pre-commit policy                         | Disabled |
| `lint`      | Repository lint suite                          | Disabled |
| `test`      | All enabled bake suites and integration checks | Disabled |
| `site-test` | Generated and committed Jekyll builds          | Enabled  |

Build the image once, then use the focused target for the task:

```shell
make build
make lint
make test
make site-test
```

Before handing off changes to the container or generation logic, run:

```shell
make verify
```

Test services mount source and all template inputs read-only, run with dropped
Linux capabilities, and use disposable output directories. They do not receive
the Docker socket, host home directory, SSH keys, or cloud credentials.
