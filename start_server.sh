#!/bin/bash

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STEAMCMD_DIR="${HOME}/steamcmd"
DST_DIR="${HOME}/dst"
CLUSTER_DIR="${HOME}/.klei/DoNotStarveTogether/MyDediServer"
CONFIG_DIR="${HOME}/config"
TEMPLATE_DIR="${HOME}/templates"
DST_APP_ID="343050"

# Environment variables with defaults
CLUSTER_NAME="${CLUSTER_NAME:-My DST Server}"
CLUSTER_DESCRIPTION="${CLUSTER_DESCRIPTION:-A DST Server}"
CLUSTER_PASSWORD="${CLUSTER_PASSWORD:-}"
CLUSTER_INTENTION="${CLUSTER_INTENTION:-cooperative}"
MAX_PLAYERS="${MAX_PLAYERS:-6}"
GAME_MODE="${GAME_MODE:-survival}"
PVP="${PVP:-false}"
PAUSE_WHEN_EMPTY="${PAUSE_WHEN_EMPTY:-true}"
AUTO_UPDATE="${AUTO_UPDATE:-true}"
TICK_RATE="${TICK_RATE:-15}"
SHUTDOWN_TIMEOUT="${SHUTDOWN_TIMEOUT:-30}"

echo -e "${GREEN}=== Don't Starve Together Dedicated Server ===${NC}"
echo ""

# Check if cluster directory exists but is empty (freshly mounted volume)
if [ -d "${CLUSTER_DIR}" ] && [ -z "$(ls -A ${CLUSTER_DIR} 2>/dev/null)" ]; then
    echo -e "${YELLOW}Detected empty cluster directory (freshly mounted volume)${NC}"
    echo -e "${YELLOW}This is normal for first run - configuration will be generated${NC}"
fi

# Function to gracefully shutdown servers
shutdown() {
    echo -e "${YELLOW}Received shutdown signal. Stopping servers...${NC}"
    
    # Send SIGINT (Ctrl+C) which DST handles more gracefully with auto-save
    # Then wait for save to complete before forcing shutdown
    if [ ! -z "$CAVES_PID" ] && kill -0 $CAVES_PID 2>/dev/null; then
        echo -e "${YELLOW}Stopping Caves shard (PID: $CAVES_PID)...${NC}"
        kill -INT $CAVES_PID
    fi
    
    if [ ! -z "$MASTER_PID" ] && kill -0 $MASTER_PID 2>/dev/null; then
        echo -e "${YELLOW}Stopping Master shard (PID: $MASTER_PID)...${NC}"
        kill -INT $MASTER_PID
    fi
    
    # Wait up to SHUTDOWN_TIMEOUT seconds for graceful shutdown
    echo -e "${YELLOW}Waiting for servers to save and exit (up to ${SHUTDOWN_TIMEOUT} seconds)...${NC}"
    for i in $(seq 1 $SHUTDOWN_TIMEOUT); do
        CAVES_ALIVE=0
        MASTER_ALIVE=0
        
        [ ! -z "$CAVES_PID" ] && kill -0 $CAVES_PID 2>/dev/null && CAVES_ALIVE=1
        [ ! -z "$MASTER_PID" ] && kill -0 $MASTER_PID 2>/dev/null && MASTER_ALIVE=1
        
        if [ $CAVES_ALIVE -eq 0 ] && [ $MASTER_ALIVE -eq 0 ]; then
            echo -e "${GREEN}Servers stopped gracefully.${NC}"
            exit 0
        fi
        sleep 1
    done
    
    # Force kill if still running after timeout
    echo -e "${YELLOW}Timeout reached (${SHUTDOWN_TIMEOUT}s). Force stopping remaining processes...${NC}"
    [ ! -z "$CAVES_PID" ] && kill -0 $CAVES_PID 2>/dev/null && kill -9 $CAVES_PID 2>/dev/null || true
    [ ! -z "$MASTER_PID" ] && kill -0 $MASTER_PID 2>/dev/null && kill -9 $MASTER_PID 2>/dev/null || true
    
    echo -e "${GREEN}Servers stopped.${NC}"
    exit 0
}

# Trap signals for graceful shutdown
trap shutdown SIGTERM SIGINT

# Validate cluster token
if [ -z "$CLUSTER_TOKEN" ]; then
    echo -e "${RED}ERROR: CLUSTER_TOKEN is not set!${NC}"
    echo "Please get your cluster token from: https://accounts.klei.com/account/game/servers?game=DontStarveTogether"
    echo "Set it in docker-compose.yml or pass it as an environment variable."
    exit 1
fi

echo -e "${GREEN}Step 1: Setting up cluster token...${NC}"

# Write cluster token
echo "$CLUSTER_TOKEN" > "${CLUSTER_DIR}/cluster_token.txt" || {
    echo -e "${RED}ERROR: Cannot write cluster token to ${CLUSTER_DIR}/cluster_token.txt${NC}"
    echo -e "${YELLOW}This should not happen as permissions are fixed by entrypoint.${NC}"
    echo -e "${YELLOW}Container user: $(whoami) (UID: $(id -u))${NC}"
    echo -e "${YELLOW}Directory: ${CLUSTER_DIR}${NC}"
    ls -la "${CLUSTER_DIR}" 2>/dev/null || echo "Directory doesn't exist"
    exit 1
}

# Copy or generate configuration files
echo -e "${GREEN}Step 2: Configuring server...${NC}"

# Check if custom config exists
if [ -d "${CONFIG_DIR}" ] && [ "$(ls -A ${CONFIG_DIR})" ]; then
    echo -e "${YELLOW}Found custom configuration. Copying files...${NC}"
    cp -r ${CONFIG_DIR}/* ${CLUSTER_DIR}/
else
    echo -e "${YELLOW}No custom configuration found. Using default configuration...${NC}"
    
    # Ensure Master and Caves directories exist
    mkdir -p "${CLUSTER_DIR}/Master"
    mkdir -p "${CLUSTER_DIR}/Caves"
    
    # Generate cluster.ini using envsubst
    if [ -f "${TEMPLATE_DIR}/cluster.ini.template" ]; then
        envsubst < "${TEMPLATE_DIR}/cluster.ini.template" > "${CLUSTER_DIR}/cluster.ini"
    else
        echo -e "${RED}ERROR: cluster.ini.template not found!${NC}"
        exit 1
    fi

    # Generate Master server.ini if not exists
    if [ ! -f "${CLUSTER_DIR}/Master/server.ini" ]; then
        if [ -f "${TEMPLATE_DIR}/master_server.ini.template" ]; then
            envsubst < "${TEMPLATE_DIR}/master_server.ini.template" > "${CLUSTER_DIR}/Master/server.ini"
        else
            echo -e "${RED}ERROR: master_server.ini.template not found!${NC}"
            exit 1
        fi
    fi

    # Generate Caves server.ini if not exists
    if [ ! -f "${CLUSTER_DIR}/Caves/server.ini" ]; then
        if [ -f "${TEMPLATE_DIR}/caves_server.ini.template" ]; then
            envsubst < "${TEMPLATE_DIR}/caves_server.ini.template" > "${CLUSTER_DIR}/Caves/server.ini"
        else
            echo -e "${RED}ERROR: caves_server.ini.template not found!${NC}"
            exit 1
        fi
    fi
fi

# Update/Install DST Server
if [ "$AUTO_UPDATE" = "true" ]; then
    echo -e "${GREEN}Step 3: Updating Don't Starve Together server...${NC}"
    
    # Retry logic for SteamCMD (sometimes fails on first attempt)
    MAX_RETRIES=3
    RETRY_COUNT=0
    SUCCESS=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo -e "${YELLOW}Attempt $((RETRY_COUNT + 1)) of ${MAX_RETRIES}...${NC}"
        
        # Clean up any partial downloads on retry
        if [ $RETRY_COUNT -gt 0 ]; then
            echo -e "${YELLOW}Cleaning up previous attempt...${NC}"
            rm -rf ${DST_DIR}/steamapps/downloading/* 2>/dev/null || true
            rm -rf ${HOME}/Steam/appcache/* 2>/dev/null || true
        fi
        
        ${STEAMCMD_DIR}/steamcmd.sh \
            +@sSteamCmdForcePlatformType linux \
            +force_install_dir ${DST_DIR} \
            +login anonymous \
            +app_update ${DST_APP_ID} validate \
            +quit
        
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ] && [ -f "${DST_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]; then
            echo -e "${GREEN}Server updated successfully!${NC}"
            SUCCESS=true
            break
        else
            echo -e "${YELLOW}Attempt $((RETRY_COUNT + 1)) failed (exit code: ${EXIT_CODE})${NC}"
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}Waiting 10 seconds before retry...${NC}"
                sleep 10
            fi
        fi
    done
    
    if [ "$SUCCESS" = false ]; then
        echo -e "${RED}Server update failed after ${MAX_RETRIES} attempts!${NC}"
        echo -e "${YELLOW}Possible causes:${NC}"
        echo -e "${YELLOW}  - Steam servers are temporarily unavailable${NC}"
        echo -e "${YELLOW}  - Insufficient disk space${NC}"
        echo -e "${YELLOW}  - Network connectivity issues${NC}"
        echo -e "${YELLOW}Try: docker compose restart${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Step 3: Auto-update disabled. Checking if server is installed...${NC}"
    if [ ! -f "${DST_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]; then
        echo -e "${YELLOW}Server not found. Installing...${NC}"
        
        # Retry logic for initial install
        MAX_RETRIES=3
        RETRY_COUNT=0
        SUCCESS=false
        
        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            echo -e "${YELLOW}Attempt $((RETRY_COUNT + 1)) of ${MAX_RETRIES}...${NC}"
            
            # Clean up any partial downloads on retry
            if [ $RETRY_COUNT -gt 0 ]; then
                echo -e "${YELLOW}Cleaning up previous attempt...${NC}"
                rm -rf ${DST_DIR}/steamapps/downloading/* 2>/dev/null || true
                rm -rf ${HOME}/Steam/appcache/* 2>/dev/null || true
            fi
            
            ${STEAMCMD_DIR}/steamcmd.sh \
                +@sSteamCmdForcePlatformType linux \
                +force_install_dir ${DST_DIR} \
                +login anonymous \
                +app_update ${DST_APP_ID} validate \
                +quit
            
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ] && [ -f "${DST_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]; then
                echo -e "${GREEN}Server installed successfully!${NC}"
                SUCCESS=true
                break
            else
                echo -e "${YELLOW}Attempt $((RETRY_COUNT + 1)) failed (exit code: ${EXIT_CODE})${NC}"
                RETRY_COUNT=$((RETRY_COUNT + 1))
                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                    echo -e "${YELLOW}Waiting 10 seconds before retry...${NC}"
                    sleep 10
                fi
            fi
        done
        
        if [ "$SUCCESS" = false ]; then
            echo -e "${RED}Server installation failed after ${MAX_RETRIES} attempts!${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Server already installed.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Step 4: Starting Don't Starve Together servers...${NC}"
echo -e "${YELLOW}Cluster: ${CLUSTER_NAME}${NC}"
echo -e "${YELLOW}Max Players: ${MAX_PLAYERS}${NC}"
echo -e "${YELLOW}Game Mode: ${GAME_MODE}${NC}"
echo ""

# Start Master shard
echo -e "${GREEN}Starting Master shard...${NC}"
cd ${DST_DIR}/bin64
./dontstarve_dedicated_server_nullrenderer_x64 \
    -console \
    -cluster MyDediServer \
    -shard Master \
    -tick ${TICK_RATE} &
MASTER_PID=$!

echo -e "${GREEN}Master shard started with PID: ${MASTER_PID}${NC}"

# Wait for Master to initialize
echo -e "${YELLOW}Waiting for Master shard to initialize (30 seconds)...${NC}"
sleep 30

# Check if Master is still running
if ! kill -0 $MASTER_PID 2>/dev/null; then
    echo -e "${RED}Master shard failed to start!${NC}"
    exit 1
fi

# Start Caves shard
echo -e "${GREEN}Starting Caves shard...${NC}"
./dontstarve_dedicated_server_nullrenderer_x64 \
    -console \
    -cluster MyDediServer \
    -shard Caves \
    -tick ${TICK_RATE} &
CAVES_PID=$!

echo -e "${GREEN}Caves shard started with PID: ${CAVES_PID}${NC}"
echo ""
echo -e "${GREEN}=== Server is now running ===${NC}"
echo -e "${YELLOW}Master PID: ${MASTER_PID}${NC}"
echo -e "${YELLOW}Caves PID: ${CAVES_PID}${NC}"
echo ""
echo -e "${YELLOW}Port Forwarding Required:${NC}"
echo -e "  - 10999/UDP (Master shard)"
echo -e "  - 11000/UDP (Caves shard)"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo -e "  docker logs -f dst-dedicated-server"
echo ""
echo -e "${YELLOW}To stop the server:${NC}"
echo -e "  docker-compose down"
echo ""

# Wait for both processes
wait $MASTER_PID $CAVES_PID
