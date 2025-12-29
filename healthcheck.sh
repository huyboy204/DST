#!/bin/bash

# Health check script for DST server
# Verifies that both Master and Caves processes are running

MASTER_RUNNING=$(pgrep -f "dontstarve_dedicated_server.*Master" | wc -l)
CAVES_RUNNING=$(pgrep -f "dontstarve_dedicated_server.*Caves" | wc -l)

if [ "$MASTER_RUNNING" -ge 1 ] && [ "$CAVES_RUNNING" -ge 1 ]; then
    # Both shards are running
    exit 0
else
    # One or both shards are not running
    echo "Health check failed:"
    echo "  Master shard running: $MASTER_RUNNING"
    echo "  Caves shard running: $CAVES_RUNNING"
    exit 1
fi
