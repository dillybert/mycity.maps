# 🚀 MyCity Maps — Automated OSM Processing & Geo-Services Stack

**MyCity Maps** is a full automation framework for preparing OpenStreetMap data, importing it into PostGIS, generating OSRM routing data, building Photon search indexes, running Martin tileserver, and launching Maputnik for style editing — all controlled via a unified Bash CLI.

It is designed to simplify the setup of a complete geospatial platform with minimal manual work.

---

# 📌 Features

### ✔ Unified CLI (`./mycity.maps`)

A command–action interface for controlling all modules:

```
./mycity.maps <command> <action> [...args]
```

### ✔ Dependency Checking

Tests all required tools and Docker images.

### ✔ OSM Data Preparation

Filtering, renumbering, and compressing raw OSM data.

### ✔ PostGIS Import (Imposm)

Full import pipeline with mapping and SQL post-processing.

### ✔ OSRM Routing Data Generation

Runs extract → partition → customize.

### ✔ Photon Search Index Builder

Uses Nominatim + Photon JAR to build fast search indexes.

### ✔ Automated Service Startup

Runs PostGIS, OSRM, Martin, Nominatim, Photon, Maputnik.

### ✔ Service Health Check

Checks if containers are running and reachable.

### ✔ Cleanup System

Stops containers, removes temporary files, resets state.

---

# 🧱 Project Structure

```
project/
├── data/
│   ├── data.osm                # raw OSM file
│   ├── mapping/mapping.json    # imposm mapping config
│   └── post_scripts/           # SQL post-processing scripts
├── maputnik/styles/            # Maputnik styles
├── martin/fonts/               # Martin tileserver fonts
├── martin/sprites/             # Martin sprites
├── photon/photon.jar           # Photon search engine
├── scripts/
│   ├── cmd/
│   │   ├── cli.sh              # CLI framework (command dispatcher)
│   │   └── utils.sh            # logging, waiters, helpers
│   └── modules/
│       ├── check.sh
│       ├── clean.sh
│       ├── import.sh
│       ├── prepare.sh
│       └── services.sh
├── tmp/                        # state files & logs
└── mycity.maps                      # CLI entrypoint
```

---

# 🔧 Installation Requirements

### System Tools

* Bash 4+
* Docker & Docker Compose
* Java (for Photon)
* `osmfilter`
* `osmium`
* `imposm`

### Recommended OS

* Linux (Ubuntu, Debian, Arch)
* WSL2 (Windows)

---

# 🛠 Commands & Usage

All functionality is accessed through:

```
./mycity.maps <command> <action>
```

---

## 1. 🔍 Checking Dependencies

### Check everything

```
./mycity.maps check all
```

### Check running services

```
./mycity.maps check services
```

---

## 2. 🧹 Cleanup

### Cleanup temporary files

```
./mycity.maps clean tmp
```

### Stop all services and remove containers

```
./mycity.maps clean services
```

---

## 3. 🗂 Prepare Data

### Prepare OSM file

Filters tags, renumbers IDs, compresses into `.osm.pbf`.

```
./mycity.maps prepare osm
```

### Prepare OSRM data

```
./mycity.maps prepare osrm
```

Runs:

* `osrm-extract`
* `osrm-partition`
* `osrm-customize`

### Prepare Photon index

```
./mycity.maps prepare photon
```

---

## 4. 📥 Import into PostGIS

```
./mycity.maps import osm
```

Pipeline:

1. Import via `imposm`
2. Apply mapping.json
3. Run SQL fixes from `post_scripts/`

---

## 5. 🚀 Start Services

### Start PostGIS:

```
./mycity.maps start postgis
```

### Start OSRM:

```
./mycity.maps start osrm
```

### Start Nominatim:

```
./mycity.maps start nominatim
```

### Start Photon:

```
./mycity.maps start photon
```

### Start Martin (tileserver):

```
./mycity.maps start martin
```

### Start Maputnik:

```
./mycity.maps start maputnik
```

---

# 📡 Service Endpoints

| Service   | Purpose             | URL (example)                                  |
| --------- | ------------------- | ---------------------------------------------- |
| PostGIS   | geo database        | exposed via Docker                             |
| OSRM      | routing engine      | [http://localhost:5000](http://localhost:5000) |
| Nominatim | geocoder backend    | [http://localhost:8080](http://localhost:8080) |
| Photon    | search engine       | [http://localhost:2322](http://localhost:8989) |
| Martin    | vector tiles server | [http://localhost:3000](http://localhost:3000) |
| Maputnik  | style editor UI     | [http://localhost:8888](http://localhost:8000) |

(All settings configurable in .env file, check env.example for defaults)

---

# 📑 Logging

* Logs written to:

  ```
  tmp/project_YYYYMMDD_HH.log
  ```

---

# 🚀 Full Example Workflow

```bash
./mycity.maps check all
./mycity.maps prepare osm
./mycity.maps import osm
./mycity.maps prepare osrm

./mycity.maps start postgis
./mycity.maps start osrm
./mycity.maps start nominatim

./mycity.maps prepare photon
./mycity.maps start photon
./mycity.maps start martin
./mycity.maps start maputnik

./mycity.maps check services
```

