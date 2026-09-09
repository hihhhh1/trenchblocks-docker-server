# trenchblocks-docker-server
Docker setup for hosting a Trenchblocks dedicated server.

## System requirements
This Docker container runs on any OS that supports Docker, provided it has an Intel or AMD (x86_64) processor.
Docker on ARM or Apple Silicon is not officially supported as SteamCMD Linux binaries are x86/x86_64 only.

### Prerequisites
- Docker (with Docker Compose v2)
- Git (optional)

## Install Docker

### Windows
1. Download and install Docker Desktop: https://docs.docker.com/desktop/windows/install/
2. Docker Desktop includes Docker Compose out of the box.
3. Make sure Docker Desktop is running before starting the container.

### Ubuntu / Debian
Install Docker using the official repository:
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

Install Docker Compose plugin:
```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

## Setting up the container

### 1. Download files
Clone this repository or download and extract the ZIP archive:
```bash
git clone https://github.com/hihhhh1/trenchblocks-docker-server.git
cd trenchblocks-docker-server
```

### 2. Data persistence
Game server files and configurations are stored in the `./server_data` directory mapped from the host:
```yaml
volumes:
  - ./server_data:/home/steam/trenchblocks_server
```
This ensures your server installations, save files, and maps persist across container restarts.

## Configuring the server settings
All server parameters can be customized directly in the `docker-compose.yml` file under the `environment` section without needing to manually edit `.ini` files.

| Environment Variable | Description | Default Value |
|----------------------|-------------|---------------|
| `STEAM_APP_ID` | Trenchblocks Dedicated Server Steam App ID | `4338960` |
| `SERVER_PORT` | Game connection port (UDP) | `7777` |
| `QUERY_PORT` | Steam query port (UDP) | `27015` |
| `SERVER_ARGS` | Additional engine launch arguments | `-log` |
| `SERVER_NAME` | Name displayed in the server list | `Trenchblocks Server` |
| `MAX_PLAYERS` | Maximum concurrent player count | `32` |
| `MAX_PING` | Maximum allowed player ping | `150` |
| `MAX_GRENADES` | Max grenades per player | `2` |
| `RESPAWN_TIME` | Player respawn time in seconds | `5.000000` |
| `SPAWN_PROTECTION_TIME` | Spawn invulnerability time in seconds | `3.000000` |
| `ROUND_TIME` | Round length in seconds | `1800.000000` |
| `VAC_ENABLED` | Enable Valve Anti-Cheat (`True`/`False`) | `True` |
| `GAMEMODE` | Game mode (e.g. `TDM`) | `TDM` |
| `MOTD` | Message of the Day shown to joining players | `Play fair.` |
| `FRIENDLY_FIRE` | Enable friendly fire (`True`/`False`) | `False` |
| `DESTRUCTION_ENABLED` | Enable terrain/block destruction (`True`/`False`) | `True` |
| `TEAM_A_NAME` | Name for Team A | `Red` |
| `TEAM_B_NAME` | Name for Team B | `Blue` |
| `TEAM_A_COLOR` | RGBA color tuple for Team A | `(R=1.000000,G=0.098958,B=0.098958,A=1.000000)` |
| `TEAM_B_COLOR` | RGBA color tuple for Team B | `(R=0.000000,G=0.347836,B=1.000000,A=1.000000)` |
| `MAP_ROTATION` | Comma-separated list of maps (e.g. `builtin:Arena01,workshop:123456789`) | `builtin:Arena01` |
| `ADMIN_LIST` | Comma-separated SteamID64 list for server administrators | `76561198965966997,76561198041113253` |
| `SESSION_PASSWORD` | Optional password required to join | *(empty)* |
| `VOICE_CHAT_MODE` | Voice chat mode (`Disabled` / `Global` / `Proximity`) | `Proximity` |
| `VOICE_MAX_HEARING_RANGE` | Max voice hearing distance in Unreal units | `5000.000000` |
| `VOICE_MAX_CONCURRENT_GLOBAL_TALKERS` | Maximum simultaneous global voice talkers | `8` |
| `VOICE_RELEVANCY_UPDATE_INTERVAL` | Voice relevancy network tick rate | `0.200000` |
| `WORKSHOP_CONTENT_DEPOT_ID` | Workshop content depot ID | `0` |
| `WORKSHOP_CONTENT_DIR` | Custom directory for workshop items | *(empty)* |
| `WORKSHOP_SEARCH_DIRS` | Comma-separated fallback workshop directories | *(empty)* |

## Starting the container
To build and start the server in the background:
```bash
docker compose up -d --build
```
On first launch, SteamCMD will automatically download all required dedicated server binaries.

### Viewing server logs
To monitor server startup and live console logs:
```bash
docker compose logs -f
```

## Stopping the container
To stop the server:
```bash
docker compose down
```
Server binaries, maps, and save files remain safely saved in `./server_data`.

## Applying configuration changes
Whenever you modify settings in `docker-compose.yml`:
```bash
docker compose up -d
```

## Updating the Trenchblocks server
To pull the latest game server updates from Steam, simply restart the container:
```bash
docker compose restart
```

## Changing port numbers
If you need to change the network ports, update both `ports` and `environment` in `docker-compose.yml`:
```yaml
ports:
  - "7778:7778/udp"
  - "27016:27016/udp"
environment:
  - SERVER_PORT=7778
  - QUERY_PORT=27016
```

## Running multiple server instances
To host multiple servers on one machine, duplicate the folder into a separate directory:
```bash
cp -r trenchblocks-server trenchblocks-server-2
cd trenchblocks-server-2
```
Edit `docker-compose.yml` to change:
1. `container_name: trenchblocks_server_2`
2. Ports (e.g. `7778` and `27016`)
3. `SERVER_NAME` and other settings

Then start with `docker compose up -d --build`.

## Port forwarding and firewalls
To allow external players to connect over the Internet, you must forward the following UDP ports on your router:
- **Game Port**: `7777` UDP (or your custom port)
- **Query Port**: `27015` UDP (or your custom port)

Ensure your host OS firewall (Windows Defender Firewall or Linux `ufw`/`iptables`) permits incoming UDP traffic on these ports.

## Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
