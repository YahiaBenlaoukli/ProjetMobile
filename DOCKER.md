# Docker Setup & Usage Guide

This project includes a Docker setup that builds the Flutter application for the **Web** and serves it using a lightweight Nginx web server. This ensures a fast, efficient, and standardized deployment.

## 📋 Prerequisites

Before running the project using Docker, ensure you have the following installed and running on your system:
- **Docker Desktop** (for Windows / macOS) or Docker Engine (for Linux).
- Ensure the Docker Daemon is actively running.

---

## 🛠️ Building the Docker Image

To build the Docker image for the first time, open your terminal at the root of the project (where the `Dockerfile` is located) and run:

```bash
docker build -t projet_mob_dev_web .
```

*Note: The first build may take a few minutes as it downloads the pre-built Flutter image, compiles the Dart code into JavaScript, and prepares the Nginx container.*

---

## 🚀 Running the Docker Container

Once the image is built, you can run it as a container in the background (detached mode) and map port `8080` on your machine to port `80` in the container:

```bash
docker run -d -p 8080:80 --name projet_mob_dev_web_container projet_mob_dev_web
```

### 🌐 Accessing the Application
After starting the container, open your web browser and navigate to:
👉 **[http://localhost:8080](http://localhost:8080)**

---

## 🔧 Managing the Container

Here are some helpful commands to manage your running Docker container:

**Stop the running container:**
```bash
docker stop projet_mob_dev_web_container
```

**Start the stopped container:**
```bash
docker start projet_mob_dev_web_container
```

**View the server logs:**
```bash
docker logs projet_mob_dev_web_container
```

**Remove the container (make sure it's stopped first):**
```bash
docker rm projet_mob_dev_web_container
```

**Remove the built Docker image:**
```bash
docker rmi projet_mob_dev_web
```

---

## ⚙️ How It Works (Multi-Stage Build)
1. **Stage 1 (Build):** The Dockerfile uses `ghcr.io/cirruslabs/flutter:stable`, pulls the necessary Flutter dependencies (`flutter pub get`), and builds the web application (`flutter build web`).
2. **Stage 2 (Serve):** It transfers the compiled web assets into a minimalistic `nginx:alpine` image. This dramatically reduces the final image size and serves your web app extremely fast.
