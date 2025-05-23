
Config and Manual is here:
https://github.com/uni-kult/vm-setup-alpine


- all VMs are Alpine running on a Proxmox Cluster
- put all files for services inside "/config" - it is backed-up continiously
- all VMS are reset regurlaly -> only "/config" is permanent
- only docker and caddy are installed
- each docker service running is seperate folder in "/config" with a compose.yaml file inside. It is started with "docker compose up -d".
- the cluster has the IP Subent "192.168.0.0/24" -> this will soon be changed to "10.200.0.0/16"
- http and https requests arrive at one of three routers (VMs), where caddy will terminate the SSL connection and route it to the target VM
- on each VM caddy accepts the http (no https) requests and routes it to the correct internal port for the docker service
- on each VM caddy accepts the http (no https) requests and routes it to the correct internal port for the docker service
- all VMs are reset and restarted on the 17th at 3:00AM every month. If you dont want this, please contact the system administrator ahead of time to make an exception!
