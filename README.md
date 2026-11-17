# Spare-API-Sample
A quick showcase of an assignment requested by Spare Technologies

# Contents
The repository consists of the resources needed to create a containerized API application as well as a Compose setup for running the stack locally. The goal is to create a production-grade application that follows an adequate amount of security and DevOps best practices whilst still being flexible and easy-to-understand. 

# Quick-start
You will need a container runtime (Docker/Podman) and its relevant compose component (docker-compose or podman-compose)
```bash
# Create your local environment file (use the provided sample as a foundation if needed)
cp .env.example .env

# Build and start the API and database
./scripts/ops.sh up
```

# Containerization Theory
When an application is containerized, they are typically built upon base images such as Alpine or Ubuntu. As this task is meant to simulate a deployment for a fintech company, security and compliance came at the forefront of my design. For this reason, I have opted to use Red Hat Hardened Images for their resilience and security-first approach to development. They act as minimal hardened images that are regularly tested and inspected for enhanced security.

Although the task stipulated that the created image and orchestration be run on Docker, I have also taken into consideration the possibility of running these containers on Podman instead. This is to account for any setups that require even more security (daemonless/rootless containers) or for those that run their workloads on Red Hat aligned setups. Any Podman-specific adjustments or caveats will be noted in the relevant sections.

# Dockerfile contents
The provided Dockerfile containerizes a minimal Node.js + Express API setup using hardened images in two stages. The first stage takes a comprehensive "builder" image to act as the environment in which to install the needed dependencies. The second stage strips down the resulting image to improve security and reduce its size.

It is important to note that should Podman be used, the "docker" format must be specified for the included healthcheck to function, otherwise it will print a warning.

# compose.yml contents
The provided docker-compose.yml file orchestrates the deployment of the API service as a multi-container application using a hardened PostgreSQL database alongside the creation of a dedicated network and volume provisions.

When using Podman as the container runtime, it is important to note that the API container stops should the database also stop. This is treated as an intentional shutdown, so a restart will not occur and the database must be started manually.

# Operations script
Also provided is a bash script that allows operators to manage the stack without having to manually input the needed commands. The script is also tailored to function with both Podman and Docker, and will prioritize Podman if both runtimes are detected due to its more secure nature.

Usage:
```bash
/scripts/ops.sh [FUNCTION]
```

| FUNCTION | What it does |
|---------|--------------|
| `up` | Starts the stack |
| `down` | Stops the stack |
| `status` | Shows the health of the service |
| `logs` | Stows the 50 newest log entries |
| `smoke` | Runs basic API checks |

# AI Disclaimer
AI was used to assist with providing templates and clarifications regarding aspects I am unfamiliar with (such as GitHub Actions) that I then adjusted and double-checked. I am nominally not an application developer, but all configurations and design decisions are my own.
