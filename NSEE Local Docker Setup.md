# NSEE Local Docker Setup — Chat Notes and Runbook

This README records the local Docker work completed during this chat, the commands used, the issue that prevented browser access, and the next steps needed to run the actual NSEE application.

## 1. Goal

Set up and test Docker locally on Windows using Ubuntu under WSL, before deploying the real NSEE application.

**Important:** The container currently running is a test Nginx image. It is **not** the full NSEE application.

## 2. Local environment

Known from this chat:

- Host: Windows desktop
- Linux environment: Ubuntu on WSL2
- Linux user: `tecresearch`
- Docker Engine: installed and running inside Ubuntu/WSL
- Docker Compose: installed
- Git: installed
- Test repository cloned to: `~/nseeindia-client`
- Test image: `ghcr.io/nsee-india/nsee-ghcr-test:latest`
- Container name: `nsee-test`
- Intended local browser URL: http://localhost:8080

## 3. What was found in the cloned repository

The repository `https://github.com/nsee-india/nseeindia-client` was cloned to:

```bash
~/nseeindia-client
```

The directory listing showed:

```text
.git/
.github/
Dockerfile
README.md
```

The README was about 20 KB and the Dockerfile was 101 bytes. Based on the investigation in this chat, this repository is a documentation/GHCR test repository, not the full NSEE application source.

The local command below returned `No such file or directory`:

```bash
ls -la /opt/nsee
```

That is expected on the local WSL machine unless you create that directory locally. `/opt/nsee` had been discussed as a directory on the VPS, not as an existing local directory.

## 4. Docker setup and image pull

Docker and Git were installed in Ubuntu/WSL. Docker permissions were fixed by adding the Linux user to the Docker group and starting a new group session.

Check versions:

```bash
docker --version
docker compose version
git --version
```

The private GitHub Container Registry test image was pulled successfully after logging in to GHCR:

```bash
docker login ghcr.io -u nsee-india
docker pull ghcr.io/nsee-india/nsee-ghcr-test:latest
docker images
```

The login succeeded and the image was available locally. **Never paste a GitHub token or password into chat.** If authentication is needed again, enter credentials only in the terminal's secure prompt.

The image was listed with an image ID beginning `4573c92ef97a`. Image sizes can vary if a newer build is published.

## 5. Running the test container

The initial command was:

```bash
docker run -d --name nsee-test ghcr.io/nsee-india/nsee-ghcr-test:latest
```

The container started, but `docker ps -a` showed only:

```text
80/tcp
```

This means the container had port 80 internally, but the port was **not published to the host**. Therefore, opening `http://localhost:8080` did not work.

### Fix: publish host port 8080 to container port 80

Remove the old container:

```bash
docker rm -f nsee-test
```

Recreate it with an explicit port mapping:

```bash
docker run -d --name nsee-test -p 8080:80 ghcr.io/nsee-india/nsee-ghcr-test:latest
```

Then verify:

```bash
docker ps
```

Look for a port mapping similar to:

```text
0.0.0.0:8080->80/tcp
```

Now open this URL in your Windows browser:

**http://localhost:8080**

The user confirmed that it was working after the port was published.

## 6. Useful day-to-day commands

### Check running containers

```bash
docker ps
```

### Check all containers, including stopped ones

```bash
docker ps -a
```

### Read test-container logs

```bash
docker logs nsee-test
```

Follow new log messages live:

```bash
docker logs -f nsee-test
```

Press `Ctrl+C` to stop following logs; this does not normally stop the container.

### Stop and start the container

```bash
docker stop nsee-test
docker start nsee-test
```

### Restart the container

```bash
docker restart nsee-test
```

### Check port publishing

```bash
docker port nsee-test
```

Expected mapping:

```text
80/tcp -> 0.0.0.0:8080
```

### Remove the test container

```bash
docker rm -f nsee-test
```

Removing the container does not remove the image. To create it again, use the `docker run` command in Section 5.

### Check locally stored images

```bash
docker images
```

## 7. Troubleshooting `localhost:8080`

If the browser says it cannot connect:

1. Check that the container is running:
   ```bash
   docker ps -a
   ```
2. Confirm that `PORTS` includes `0.0.0.0:8080->80/tcp` (or a corresponding host mapping).
3. Check the logs:
   ```bash
   docker logs nsee-test
   ```
4. Check the published port:
   ```bash
   docker port nsee-test
   ```
5. If the old container has no host-port mapping, recreate it using:
   ```bash
   docker rm -f nsee-test
   docker run -d --name nsee-test -p 8080:80 ghcr.io/nsee-india/nsee-ghcr-test:latest
   ```

If port 8080 is already occupied, choose another host port, for example `-p 8081:80`, and browse to `http://localhost:8081`.

## 8. Current status

- [x] Docker installed in local Ubuntu/WSL
- [x] Docker Engine responding to commands
- [x] Git installed
- [x] Test repository cloned
- [x] GHCR test image pulled
- [x] Nginx test container started
- [x] Port 8080 published to container port 80
- [x] User confirmed local browser access works
- [ ] Actual NSEE application source repository identified
- [ ] Actual application Dockerfile / Compose configuration reviewed
- [ ] Frontend and backend started locally
- [ ] Database and any supporting services configured
- [ ] Application-specific health checks and browser testing completed

## 9. Next steps to run the real NSEE application

1. Sign in to GitHub and open the repositories for the `nsee-india` account:
   https://github.com/nsee-india?tab=repositories
2. Identify the repository containing the real application source code. Do not assume `nseeindia-client` is the app repository; the files seen in this chat indicate it is the test/documentation repository.
3. If the repository is private, make sure the GitHub account you use has access. Do not share access tokens or passwords in chat.
4. Once the correct repository is identified, clone it locally and inspect its files before running it. Look for files such as `package.json`, `pom.xml`, `build.gradle`, `Dockerfile`, `compose.yaml`, or `docker-compose.yml`.
5. Review required environment variables and secrets. Keep real passwords, API keys, and tokens out of Git and out of this README.
6. Create or use a Docker Compose configuration for the actual application and its required services. Do not expose database or Redis ports to the network unless there is a specific, understood need.
7. Start the real app and test its health endpoints and browser UI.

Do not replace the working test container with an assumed application setup until the real source code and its requirements have been identified.

## 10. Reference: VPS notes from the earlier setup

These notes were discussed previously but are **not part of the local WSL Docker container**:

- Domain: `nseeindia.com`
- VPS hostname: `srv2048997.hstgr.cloud`
- VPS address noted earlier: `187.126.122.199`
- Planned server directory: `/opt/nsee`
- Planned architecture: Docker Compose with frontend, backend, PostgreSQL, Redis, and a reverse proxy
- The VPS had no application containers deployed at the time it was checked.

The user requested to do the current work locally. The commands in Sections 4–7 are for the local Ubuntu/WSL terminal; do not run VPS commands unless you intentionally switch to the VPS.

## 11. Security reminders

- Never commit `.env` files containing credentials.
- Never paste GitHub tokens, passwords, private keys, database passwords, or other secrets into chat.
- Use strong, unique passwords for services.
- Keep PostgreSQL and Redis private to the Docker network unless remote access is specifically required and secured.
- The GHCR test image is not proof that the actual NSEE app has been built or deployed.

---

**Last recorded result:** The `nsee-test` Nginx container was running with host port 8080 mapped to container port 80, and the user confirmed the local browser test was working.
