# Dev Container Setup

> **Experimental**: This is a personal project and is not officially supported by DigitalOcean. APIs may change without notice.

This is part of 3 projects to scale Agentic workflows with DigitalOcean App Platform. The concepts are generic and should work with any PaaS:
- Safe local sandboxing using DevContainers (this repo or [do-app-devcontainer](https://github.com/bikramkgupta/do-app-devcontainer))
- Rapid development iteration using hot reload ([do-app-hot-reload-template](https://github.com/bikramkgupta/do-app-hot-reload-template))
- Disposable environments using sandboxes for parallel experimentation and debugging ([do-app-sandbox](https://github.com/bikramkgupta/do-app-sandbox))

This repo provides a reusable `.devcontainer` setup for **DigitalOcean App Platform developers** who want a realistic, cloud-like development environment on their laptop.

Use this if:
- you are building or operating **DigitalOcean app platform** and want a standard, batteries-included dev environment for your teams, or
- you are an **application developer** and want to spin up all the platform dependencies (databases, queues, object storage, etc.) locally with one command.

All you need on your machine is **Docker (or any Docker-compatible runtime)** installed and running (e.g. Docker Desktop, Orbstack, Moby, or Podman with Docker API). You do **not** need to install Postgres, MongoDB, Kafka, RustFS, or other services manually; they are started for you via Docker Compose when the Dev Container comes up.

Once you open your project in this Dev Container, you should hit the “aha” moment quickly: your editor, runtimes (Node, Python, etc.), and backing services are all wired together and ready to use, without additional local setup.

This configuration uses **Docker Compose Profiles** to manage the various services (databases, message queues, etc.) available in the development environment. This allows you to keep the environment lightweight by only running the services you need.



![Dev Container Architecture](images/devcontainer-architecture.svg)

## Getting Started

1. **Create the folder**  
   At the root of your project, create a `.devcontainer` folder.

2. **Copy the config files**  
   Put these files inside `.devcontainer`:
   - `devcontainer.json`
   - `docker-compose.yml`
   - `postcreate.sh`
   - `.env`

3. **Customize your setup**
   Edit `devcontainer.json` to choose:
   - which services you want (databases, kafka, object storage, etc.)
   - which language/tooling you need (Node, Python, Go, Rust, etc.)

4. **Open the folder in a Dev Container**  
   - Install the **Dev Containers** extension in your IDE (VS Code, Cursor, etc.).
   - Open your project folder in the IDE.
   - Run the Command Palette and choose **“Dev Containers: Open Folder in Container…”** (or the equivalent command in your IDE).

5. **Return to local**  
   When you’re done, either close the IDE or run **“Dev Containers: Reopen Folder Locally”** from the Command Palette.


## Default Features

By default, the app container includes the **Node.js** and **Python** development features.

To install additional languages or tools, open `.devcontainer/devcontainer.json` and update the `features` section and **rebuild the container** for changes to take effect. You can find more available features at [containers.dev/features](https://containers.dev/features).


## Default Services

By default, the following services are enabled via the `COMPOSE_PROFILES` environment variable in `devcontainer.json`:

- **PostgreSQL** (`postgres`)
- **RustFS** (`minio`) - S3-compatible object storage

> **Note:** The `minio` profile name is kept for backward compatibility but uses [RustFS](https://github.com/rustfs/rustfs), a high-performance S3-compatible object storage built in Rust.

## Enabling Additional Services

You can enable additional services in two ways:

### 1. Dynamic Start (Recommended)

Since this Dev Container has **Docker-out-of-Docker** enabled, you can start any service instantly from the terminal without rebuilding the container.

To start a specific service (e.g., MongoDB), run:

```bash
docker compose -f .devcontainer/docker-compose.yml --profile mongo up -d
```

Replace `mongo` with the profile name of the service you want to start.

**Available Profiles:**
- `postgres`
- `mongo`
- `mysql`
- `valkey`
- `kafka`
- `minio` (RustFS - S3-compatible object storage)
- `opensearch`

### 2. Persistent Configuration

To change the default set of services that start when the container opens:

1.  Open `.devcontainer/devcontainer.json`.
2.  Find the `containerEnv` section.
3.  Update the `COMPOSE_PROFILES` variable with a comma-separated list of profiles.

```json
"containerEnv": {
  "COMPOSE_PROFILES": "postgres,mongo,valkey"
}
```

4.  **Rebuild the Container** (Cmd/Ctrl + Shift + P -> "Dev Containers: Rebuild Container") for changes to take effect.

### Container Shutdown Behavior

By default, the `shutdownAction` in `devcontainer.json` is set to `"none"`. This means containers will keep running after you close the IDE. To change this behavior, modify the `shutdownAction` parameter. See comments in `devcontainer.json` for details.

### Docker & Compose Tips

If you're new to Docker or Docker Compose, it's helpful to keep a quick reference handy. Consider creating a custom command file in your IDE for common Docker operations.

### (Optional) Install the DevContainer CLI

If you frequently work with Dev Containers, consider installing the DevContainer CLI (under active development):

```bash
npm install -g @devcontainers/cli
```

## Running Multiple Workspaces

Recommended: use Git worktrees (one folder per branch) and open that folder directly in Cursor/VS Code, then “Reopen in Container.” Docker Compose will prefix containers with the folder name (e.g., `main_app_1`, `feature-x_postgres_1`), keeping worktrees isolated by default.

### Quick start with worktrees
- Create the worktree: `git worktree add ../feature-x origin/feature-x`
- Optional: set a custom prefix in `.devcontainer/.env` for that worktree:
  ```env
  COMPOSE_PROJECT_NAME=my-app-feature-x
  ```
- Open the worktree folder in the IDE and reopen in the container. Each worktree spins up its own containers and volumes.

### Port conflicts
Ports are already dynamic (`127.0.0.1:0:PORT`), so multiple worktrees can run at once. To find host ports:
```bash
docker compose -f .devcontainer/docker-compose.yml ps
docker compose -f .devcontainer/docker-compose.yml port postgres 5432
docker compose -f .devcontainer/docker-compose.yml port minio 9001
```
Inside the container, use service names/standard ports (`postgres:5432`, `minio:9000`).

### More detail
See `docs/worktrees-devcontainer.md` for the full workflow, dynamic port notes, COMPOSE_PROJECT_NAME guidance, and a brief multi-root workspace example (works in VS Code and Cursor).

## Testing Services

This project includes a comprehensive test suite to verify that all services are working correctly. Tests perform full CRUD operations to ensure connectivity and functionality.

### Running Tests

From inside the dev container, run:

```bash
# Test all running services
./tests/run-all-tests.sh --all

# Test specific services
./tests/run-all-tests.sh postgres minio

# List available services
./tests/run-all-tests.sh --list

# Show help
./tests/run-all-tests.sh --help
```

### Available Test Scripts

| Service | Script | What It Tests |
|---------|--------|---------------|
| PostgreSQL | `test-postgres.sh` | Table CRUD, row operations |
| RustFS (S3) | `test-rustfs.sh` | Bucket CRUD, object upload/download |
| MySQL | `test-mysql.sh` | Table CRUD, row operations |
| MongoDB | `test-mongo.sh` | Collection CRUD, document operations |
| Valkey | `test-valkey.sh` | Key/value, hash, list operations |
| Kafka | `test-kafka.sh` | Topic CRUD, produce/consume messages |
| OpenSearch | `test-opensearch.sh` | Index CRUD, document search |

### Test Requirements

Tests use native CLI tools for each service:
- **PostgreSQL**: `psql` (postgresql-client)
- **MySQL**: `mysql` (mysql-client)
- **MongoDB**: `mongosh` (mongodb-mongosh)
- **RustFS**: `aws` CLI (awscli)
- **Valkey**: `valkey-cli` or `redis-cli`
- **Kafka**: Kafka CLI tools (kafka-topics.sh, etc.)
- **OpenSearch**: `curl`

Most tools are available in the dev container. Install any missing ones as needed.

