#!/bin/bash
set -e

STEAMCMD_DIR="/home/steam/steamcmd"
SERVER_DIR="/home/steam/trenchblocks_server"

# Step 1: Download or update Trenchblocks Dedicated Server via SteamCMD
${STEAMCMD_DIR}/steamcmd.sh +force_install_dir "${SERVER_DIR}" +login anonymous +app_update "${STEAM_APP_ID}" validate +quit

# Step 2: Create symlinks for Steam SDK libraries (required for Unreal Engine Steam integration)
mkdir -p /home/steam/.steam/sdk64 /home/steam/.steam/sdk32
if [ -f "${STEAMCMD_DIR}/linux64/steamclient.so" ]; then
    ln -sf "${STEAMCMD_DIR}/linux64/steamclient.so" /home/steam/.steam/sdk64/steamclient.so
fi
if [ -f "${STEAMCMD_DIR}/linux32/steamclient.so" ]; then
    ln -sf "${STEAMCMD_DIR}/linux32/steamclient.so" /home/steam/.steam/sdk32/steamclient.so
fi

# Step 3: Locate project config directory and generate DefaultServerSettings.ini from environment variables
PROJECT_DIR="${SERVER_DIR}/Trenchblocks"
if [ -d "${PROJECT_DIR}" ]; then
    CONFIG_DIR="${PROJECT_DIR}/Config"
else
    CONFIG_DIR="${SERVER_DIR}/Config"
fi
mkdir -p "${CONFIG_DIR}"
CONFIG_FILE="${CONFIG_DIR}/DefaultServerSettings.ini"

cat <<EOF > "${CONFIG_FILE}"
[/Script/Trenchblocks.TrenchblocksServerSettings]
ServerName=${SERVER_NAME:-Trenchblocks Server}
MaxPlayers=${MAX_PLAYERS:-32}
MaxPing=${MAX_PING:-150}
MaxGrenades=${MAX_GRENADES:-2}
RespawnTime=${RESPAWN_TIME:-5.000000}
SpawnProtectionTime=${SPAWN_PROTECTION_TIME:-3.000000}
RoundTime=${ROUND_TIME:-1800.000000}
bVacEnabled=${VAC_ENABLED:-True}
Gamemode=${GAMEMODE:-TDM}
MOTD=${MOTD:-Play fair.}
bFriendlyFire=${FRIENDLY_FIRE:-False}
bDestructionEnabled=${DESTRUCTION_ENABLED:-True}
TeamAName=${TEAM_A_NAME:-Red}
TeamBName=${TEAM_B_NAME:-Blue}
TeamAColor=${TEAM_A_COLOR:-(R=1.000000,G=0.098958,B=0.098958,A=1.000000)}
TeamBColor=${TEAM_B_COLOR:-(R=0.000000,G=0.347836,B=1.000000,A=1.000000)}
!MapRotation=ClearArray
EOF

# Parse comma-separated MAP_ROTATION
IFS=',' read -ra MAPS <<< "${MAP_ROTATION:-builtin:Arena01}"
for map in "${MAPS[@]}"; do
    clean_map=$(echo "$map" | xargs)
    if [ -n "$clean_map" ]; then
        echo "+MapRotation=${clean_map}" >> "${CONFIG_FILE}"
    fi
done

cat <<EOF >> "${CONFIG_FILE}"
!AdminList=ClearArray
EOF

# Parse comma-separated ADMIN_LIST
if [ -n "${ADMIN_LIST}" ]; then
    IFS=',' read -ra ADMINS <<< "${ADMIN_LIST}"
    for admin in "${ADMINS[@]}"; do
        clean_admin=$(echo "$admin" | xargs)
        if [ -n "$clean_admin" ]; then
            echo "+AdminList=${clean_admin}" >> "${CONFIG_FILE}"
        fi
    done
fi

cat <<EOF >> "${CONFIG_FILE}"
SessionPassword=${SESSION_PASSWORD:-}
VoiceChatMode=${VOICE_CHAT_MODE:-Proximity}
VoiceMaxHearingRange=${VOICE_MAX_HEARING_RANGE:-5000.000000}
VoiceMaxConcurrentGlobalTalkers=${VOICE_MAX_CONCURRENT_GLOBAL_TALKERS:-8}
VoiceRelevancyUpdateInterval=${VOICE_RELEVANCY_UPDATE_INTERVAL:-0.200000}
WorkshopContentDepotId=${WORKSHOP_CONTENT_DEPOT_ID:-0}
WorkshopContentDir=${WORKSHOP_CONTENT_DIR:-}
!WorkshopSearchDirs=ClearArray
EOF

# Parse comma-separated WORKSHOP_SEARCH_DIRS
if [ -n "${WORKSHOP_SEARCH_DIRS}" ]; then
    IFS=',' read -ra WDIRS <<< "${WORKSHOP_SEARCH_DIRS}"
    for wdir in "${WDIRS[@]}"; do
        clean_wdir=$(echo "$wdir" | xargs)
        if [ -n "$clean_wdir" ]; then
            echo "+WorkshopSearchDirs=${clean_wdir}" >> "${CONFIG_FILE}"
        fi
    done
fi

# Step 4: Find Unreal Engine Linux server executable
EXEC_FILE=$(find "${SERVER_DIR}" -maxdepth 3 -type f \( -name "*Server.sh" -o -name "TrenchblocksServer" -o -name "*Server" \) ! -name "*.so*" | head -n 1)

if [ -z "${EXEC_FILE}" ]; then
    echo "ERROR: Server binary not found in ${SERVER_DIR}"
    ls -la "${SERVER_DIR}"
    exit 1
fi

chmod +x "${EXEC_FILE}"

export LD_LIBRARY_PATH="/home/steam/.steam/sdk64:${STEAMCMD_DIR}/linux64:${LD_LIBRARY_PATH}"

# Step 5: Launch dedicated server
exec "${EXEC_FILE}" -Port="${SERVER_PORT}" -QueryPort="${QUERY_PORT}" ${SERVER_ARGS}
