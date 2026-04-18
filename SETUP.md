# Dedicated Mirror Server — Setup & Deploy Guide

End-to-end process for building, deploying, and connecting the headless Mirror server on Edgegap.

---

## Architecture

```
Unity Client  ──lobby/matchmaking──►  Render (mirror-server.js / Socket.IO)
Unity Client  ──Mirror KCP/WS──────►  Edgegap (headless Unity server)
```

- **Render** brokers the lobby and injects the Edgegap address/ports into `match_started`
- **Edgegap** runs the actual Mirror dedicated server (KCP port 7777, WebSocket port 7778)

---

## Part 1 — Build the Linux Server Binary

1. Open `mirror-server-demo` in Unity
2. Select `NetworkManager` in the scene → set **Headless Start Mode = Auto Start Server**
3. Save the scene (Cmd+S)
4. File → **Build Profiles** → select **Linux Server** → click **Build**
5. Choose an output folder (e.g. `build-output/`)

---

## Part 2 — Release & CI/CD

1. Zip the build output contents (`.x86_64` binary + `_Data/` folder) → name it **`server-linux.zip`**
2. Go to `github.com/Magithar/socketio-unity-mirror-server` → **Releases** → **Draft a new release**
3. Tag: `v0.x.0` (increment from previous), Title: same
4. Attach `server-linux.zip` as a release asset → **Publish Release**
5. GitHub Actions (`build-server.yml`) triggers automatically:
   - Downloads the zip
   - Builds Docker image
   - Pushes to Edgegap registry as `mirror-server:v0.x.0`
6. Wait ~2-3 minutes for the workflow to complete

---

## Part 3 — Create Edgegap Version

1. Edgegap dashboard → **Versions** → **Create Version**
2. Fill in:
   - **Version name**: `v0.x.0`
   - **Image Repository**: `magi-csyceyhoz6ek/mirror-server`
   - **Tag**: `v0.x.0`
3. Under **Ports** → create two ports:

   | Port | Protocol | Name      | Verifications |
   |------|----------|-----------|---------------|
   | 7777 | UDP      | kcp       | true          |
   | 7778 | TCP      | websocket | true          |

4. Save the version

---

## Part 4 — Deploy on Edgegap

1. Edgegap → **Deployments** → terminate any existing deployment
2. Click **Create Deployment** → select `mirror-server` → version `v0.x.0` → pick location closest to your players
3. Deploy → wait ~20-30 seconds for status **Ready**
4. Click the deployment → **Deployment Details** → note:
   - **Host FQDN** (e.g. `xxxxxx.pr.edgegap.net`)
   - **UDP external port** (KCP)
   - **TCP external port** (WebSocket)

---

## Part 5 — Update Render Environment Variables

1. Render dashboard → `socketio-unity-mirror` → **Environment**
2. Set (or update) these three vars:

   | Key                    | Value                        |
   |------------------------|------------------------------|
   | `MIRROR_SERVER_ADDRESS`| `xxxxxx.pr.edgegap.net`      |
   | `MIRROR_KCP_PORT`      | `<UDP external port>`        |
   | `MIRROR_WS_PORT`       | `<TCP external port>`        |

3. Save → Render auto-redeploys (~1-2 min)

> These values change every new Edgegap deployment. Never commit them to git.

---

## Part 6 — Test in Unity

1. Open `MirrorIntegrationScene`
2. Select `MirrorGameOrchestrator` → set **Server Mode = Dedicated KCP**
3. Set `LobbyNetworkManager` → **Server Url** = `https://socketio-unity-mirror.onrender.com`
4. Press Play → Create Room → mark Ready → Start Match
5. Check console for:
   ```
   🎮 Match started! hostAddress=xxxxxx.pr.edgegap.net kcpPort=XXXXX
   [MirrorOrchestrator] DedicatedKCP — connecting to xxxxxx.pr.edgegap.net:XXXXX
   [PlayerIdentityBridge] Registered netId=1 → playerId=...
   ```

---

## Keeping Scripts in Sync

The server project imports sample scripts from the `com.magithar.socketio-unity` package.
When those scripts are updated in the main repo, sync them:

```bash
SERVER="mirror-server-demo/Assets/Samples/Socket.IO Unity Client/1.4.0"
SOURCE="socketio-unity/package/Samples~"

cp "$SOURCE/Lobby/Scripts/LobbyStateStore.cs"      "$SERVER/Lobby/Scripts/"
cp "$SOURCE/Lobby/Scripts/LobbyNetworkManager.cs"  "$SERVER/Lobby/Scripts/"
cp "$SOURCE/Lobby/Scripts/LobbyUIController.cs"    "$SERVER/Lobby/Scripts/"
cp "$SOURCE/MirrorIntegration/Scripts/MirrorGameOrchestrator.cs" "$SERVER/Mirror Integration/Scripts/"
```

Or in Unity Package Manager: remove the imported samples and re-import them.

---

## Free-Tier Notes

- Edgegap free tier: **1 concurrent deployment**, auto-terminates after **60 minutes**
- Render free tier: **spins down after inactivity** — first connection may take ~50 seconds
- Terminate the Edgegap deployment when done testing to preserve the free-tier allowance
