# Deployment guide

This guide describes a small production deployment with the backend services on
a Linux host running Docker Compose and the frontend served as a static site.
The Docker Compose file runs Redis and the backend; it does not build or serve
the frontend.

## 1. Prepare services and credentials

You will need:

- A Linux server with Docker Engine and the Docker Compose plugin.
- A domain name and HTTPS for the frontend and API.
- MongoDB connection strings for the auth, project, file, AI, terminal, and
  payment services. MongoDB Atlas or another managed MongoDB provider is
  suitable. Configure its network allowlist for the server and use a dedicated
  database user with only the required permissions.
- An OpenRouter API key if AI features are required.
- Razorpay test or live keys if payments are required.
- A Firebase Admin service-account JSON file for the auth service.
- A Firebase Web API key for the frontend, and the frontend domain registered
  in Firebase Authentication's authorized domains.

Do not commit credentials or put server secrets in frontend `VITE_*` variables.
Vite embeds those variables in publicly downloadable frontend assets.

## 2. Configure backend environment

On the server, clone or copy the project. Create `backend/.env` (next to
`docker-compose.prod.yml`) with the following values:

```dotenv
FRONTEND_URL=https://app.example.com
MONGODB_URI_AUTH=mongodb+srv://...
MONGODB_URI_PROJECT=mongodb+srv://...
MONGODB_URI_FILE=mongodb+srv://...
MONGODB_URI_AI=mongodb+srv://...
MONGODB_URI_TERMINAL=mongodb+srv://...
MONGODB_URI_PAYMENT=mongodb+srv://...
OPENROUTER_API_KEY=...
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
```

Use URL-encoded special characters in MongoDB usernames and passwords. Use
Razorpay test credentials for a test deployment and live credentials only for
production.

The auth service currently imports
`backend/services/auth/serviceAccountKey.json`. Place the Firebase Admin
service-account file at that exact path on the server before building. Restrict
file access to the deployment account. **The current auth Dockerfile copies
this file into the built image. Do not publish that image to a registry or
share it.** For a registry-based or multi-host deployment, first change the
auth service to load the credential from a mounted secret or a cloud secret
manager instead of bundling it in the image.

Keep `.env` and the service-account JSON out of version control and backups
that are accessible to untrusted users. If either credential file is exposed,
rotate its credentials.

## 3. Start the backend

From the `backend` directory on the server:

```sh
docker compose -f docker-compose.prod.yml config
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps
```

Check startup logs if a service is unhealthy or exits:

```sh
docker compose -f docker-compose.prod.yml logs --tail=100
docker compose -f docker-compose.prod.yml logs --tail=100 auth
```

The gateway listens on port `8000`. Allow public access to that port only when
the reverse proxy must reach it. The production Compose file currently
publishes Redis on port `6379`; block that port from the public internet in the
server firewall. Redis should only be reachable by the backend containers.
The Compose configuration does not currently persist Redis data across
container replacement; do not rely on it for durable storage.

## 4. Build and host the frontend

Configure these frontend build variables in the static host's environment:

```dotenv
VITE_SERVER_URL=https://api.example.com
VITE_TERMINAL_SERVICE_URL=https://api.example.com
VITE_FIREBASE_API_KEY=...
```

Both service URLs should use the public gateway origin. The gateway proxies
`/api/*` and Socket.IO at `/socket.io`, including the terminal WebSocket.

Build and deploy the `frontend` directory using a static hosting provider that
supports Vite, or build it locally and upload the generated `frontend/dist`
directory:

```sh
cd frontend
npm ci
npm run build
```

Configure the static host to serve `dist/index.html` for client-side routes.
In Firebase Authentication, add the frontend's public hostname to the
authorized domains. Set `FRONTEND_URL` to the exact frontend origin (scheme
and hostname, without a path) and redeploy the backend if it changes.

## 5. Configure HTTPS and reverse proxy

Point `app.example.com` to the static frontend and `api.example.com` to the
server. Terminate HTTPS at a managed edge or reverse proxy such as Caddy or
Nginx, and proxy API requests to the gateway on port `8000`.

The API proxy must preserve the `/api` path and forward WebSocket upgrade
requests for `/socket.io`; otherwise the terminal will not connect. Do not
expose the internal service ports `8001` through `8006` publicly. The gateway
uses credentialed cookies, so use HTTPS and ensure the proxy forwards the
original host and scheme.

## 6. Update and operate

After deploying a new version of the source:

```sh
cd backend
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps
```

To stop the backend containers without deleting their named/anonymous Docker
volumes:

```sh
docker compose -f docker-compose.prod.yml down
```

Back up managed MongoDB databases using the provider's backup tools. Monitor
container logs and service health, and keep the host, Docker, and application
dependencies updated.
