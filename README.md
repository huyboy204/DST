# Don't Starve Together Dedicated Server - Docker

A comprehensive Docker container solution for hosting a Don't Starve Together (DST) dedicated server with SteamCMD, featuring dual-shard support (Master + Caves), automated updates, health monitoring, and easy configuration.

## Features

- ✅ **Dual-Shard Support**: Both Overworld (Master) and Caves shards running simultaneously
- ✅ **SteamCMD Integration**: Automated server installation and updates
- ✅ **Health Monitoring**: Docker health checks with automatic restart on failure
- ✅ **Persistent Storage**: Game saves and configurations preserved across restarts
- ✅ **Easy Configuration**: Environment variables and config files for customization
- ✅ **Graceful Shutdown**: Proper save handling when stopping the server
- ✅ **Port Management**: All 7 UDP ports properly configured
- ✅ **Mod Support**: Ready for custom mods (configuration structure included)

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- At least 2GB RAM
- 5GB free disk space
- A Klei account and cluster token

## Quick Start

### 1. Get Your Cluster Token

1. Visit [https://accounts.klei.com/account/game/servers?game=DontStarveTogether](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)
2. Log in with your Klei account
3. Click "Add New Server" or use an existing token
4. Copy the cluster token (it's a long string like `pds-g^KU_aBcDeFg...`)

### 2. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env and set your CLUSTER_TOKEN
```

### 3. Create Required Directories

```bash
mkdir -p data
chmod 777 data
```

### 4. Start the Server

Using Docker Compose (recommended):
```bash
docker compose up -d
```

Or using Docker directly:
```bash
docker pull ghcr.io/huyboy204/dst:latest
docker run -d \
  --name dst-dedicated-server \
  -p 10999:10999/udp \
  -p 11000:11000/udp \
  -e CLUSTER_TOKEN="your_token_here" \
  -v $(pwd)/data:/home/steam/.klei/DoNotStarveTogether/MyDediServer \
  ghcr.io/huyboy204/dst:latest
```

### 5. View Logs

```bash
docker logs -f dst-dedicated-server
```

### 6. Configure Port Forwarding

For internet access, forward these ports on your router to your Docker host:

| Port | Protocol | Purpose |
|------|----------|---------|
| **10999** | **UDP** | **Master shard (REQUIRED)** |
| **11000** | **UDP** | **Caves shard (REQUIRED)** |

**Note**: Ports 12345-12348 and 10888 are for internal Steam/shard communication and do NOT need port forwarding.

## Server Management

### Stop the Server

```bash
docker-compose down
```

This will gracefully shut down both shards, saving the game state.

### Restart the Server

```bash
docker-compose restart
```

### Update the Server

```bash
docker-compose down
docker-compose pull
docker-compose up -d
```

Or set `AUTO_UPDATE=true` in your environment variables (enabled by default).

### View Server Status

```bash
docker-compose ps
docker inspect dst-dedicated-server | grep Health -A 10
```

## Advanced Configuration

### Custom Configuration Files

To use custom server configurations:

1. Edit files in the `config/` directory:
   - `config/cluster.ini` - Cluster-wide settings
   - `config/Master/server.ini` - Master shard settings
   - `config/Caves/server.ini` - Caves shard settings
   - `config/Master/worldgenoverride.lua` - Overworld generation
   - `config/Caves/worldgenoverride.lua` - Caves generation

2. Rebuild and restart:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### World Generation Options

Edit `worldgenoverride.lua` files to customize:

- World size: `"small"`, `"medium"`, `"default"`, `"huge"`
- Resource abundance: `"never"`, `"rare"`, `"default"`, `"often"`, `"always"`
- Season length: `"noseason"`, `"veryshortseason"`, `"shortseason"`, `"default"`, `"longseason"`, `"verylongseason"`, `"random"`
- Mob spawns, boss spawns, caves settings, etc.

**Example** - More resources:
```lua
overrides = {
    world_size = "default",
    grass = "often",
    sapling = "often",
    berrybush = "often",
    -- ... other settings
}
```

### Installing Mods

1. Create `mods/dedicated_server_mods_setup.lua`:
   ```lua
   ServerModSetup("workshop-mod-id-here")
   ServerModSetup("another-workshop-id")
   ```

2. Create `config/Master/modoverrides.lua` and `config/Caves/modoverrides.lua`:
   ```lua
   return {
       ["workshop-mod-id"] = { enabled = true },
   }
   ```

3. Restart the server to download and enable mods.

### Admin Commands

Connect to your server in-game, then press `` ` `` (backtick) to open the console:

```lua
-- Make yourself admin (use your Klei User ID)
c_save()  -- Save the game
c_rollback(1)  -- Rollback 1 save
c_regenerateworld()  -- Regenerate the world
c_shutdown()  -- Shutdown server
```

For full admin access, add your Klei User ID to `config/adminlist.txt`:
```
KU_AbCdEfGh
```

### Whitelist Players

Create `config/whitelist.txt`:
```
KU_Player1
KU_Player2
```

Then in `cluster.ini`:
```ini
[NETWORK]
whitelist_slots = 2
```

### Backup Server Data

Server data is stored in a Docker volume. To backup:

```bash
# Create backup
docker run --rm \
  -v dst_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/dst-backup-$(date +%Y%m%d-%H%M%S).tar.gz /data

# Restore backup
docker run --rm \
  -v dst_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/dst-backup-YYYYMMDD-HHMMSS.tar.gz -C /
```

## Port Reference

### Complete Port List (All UDP)

| Port | Purpose | Forwarding Required |
|------|---------|---------------------|
| 10999 | Master game port | ✅ YES |
| 11000 | Caves game port | ✅ YES |
| 12345 | Master Steam auth | ❌ NO (internal) |
| 12346 | Master Steam MSP | ❌ NO (internal) |
| 12347 | Caves Steam auth | ❌ NO (internal) |
| 12348 | Caves Steam MSP | ❌ NO (internal) |
| 10888 | Shard communication | ❌ NO (internal) |

### Customizing Ports

Edit `config/Master/server.ini` and `config/Caves/server.ini`:

```ini
[NETWORK]
server_port = 10999  # Change to your desired port (10998-11018 recommended)

[STEAM]
authentication_port = 12345  # Must be unique per shard
master_server_port = 12346   # Must be unique per shard
```

**Important**: Each shard must have unique ports!

## Troubleshooting

### Server doesn't appear in browser

- Ensure ports 10999 and 11000 are forwarded
- Check firewall rules on your router and host machine
- Verify server is running: `docker logs dst-dedicated-server`
- Server ports must be in range 10998-11018 for LAN visibility

### Players can't enter caves

- Port 11000 must be forwarded (not just 10999)
- Check that Caves shard is running: `docker logs dst-dedicated-server | grep Caves`
- Verify shard communication: Both shards should show "Shard server started"

### Authentication errors

- Verify your `CLUSTER_TOKEN` is correct
- Token must not have extra spaces or newlines
- Get a fresh token from Klei if needed

### Server keeps restarting

- Check logs: `docker logs dst-dedicated-server`
- Verify you have enough RAM (minimum 2GB)
- Check disk space: `docker system df`
- Review health check status: `docker inspect dst-dedicated-server`

### Mods not loading

- Verify mod IDs in `dedicated_server_mods_setup.lua`
- Check `modoverrides.lua` in both Master and Caves
- Some mods are not compatible with dedicated servers
- Check logs for mod errors

### World generation failed

- Delete the world and regenerate:
  ```bash
  docker-compose down
  docker volume rm dst_data
  docker-compose up -d
  ```
- Check `worldgenoverride.lua` for syntax errors
- Some presets conflict with custom overrides

### Performance issues

- Increase `TICK_RATE` (default: 15, max: 60)
- Reduce `MAX_PLAYERS`
- Allocate more resources in Docker settings
- Disable unnecessary mods

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `CLUSTER_TOKEN` | **(required)** | Your Klei cluster token |
| `CLUSTER_NAME` | `My DST Server` | Server name in browser |
| `CLUSTER_DESCRIPTION` | `A Don't Starve Together Server` | Server description |
| `CLUSTER_PASSWORD` | *(empty)* | Password protection (leave empty for public) |
| `CLUSTER_INTENTION` | `cooperative` | `cooperative`, `social`, `competitive`, `madness` |
| `MAX_PLAYERS` | `6` | Maximum players (1-64) |
| `GAME_MODE` | `survival` | `survival`, `wilderness`, `endless` |
| `PVP` | `false` | Enable PvP (`true`/`false`) |
| `PAUSE_WHEN_EMPTY` | `true` | Pause when no players (`true`/`false`) |
| `AUTO_UPDATE` | `true` | Auto-update on restart (`true`/`false`) |
| `TICK_RATE` | `15` | Server tick rate (15-60) |

## Server Resources

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 5GB
- **Network**: 10 Mbps upload

### Recommended Requirements
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disk**: 10GB
- **Network**: 25 Mbps upload

### Performance Scaling
- 1-4 players: 2GB RAM
- 5-8 players: 3GB RAM
- 9-16 players: 4GB RAM
- Heavy mods: +1-2GB RAM

## Health Monitoring

The container includes automatic health checks that:

- Run every 60 seconds
- Verify both Master and Caves processes are running
- Automatically restart the container if health check fails 3 times
- Have a 120-second startup grace period

View health status:
```bash
docker inspect dst-dedicated-server --format='{{.State.Health.Status}}'
```

## Logs and Debugging

### View server logs
```bash
docker logs -f dst-dedicated-server
```

### View DST game logs
```bash
docker exec dst-dedicated-server tail -f /home/steam/.klei/DoNotStarveTogether/MyDediServer/Master/server_log.txt
docker exec dst-dedicated-server tail -f /home/steam/.klei/DoNotStarveTogether/MyDediServer/Caves/server_log.txt
```

### Enter container shell
```bash
docker exec -it dst-dedicated-server /bin/bash
```

## Security Considerations

- **Cluster Token**: Keep your token secret! Don't commit it to git.
- **Passwords**: Use strong passwords if enabling `CLUSTER_PASSWORD`
- **Firewall**: Only forward required ports (10999, 11000)
- **Updates**: Keep Docker and the base image updated
- **Admin Access**: Limit admin privileges to trusted players only

## FAQ

**Q: Can I run multiple servers on one host?**
A: Yes! Copy the entire directory and change all ports in both `docker-compose.yml` and config files. Also change the cluster name.

**Q: Does this support mods?**
A: Yes! See the "Installing Mods" section above.

**Q: Can I run only Master (no Caves)?**
A: Yes, but it requires modifying `start_server.sh` to skip the Caves shard and setting `shard_enabled = false` in `cluster.ini`.

**Q: How do I make myself admin?**
A: Add your Klei User ID (starts with `KU_`) to `config/adminlist.txt` and restart the server.

**Q: Can I migrate from an existing server?**
A: Yes! Copy your existing cluster folder to the Docker volume and ensure `cluster_token.txt` is present.

**Q: What's my Klei User ID?**
A: In-game, open console with `` ` `` and type `ThePlayer.userid`. It will show your `KU_xxxxxxxx` ID.

## Contributing

Contributions are welcome! Please:
1. Test your changes thoroughly
2. Update documentation
3. Follow existing code style
4. Create detailed pull requests

## License

This project is provided as-is for hosting Don't Starve Together servers. Don't Starve Together is owned by Klei Entertainment.

## Support

- **Klei Forums**: https://forums.kleientertainment.com/forums/topic/59174-dedicated-server-discussion/
- **DST Wiki**: https://dontstarve.fandom.com/wiki/Guides/Don%E2%80%99t_Starve_Together_Dedicated_Servers
- **Steam Community**: https://steamcommunity.com/app/322330/discussions/

## Acknowledgments

- Klei Entertainment for Don't Starve Together
- Valve for SteamCMD
- The DST community for documentation and guides

---

**Enjoy your Don't Starve Together server!** 🔥🎮
