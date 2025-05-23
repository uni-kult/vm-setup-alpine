## Alpine VM Configuration & Manual

### Repository
*   **Documentation & Setup:** [https://github.com/uni-kult/vm-setup-alpine](https://github.com/uni-kult/vm-setup-alpine)

### VM Overview
*   **Operating System:** Alpine Linux
*   **Virtualization:** Proxmox Cluster
*   **Installed Software:** Docker, Caddy

### Data Management & Service Deployment
*   **Permanent Storage:** Only the `/config` directory is permanent and continuously backed up. All other VM data is *not* persistent and will be reset.
*   **Docker Service Management:**
    *   Each Docker service resides in a separate subfolder within `/config`.
    *   Each service folder must contain a `compose.yaml` file.
    *   Services are started using `dockerctl up`.

### Network Configuration
*   **IP Subnet:** `192.168.0.0/24` (this will soon be changed to `10.200.0.0/16`)
*   **Private IP Block Caution:** Do not trust any other "private IPs" outside of the specified one. ([lrz.de](https://web.archive.org/web/20250523143444/https://www.old.lrz.de.devweb.mwn.de/fragen/faq/netz/netz35/))

### Caddy & Routing
*   **External Routing (via Router VMs):**
    *   HTTP and HTTPS requests first arrive at one of three router VMs.
    *   Caddy on the router VM terminates the SSL connection.
    *   Requests are then routed to the target VM.
*   **Internal Routing (on each VM):**
    *   Caddy on each VM accepts *HTTP only* requests.
    *   It then routes these requests to the correct internal port for the Docker service.

### Snapshots & Resets
*   **Snapshots:** Every 30 minutes a Snapshot of teh VM is created. These snapshots are stored for 12 hours. Daily snapshots are kept for much longer.
*   **Monthly VM Reset:**
    *   **Schedule:** All VMs are reset and restarted monthly on the **17th at 3:00 AM**.
    *   **Exceptions:** If you require an exception, please contact the system administrator in advance.
    *   **init.sh Script:** A file named `/config/init.sh` can be created. This script will be run *once* after a VM reset, allowing for custom setup logic. Prefer using Docker containers for persistent services and configurations over relying heavily on `init.sh`.
