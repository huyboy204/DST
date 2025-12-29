# 🎮 Don't Starve Together - Production Ready

## ✅ All Components Finalized

### Docker Infrastructure
- ✅ **Dockerfile** - Optimized Ubuntu 22.04 with proper i386 and amd64 libraries
- ✅ **docker-compose.yml** - Production configuration with GHCR image
- ✅ **docker-compose.local.yml** - Local build configuration
- ✅ **.dockerignore** - Optimized build context

### Configuration System
- ✅ **Templates** - envsubst-based dynamic configuration
  - `cluster.ini.template`
  - `master_server.ini.template`
  - `caves_server.ini.template`
- ✅ **Default configs** - Pre-configured in `config/` directory
- ✅ **.env.example** - Complete environment variable reference

### Server Management
- ✅ **start_server.sh** - Robust startup with retry logic and error handling
- ✅ **healthcheck.sh** - Process monitoring for both shards
- ✅ **Graceful shutdown** - Configurable timeout with auto-save
- ✅ **Auto-update** - SteamCMD integration with cleanup and retry

### CI/CD Pipeline
- ✅ **GitHub Actions** - Automated build and push to GHCR
- ✅ **Multi-tag support** - latest, semver, branch tags
- ✅ **Cache optimization** - Fast rebuilds with layer caching

### Documentation
- ✅ **README.md** - Comprehensive setup guide
- ✅ **DEPLOYMENT.md** - Production checklist
- ✅ **.gitignore** - Protects sensitive data

## 🚀 Production Features

### Reliability
- Automatic container restart on failure
- Health checks every 60 seconds
- Retry logic for SteamCMD failures
- Proper error messages and troubleshooting hints

### Performance
- Configurable tick rate (15-60)
- Optimized Docker image (~500MB)
- Persistent volumes for fast restarts
- Multi-threaded server support

### Security
- No hardcoded credentials
- .env file for secrets
- Read-only config mounts
- Proper user permissions (steam user)

### Maintenance
- Easy log access via `docker logs`
- Hot-reload configuration support
- Automated updates optional
- Simple backup via tar

## 📦 Image Details

- **Registry**: `ghcr.io/huyboy204/dst:latest`
- **Platform**: linux/amd64 (x86_64)
- **Base**: Ubuntu 22.04
- **Size**: ~500MB (compressed)
- **Updates**: Automatic on push to main

## 🎯 Deployment Options

### 1. Production (Pre-built Image)
```bash
docker compose up -d
```

### 2. Development (Local Build)
```bash
docker compose -f docker-compose.local.yml up -d
```

### 3. Standalone Docker
```bash
docker run -d -p 10999:10999/udp -p 11000:11000/udp \
  -e CLUSTER_TOKEN="your_token" \
  -v ./data:/home/steam/.klei/DoNotStarveTogether/MyDediServer \
  ghcr.io/huyboy204/dst:latest
```

## 🌍 Port Configuration

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| 10999 | UDP | Master shard | ✅ Yes |
| 11000 | UDP | Caves shard | ✅ Yes |

Internal ports (no forwarding needed):
- 12345-12348/UDP - Steam authentication
- 10888/UDP - Shard communication

## ⚙️ Environment Variables

All variables have sensible defaults. Only `CLUSTER_TOKEN` is required.

```bash
CLUSTER_TOKEN=          # Required - from Klei account
CLUSTER_NAME=           # Default: "My DST Server"
CLUSTER_DESCRIPTION=    # Default: "A Don't Starve Together Server"
CLUSTER_PASSWORD=       # Default: empty (no password)
MAX_PLAYERS=            # Default: 6
GAME_MODE=              # Default: survival (survival/endless/wilderness)
AUTO_UPDATE=            # Default: true
TICK_RATE=              # Default: 15 (higher = better performance, max 60)
SHUTDOWN_TIMEOUT=       # Default: 30 seconds
```

## 🔧 Tested Platforms

✅ **Working**:
- x86_64 Linux servers (AWS, DigitalOcean, etc.)
- Intel/AMD desktop processors
- Cloud hosting providers

⚠️ **Limited Support**:
- Apple Silicon (M1/M2/M3) - Requires emulation, may have performance issues

## 📊 Resource Requirements

### Minimum
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 5GB
- **Network**: 10 Mbps upload

### Recommended
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disk**: 10GB
- **Network**: 25 Mbps upload

## 🎉 Ready for Production!

This setup is production-ready and includes:
- ✅ Automated CI/CD pipeline
- ✅ Health monitoring
- ✅ Graceful shutdown handling
- ✅ Comprehensive documentation
- ✅ Error handling and retry logic
- ✅ Security best practices
- ✅ Easy configuration management
- ✅ Public container registry

Deploy with confidence! 🚀
