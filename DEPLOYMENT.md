# Production Deployment Checklist

## ✅ Pre-Deployment

- [ ] Get your cluster token from Klei
- [ ] Configure `.env` file with your settings
- [ ] Create and set permissions on data directory: `mkdir -p data && chmod 777 data`
- [ ] Verify Docker is running and has sufficient resources (2GB RAM minimum)
- [ ] Ensure ports 10999 and 11000 are available

## ✅ Deployment Options

### Option 1: Using Pre-built Image (Recommended for Production)

```bash
# 1. Pull the image
docker pull ghcr.io/huyboy204/dst:latest

# 2. Create .env file
cp .env.example .env
# Edit .env with your CLUSTER_TOKEN

# 3. Start server
docker compose up -d

# 4. Monitor logs
docker logs -f dst-dedicated-server
```

### Option 2: Building Locally

```bash
# Use docker-compose.local.yml
docker compose -f docker-compose.local.yml up -d --build
```

## ✅ Post-Deployment

- [ ] Verify both Master and Caves shards started successfully
- [ ] Check server appears in game browser (if ports forwarded)
- [ ] Test connecting to server
- [ ] Configure automatic backups (optional)
- [ ] Set up monitoring/alerts (optional)

## ✅ Port Forwarding (For Internet Access)

Forward these UDP ports on your router:
- **10999** → Docker host IP (Master shard)
- **11000** → Docker host IP (Caves shard)

## ✅ Directory Structure

```
DST/
├── data/                      # Server saves and configs (auto-created)
│   ├── cluster_token.txt
│   ├── cluster.ini
│   ├── Master/
│   │   ├── server.ini
│   │   ├── worldgenoverride.lua
│   │   └── server_log.txt
│   └── Caves/
│       ├── server.ini
│       ├── worldgenoverride.lua
│       └── server_log.txt
├── config/                    # Custom configs (optional)
├── mods/                      # Custom mods (optional)
├── .env                       # Your environment variables
├── docker-compose.yml         # Production compose file
└── README.md
```

## ✅ Maintenance Commands

```bash
# View logs
docker logs -f dst-dedicated-server

# Restart server
docker compose restart

# Stop server
docker compose down

# Update server
docker compose pull
docker compose up -d

# Backup saves
tar -czf dst-backup-$(date +%Y%m%d).tar.gz data/

# Check container health
docker inspect dst-dedicated-server | grep -A 10 Health
```

## ✅ Troubleshooting

### Server won't start
- Check logs: `docker logs dst-dedicated-server`
- Verify CLUSTER_TOKEN is set correctly
- Ensure data directory permissions: `chmod 777 data`

### Can't connect to server
- Verify ports 10999 and 11000 are forwarded
- Check firewall rules
- Confirm server is running: `docker ps`

### Low performance
- Increase TICK_RATE (max 60)
- Reduce MAX_PLAYERS
- Allocate more Docker resources

## ✅ Security Considerations

- Use strong CLUSTER_PASSWORD for public servers
- Keep CLUSTER_TOKEN secret (already in .gitignore)
- Regularly update the Docker image
- Consider using whitelist for private servers
- Enable vote kick (already enabled by default)

## ✅ Production Best Practices

- Use `restart: unless-stopped` policy (already configured)
- Set up automated backups
- Monitor disk space usage
- Use health checks (already configured)
- Keep logs rotated
- Test updates in staging first
