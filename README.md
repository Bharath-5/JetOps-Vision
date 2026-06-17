# Edge-Device Computer Vision DevOps & Orchestration Framework (EdgeCV-Ops)

An enterprise-grade MLOps and automation framework engineered for the deployment, telemetry tracking, and lifecycle management of multi-model Nvidia DeepStream pipelines on resource-constrained distributed edge hardware (NVIDIA Jetson Nano nodes).

This repository provides low-level network automation, container lifecycle synchronization, remote interactive diagnostic utilities, and telemetry tracking agents alongside an experimental deep learning inference classifier module.

---

## 📂 Core Repository Architecture

```text
.
├── main.sh                       # Master interactive CLI management console
├── RTSP_Deploy.sh                # Edge container runner (Nvidia runtime + X11 bindings)
├── RTSP_Deploy_ref.sh            # Baseline fallback template for RTSP_Deploy.sh
├── EnableDisableNonRTSP.sh       # Fleet load-balancing pipeline toggler
├── ping_nonrtsp.sh               # Active state telemetry sync (Ansible/Tmux orchestrator)
├── heartbeat.py                  # Distributed network agent broadcasting device metrics
├── IP_Set.sh                     # Low-level static IP provisioning engine
├── IP_Set_ref.sh                 # Template blueprint for static IP configuration
├── json_update_ref.sh            # Dynamic template compiler engine using `sed`/`awk`
├── CamRec.sh                     # Runtime diagnostics camera clip extraction tool
├── OldRec_ref.sh                 # Chronological retrospection stream retrieval engine
├── reference.json                # Master application structure baseline schema
├── iris.json                     # Dynamic active runtime orchestration parameters
├── full.txt                      # Consolidated system device compilation log
├── host_gen.sh                   # Loopback callback environment discovery asset
├── IF_ref.txt / IN_ref.txt       # Configuration references mapped out per stream zone
├── BH_ref.txt                    # Configuration reference mapped out per stream zone
├── DB/                           # Fleet Inventory Metaspace Databases
│   ├── Phase1.txt                # Cluster A Fleet tracking records
│   ├── Phase2.txt                # Cluster B Fleet tracking records
│   ├── Phase3.txt                # Cluster C Fleet tracking records
│   └── Phase4.txt                # Cluster D Fleet tracking records
├── Detect/                       # Experimental Image Recognition Pipeline
│   ├── Detect.py                 # Core Keras evaluation script (Pillow 10+ compliant)
│   ├── keras_model.h5            # Trained lightweight classification model weights
│   └── labels.txt                # Classification model target environment indices
└── config_infer_primary_yolov5sP6.txt  # Core TensorRT DeepStream inference layer matrix

```

---

## ⚡ System Initialization & Entry Point

Everything in this orchestration architecture is designed to be completely modular and begins with the interactive master controller shell:

```bash
chmod +x main.sh
./main.sh

```
❗ Important Deployment Disclaimer: This infrastructure framework utilizes generic substitution tokens and configuration templates. System administrators must populate localized networking paths, cluster IDs, and credential parameters prior to runtime execution

Upon launching, `main.sh` reads and processes the database files inside `DB/` to map out active connection strings, compiling device counts natively using standard Linux utilities (`awk`, `grep`). It presents an interactive terminal dashboard supporting 9 fundamental system provisioning states:

1. **Setup device before dispatch:** Automates local system variables prior to deployment.
2. **SSH into a device:** Parses targeted host strings out of the database arrays dynamically to initialize remote shells.
3. **Set static IP for a device:** Deploys `IP_Set.sh` to remotely bind hardware to strict cluster segments.
4. **RTSP Deployment:** Invokes stream discovery, verifies video processing framerates, and runs the container stack.
5. **Non-RTSP Deployment:** Standardized fallbacks for file-based batch processing modules.
6. **Extract RTSP historical feed:** Pulls chronological video partitions out of a DVR's archive timeline.
7. **Maintain sites (Non-RTSP script):** Load-balances processing engines on target backend servers.
8. **Maintain sites (Down script):** Reconciles host machine ping discrepancies against active cloud dashboard logs.
9. **Get Remmina access:** Modifies remote graphical server configurations over SSH (`gsettings Vino`) to establish remote desktops.

---

## 🐳 Container Layer & Hardware Virtualization

The container runtime loop is driven by `RTSP_Deploy.sh`. It connects to your remote private registry, manages image tags, and interfaces directly with the host system's Docker socket to map physical hardware boundaries straight into the container environment.

```bash
# Automated deployment initialized inside main.sh
./RTSP_Deploy.sh

```

### Key Orchestration Components:

* **X11 Acceleration Bridging:** The runner automatically pulls down your display server's active authorization keys (`.Xauthority`), extracts the environment's magic cookies dynamically via `xauth`, and pipes them inside the root socket via `xhost +local:root` to enable NVIDIA hardware-accelerated EGL rendering pipelines inside the Docker layer.
* **DeepStream Hardware Passthrough:** Mounts local TensorRT engines, CUDA compiler include headers, system architecture binaries (`/usr/lib/aarch64-linux-gnu`), and custom YOLO model bindings directly, running securely under the `--runtime nvidia` flags.
* **Persistent Network Binding:** Utilizes strict `--net=host` architectures to prevent network encapsulation overhead, giving the container raw access to distributed internal camera networks.

---

## 📊 Telemetry, Automation & Sync Systems

### 1. Networking Rollback Engine (`IP_Set.sh`)

An automated network provisioning utility pushed to new hardware. It writes strict properties directly into `/etc/network/interfaces` and establishes structural persistence in `/etc/rc.local`. Upon reboot, it validates internet connectivity to public resolvers (`8.8.8.8`). If outward routing fails, it triggers a programmatic fallback routine, purging the configurations and restoring standard dynamic DHCP to prevent permanent device isolation in the field.

### 2. Distributed Telemetry Agent (`heartbeat.py`)

A continuous background daemon that loops every 5 minutes on active nodes. It uses resource boundary handlers to inspect active local interface adapters (`eth0`, `tun1`), maps local VPN routing segments, captures system metadata descriptors, and broadcasts a securely serialized RFC-compliant JSON payload back to central infrastructure orchestration endpoints.

### 3. Fleet Balance Optimization (`EnableDisableNonRTSP.sh` / `ping_nonrtsp.sh`)

Pushed to core host servers by an Ansible automation manager, this utility handles active load-balancing. It parses error arrays (`disableTheseCodes.txt` / `enableTheseCodes.txt`) containing disconnected node listings, loops through target JSON configurations utilizing complex multi-line `sed` pattern space strings to toggle `"utilize": true/false`, kills dead tmux windows, and cleanly forks renewed inference pipelines inside isolated background multiplexers.

---

## 🧠 Experimental Submodule: Image Recognition Pipeline

> ⚠️ **Development Status: Experimental** > The modules situated inside the `Detect/` directory reflect a proof-of-concept image environment classifier. This subsystem is currently decoupled from the main automated processing architecture and is intended for stand-alone evaluation, diagnostic verification, and validation testing.

### Submodule Components:

* `Detect.py`: Inference wrapper script. It ingests an image file target via command line arguments (`sys.argv[1]`), reads the model assets, applies input normalization transformations (mapping pixel parameters from `[0, 255]` to `[-1, 1]`), and executes a soft-max probability lookup.
* `keras_model.h5`: A lightweight, trained image classification model.
* `labels.txt`: Index mappings translating raw numerical model array slots into human-readable target labels.

---

## 🔄 Modernization Notice (Pillow 10+ Compatibility)

The core preprocessing pipeline inside `Detect.py` has been upgraded to maintain compatibility with modern runtime servers. The deprecated `Image.ANTIALIAS` flag (removed completely in recent Pillow versions) has been wrapped into an adaptive fallback mechanism:

```python
# Fully compliant across modern desktop and legacy edge environments
resample_method = getattr(Image, 'ANTIALIAS', getattr(Image, 'LANCZOS', 1))
image = ImageOps.fit(image, target_size, resample=resample_method)

```

To run a diagnostic classification evaluation:

```bash
python3 Detect/Detect.py path/to/diagnostic_frame.jpg

```

---

## 📜 License

This framework is licensed under the **Apache License 2.0**. For open-source, edge-AI, and corporate hardware deployments, Apache 2.0 provides explicit royalty-free patent grant rights, trademark protection rules, and robust defensive legal retaliation clauses. See the `LICENSE` file for more details.

```

```
