# Worktrees + Dev Containers

Use a separate Git worktree per branch and open that folder directly in Cursor/VS Code. Each worktree gets its own dev container, Compose project name, and data, keeping environments isolated.

## Compose project naming
- By default, Docker Compose uses the folder name as the project prefix (e.g., `feature-x_app_1`), which is perfect for worktrees.
- If you need to override it, set `COMPOSE_PROJECT_NAME` in `.devcontainer/.env` (per worktree):
  ```env
  COMPOSE_PROJECT_NAME=my-app-feature-x
  # keep any existing entries, e.g. COMPOSE_PROFILES=app,postgres,minio
  ```
- Keep project names unique per worktree to avoid container/volume clashes.

## Dynamic ports (already enabled)
- Services bind to `127.0.0.1:0:PORT`, letting Docker pick a free host port so multiple worktrees can run at once.
- Find assigned ports:
  ```bash
  docker compose -f .devcontainer/docker-compose.yml ps
  docker compose -f .devcontainer/docker-compose.yml port postgres 5432
  ```
- Inside the container, use service names/standard ports (e.g., `postgres:5432`, `minio:9000`).

## Daily workflow with worktrees
1) Create a worktree folder for a branch:
   ```bash
   git worktree add ../feature-x origin/feature-x  # example
   ```
2) In that folder, ensure `.devcontainer/.env` exists (optional `COMPOSE_PROJECT_NAME` override if you want a custom prefix).
3) Open the worktree folder in Cursor/VS Code and choose “Reopen in Container.” Each worktree spins up its own containers.
4) To inspect host ports: `docker compose -f .devcontainer/docker-compose.yml ps`.
5) To remove when done: `git worktree remove ../feature-x` (and delete the branch if desired).

## Multi-root workspace (optional)
If you open the parent folder containing multiple worktrees, VS Code/Cursor won’t auto-pick a dev container. Use a `.code-workspace` file to list the worktree folders:
```json
{
  "folders": [
    { "name": "main", "path": "main" },
    { "name": "feature-x", "path": "feature-x" }
  ],
  "settings": { "remote.containers.copyGitConfig": true }
}
```
Open the workspace, then pick which folder to reopen in a container. For the simplest workflow, open a single worktree folder instead of the parent.

