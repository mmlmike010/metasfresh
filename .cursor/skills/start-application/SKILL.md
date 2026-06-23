---
name: start-application
description: Quickly start or shut down the metasfresh application in this repository. Use when the user says "start application", "start app", "run application", "launch metasfresh", "stop app", "shut down app", or asks to bring up or tear down the local metasfresh stack.
---

# Start Application

## Default Behavior

When the user says "start app", "start application", or similar without more detail, start the login-ready Docker stack on nonstandard host ports. Do not start only the frontend dev server by default, because it cannot log in unless a backend API is already running.

When the user says "shut down app", "stop app", "shutdown application", or similar, stop the Docker stack using the shutdown workflow below.

Use `/Users/michaelacsamana/Documents/metasfresh` as the repository root.

## Before Starting

1. Check existing IDE terminals before starting long-running processes. Do not start a duplicate `npm start`, frontend `node server.js`, or infrastructure command if one is already running.
2. Prefer the existing repo commands over inventing new startup scripts.
3. Keep long-running servers in background shell jobs and do one immediate smoke check to ensure they started.
4. Use project name `metasfresh-local-weird` for Docker Compose so the containers are easy to identify and do not collide with other compose projects.

## Nonstandard Local Ports

Use these host ports for the default Docker stack:

- Web UI: `http://localhost:13000`
- Mobile UI: `http://localhost:13001`
- Web API: `http://localhost:18080`
- App API: `http://localhost:18282`
- PostgreSQL: `localhost:15432`
- RabbitMQ AMQP: `localhost:15692`
- RabbitMQ management: `http://localhost:15673`
- Elasticsearch HTTP: `http://localhost:19200`
- Elasticsearch transport: `localhost:19300`
- App debug: `localhost:18788`
- Web API debug: `localhost:18789`

## Docker Stack Start

Use this workflow for the default "start app" command.

1. Ensure `docker-builds/compose/.env` exists with the known matching image set:

```bash
cat > docker-builds/compose/.env <<'EOF'
mfregistry=metasfresh
mfversion=5.175-deep-tundra-release.38193
dbqualifier=preloaded
EOF
```

2. Create local temporary config files so the Docker frontend points at the weird API ports:

```bash
cat > /tmp/metasfresh-web-config.local.js <<'EOF'
const config = {
  API_URL: 'http://localhost:18080/rest/api',
  WS_URL: 'http://localhost:18080/stomp'
}
EOF

cat > /tmp/metasfresh-mobile-config.local.js <<'EOF'
window.config = {
  SERVER_URL: 'http://localhost:18282'
}
EOF
```

3. Create the local Docker Compose override. Use `ports: !override` so the repo's default host ports are replaced rather than merged:

```bash
cat > /tmp/metasfresh-compose-weird-ports.yml <<'EOF'
services:
  db:
    ports: !override
      - "15432:5432"
  rabbitmq:
    ports: !override
      - "15692:5672"
      - "15673:15672"
  search:
    ports: !override
      - "19200:9200"
      - "19300:9300"
  webapi:
    ports: !override
      - "18080:8080"
      - "18789:8789"
  app:
    ports: !override
      - "18282:8282"
      - "18788:8788"
  webui:
    ports: !override
      - "13000:80"
      - "13443:443"
    volumes: !override
      - /tmp/metasfresh-web-config.local.js:/usr/share/nginx/html/config.js:ro
  mobile:
    ports: !override
      - "13001:80"
    volumes: !override
      - /tmp/metasfresh-mobile-config.local.js:/usr/share/nginx/html/config.js:ro
EOF
```

4. Start the login-ready services:

```bash
docker compose \
  -p metasfresh-local-weird \
  -f docker-builds/compose/compose.yml \
  -f /tmp/metasfresh-compose-weird-ports.yml \
  up -d db rabbitmq search app webapi webui mobile
```

5. Verify startup:

```bash
docker compose \
  -p metasfresh-local-weird \
  -f docker-builds/compose/compose.yml \
  -f /tmp/metasfresh-compose-weird-ports.yml \
  ps
```

Then probe:

```bash
curl -fsS http://localhost:18080/health
curl -fsS http://localhost:13000/
```

If the images are missing, Docker will pull them. On Apple Silicon, linux/amd64 platform warnings are expected for these images.

## Docker Stack Shutdown

When the user asks to stop or shut down the app, stop the weird-port Docker stack. Recreate `/tmp/metasfresh-compose-weird-ports.yml` first if it is missing, then run:

```bash
docker compose \
  -p metasfresh-local-weird \
  -f docker-builds/compose/compose.yml \
  -f /tmp/metasfresh-compose-weird-ports.yml \
  down
```

This removes containers and the compose network but preserves Docker volumes. Do not use `down -v` unless the user explicitly asks to reset/delete local app data.

## Docker Stack Reset

Only if the backend is failing because of a stale or mismatched database, ask for explicit user approval before running:

```bash
docker compose \
  -p metasfresh-local-weird \
  -f docker-builds/compose/compose.yml \
  -f /tmp/metasfresh-compose-weird-ports.yml \
  down -v
```

Then start again with the Docker Stack Start workflow. Explain that `down -v` deletes the local compose volumes, including the local PostgreSQL data.

## Frontend Quick Start

Use this only when the user explicitly asks for the frontend dev server. It is not the default because `server.js` is hardcoded to port `3000` and needs a backend on `8080` unless `frontend/config.js` is changed.

Run these from `frontend`:

```bash
npm install
cp config.js.dist config.js
npm start
```

Practical workflow:

1. If `frontend/node_modules` is missing, run `npm install`.
2. If `frontend/config.js` is missing, copy `frontend/config.js.dist` to `frontend/config.js`.
3. For current local Node 25, prefer Node 16 via `npx` plus polling watchers:

```bash
cd /Users/michaelacsamana/Documents/metasfresh/frontend
CHOKIDAR_USEPOLLING=true WATCHPACK_POLLING=true npx -y node@16 server.js
```

4. Start the dev server with `npm start` only if the local Node version is compatible.
5. Tell the user the frontend should be available from the URL printed by the server output. The README says local production serving uses `localhost:8080`; do not promise the dev port unless the command output confirms it.
6. After the server starts, send a chat response that clearly says it started and how to sign in.

## Infrastructure

The local infrastructure lives in:

```bash
/Users/michaelacsamana/Documents/metasfresh/misc/dev-support/docker/infrastructure/scripts
```

Use these existing scripts:

```bash
./93_status.sh [env-name]
./95_start.sh [env-name]
./00_cmd.sh [env-name] logs -f db
```

If no env name is supplied, the scripts try to auto-detect one from the current git branch prefix. Known env files include `default.env`, `master.env`, `release.env`, and multiple `*_uat.env` files.

For a quick non-destructive infrastructure start, run:

```bash
./95_start.sh default
```

If containers have never been created, `95_start.sh` may not be enough. Ask before running:

```bash
./10_reset_db_to_seed_dump.sh default
```

This reset script brings the Docker Compose stack up but deletes the matching PostgreSQL and Elasticsearch Docker volumes first, so it requires explicit user approval.

## Backend Notes

Backend Java apps are documented via IntelliJ run configurations under `misc/dev-support/idea-runConfigurations`, including:

- `ServerBoot - new_dawn_uat.run.xml`
- `WebRestApiApplication - new_dawn_uat.run.xml`

If the user asks for the full stack, start the frontend and infrastructure first, then mention that backend services appear to be intended to run from the provided IntelliJ Spring Boot configurations unless the user wants a terminal-based Java launch workflow.

## Sign In Details

For the default weird-port Docker stack:

- Web UI: `http://localhost:13000`
- Username: `metasfresh`
- Password: `metasfresh`
- Mobile UI: `http://localhost:13001`
- Mobile username: `cynthia`
- Mobile password: `metasfresh`
- API health: `http://localhost:18080/health`

For the frontend dev server, use the URL printed by `npm start`. If the frontend points at a local seeded metasfresh backend, try the same `metasfresh` / `metasfresh` credentials.

## Response Style

While starting the app, give short progress updates:

- Existing process found, reusing it.
- Creating weird-port Docker override.
- Pulling Docker images.
- Starting Docker services.
- Waiting for API health.

While shutting down the app, give short progress updates:

- Stopping weird-port Docker stack.
- Preserving Docker volumes.

When done, summarize what is running and include any URLs or ports shown by the command output. Always include a direct confirmation and sign-in instructions.

Use this final response shape:

```markdown
Started the application.

Web UI: `http://localhost:13000`
Mobile UI: `http://localhost:13001`
API health: `http://localhost:18080/health`

Sign in:
- Username: `metasfresh`
- Password: `metasfresh`

Shutdown command:
`docker compose -p metasfresh-local-weird -f docker-builds/compose/compose.yml -f /tmp/metasfresh-compose-weird-ports.yml down`
```

For shutdown, use this final response shape:

```markdown
Shut down the application.

The weird-port Docker stack is stopped. Local Docker volumes were preserved.
```

If startup fails, do not say it started. Instead, report the failing command, the useful error lines, and the next concrete fix.
