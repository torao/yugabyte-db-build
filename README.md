# yugabyte-db-build

This repository provides a consistent development environment for efficiently modifying, building, and testing the YugabyteDB source code. Using docker containers, you can develop YugabyteDB under the same conditions on any platform.

YugabyteDB is a distributed SQL database developed in C++, and requires an appropriate build environment for source code modification and customization. Differences in the environment used by developers can lead to different results from the same code, hindering efficient development. This repository aims to standardize the development process by providing a consistent YugabyteDB build and test environment using a docker container.

## Putpose

The main purposes of this repository are as follows:

- To simplify the build and testing of YugabyteDB source code and accelerate development
- To provide an environment where all developers can build under the same conditions
- To reduce the effort required for environment setup and enable developers to focus on development
- To make the build and test process productive

What this repository is not:

- It is not the source code for YugabyteDB itserlf
- It is not an execution environment for YugabyteDB
- It is not a deploy tool for YugabyteDB in production environments
- It is not a tutorial on how to use YugabyteDB in general

## Scope

### Target Users

This repository is primarily intended for developers who want to modify or extend the YugabyteDB source code on their company-issued computers.

### Provided features

- A docker image definition based on AlmaLinux 8
- Environment containing all dependencies required to build YugabyteDB
- Configuration to mount and use the local `yugabyte-db` repository

## Requirements

- A host machine with Docker installed (Linux or mac OS)
- Minimum 8 GB of RAM (16 GB or more recommended)
- Minimum 10 GB of free disk space
- Internet connection (for downloading dependencies)
- Git client

### Limitations

Some dependencies may require emulation on ARM architectures (such as M1/M2 Macs).

## How to use

First, clone the YugabyteDB source code locally:

```shell
git clone https://github.com/yugabyte/yugabyte-db.git
cd yugabyte-db
```

After that, modify the YugabyteDB source code if necessary.

Next, mount the YugabyteDB repository and start the container:

```shell
docker run -it --rm --name yugabyte-db-build \
  -e LOCAL_USER_ID=$(id -u) \
  -e LOCAL_GROUP_ID=$(id -g) \
  -e TZ=Asia/Tokyo \
  -v $(pwd):/yugabyte-db \
  yugabyte-db-build
```

Make source modification and execute commands in the `/yugabyte-db` directory inside the container.

```shell
./yb_release
```

See the official document [Build and test](https://docs.yugabyte.com/preview/contribute/core-database/build-and-test/) for what can be done.

## How to build the docker image to build and testing the YugabyteDB

Build the YugabyteDB build environment Docker imge as follows.

```shell
docker build -t yugabyte-db-build:latest .
```

If you are building on an ARM64 environment such as an M1 MacBook using x86_64 emulation, you can create an image like the following. However, segmentation faults may occur when building YugabyteDB.

```shell
docker build --platform linux/amd64 -t yugabyte-db-build:latest .
```
