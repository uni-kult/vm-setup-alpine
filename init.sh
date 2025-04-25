#!/bin/sh
set -eu

mv /init/quick-info.md /root/README.md
find /init/dotfiles/ -mindepth 1 -maxdepth 1 -name ".*" -exec cp -a {} "$HOME" \;

truncate -s 0 /etc/motd
sed -i '/community/ s/^#//' /etc/apk/repositories
apk update && apk upgrade
apk add qemu-guest-agent
rc-update add qemu-guest-agent
/etc/init.d/qemu-guest-agent start

adduser user -G users -DH -u 1000 -s /sbin/nologin # reserve UID 1000
wget -O /var/tmp/tempfile http://speedtest.belwue.net/random-100M >/dev/null 2>&1 && find / -size +1k >/dev/null 2>&1 && ls -R / >/dev/null 2>&1 && rm /var/tmp/tempfile >/dev/null 2>&1 && sync # increase entropy
echo "41 3 * * * apk update && apk upgrade" | tee -a /var/spool/cron/root > /dev/null
apk add micro tmux curl wget htop mosh rsync iputils-ping

apk add audit
apk add ip6tables ufw
rc-update add ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.0.0/24 to any port 60000:60100 proto udp # mosh
ufw allow ssh
ufw limit ssh
ufw allow http
ufw allow https
echo "y" | ufw enable
ufw reload

apk add fail2ban
rc-update add fail2ban
rc-service fail2ban start
service sshd restart

# TODO: get files from restic -> if restic not available keep /config empty
mkdir -p /config/

########## caddy

apk add caddy caddy-openrc
mkdir /var/log/caddy
chmod 777 -R /var/log/caddy
cat <<EOF > /config/Caddyfile
{
    log {
        output file /var/log/caddy/caddy.log
        format json
    }
    servers {
        trusted_proxies static 192.168.0.1 192.168.0.30 192.168.0.40 192.168.0.50
    }
}

:80 {
    respond "Caddy Server (Hostname: $(hostname)) is running. Request received, but resource is not yet implemented.
" 501
}
EOF

rm /etc/caddy/Caddyfile 
ln -s /config/Caddyfile /etc/caddy/Caddyfile
rc-service caddy start
rc-update add caddy default


########## docker


apk add docker docker-compose curl
rc-update add docker default
/etc/init.d/docker start

# if this error shows, there is too little RAM available:
# docker: error during connect: Head "http://%2Fvar%2Frun%2Fdocker.sock/_ping": read unix @->/var/run/docker.sock: read: connection reset by peer.


