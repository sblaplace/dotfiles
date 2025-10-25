#!/usr/bin/env bash

GRAFANA_URL="http://neovenezia.local:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

# Create playlist
curl -X POST "$GRAFANA_URL/api/playlists" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Homelab Monitoring",
    "interval": "30s",
    "items": [
      {
        "type": "dashboard_by_tag",
        "value": "homelab"
      },
      {
        "type": "dashboard_by_tag",
        "value": "overview"
      },
      {
        "type": "dashboard_by_tag",
        "value": "storage"
      }
    ]
  }'