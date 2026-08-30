#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "=== Connexxion app bootstrap starting: $(date) ==="

# --- 1. System packages: Node.js, Nginx, git ---
apt-get update -y
apt-get install -y curl git nginx

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- 2. Determine the non-root user to run the app as ---
# Ubuntu cloud images default to the "ubuntu" user.
sudo useradd -m connexxiongroup
sudo su - connexxiongroup 
git clone https://github.com/EseVic/connexxiongroup_project.git

APP_USER="connexxiongroup"
APP_HOME="/home/$APP_USER"
REPO_DIR="$APP_HOME/connexxiongroup_project"
APP_DIR="$REPO_DIR/${app_subdir}"

# --- 3. Clone the application source ---
if [ ! -d "$REPO_DIR" ]; then
  sudo -u "$APP_USER" git clone "${repo_url}" "$REPO_DIR"
else
  cd "$REPO_DIR" && sudo -u "$APP_USER" git pull
fi

# --- 4. Install app dependencies ---
cd "$APP_DIR"
sudo -u "$APP_USER" npm install --omit=dev

# --- 5. Generate a random JWT secret and write .env ---
# Generated on the instance itself at boot time — never hard-coded in
# Terraform code or committed to the repo.
JWT_SECRET="$(openssl rand -hex 32)"

cat > "$APP_DIR/.env" << EOF
PORT=${app_port}
JWT_SECRET=$JWT_SECRET
NODE_ENV=production
EOF
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"

# --- 6. systemd service: start on boot, restart on crash ---
cat > /etc/systemd/system/connexxiongroup.service << EOF
[Unit]
Description=Connexxion TaskBoard Node.js app
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/usr/bin/node src/server.js
Restart=on-failure
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable connexxiongroup.service
systemctl restart connexxiongroup.service

# --- 7. Nginx reverse proxy: expose :80, keep the app port internal ---
cat > /etc/nginx/sites-available/connexxiongroup << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/connexxiongroup /etc/nginx/sites-enabled/connexxiongroup
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "=== Connexxion app bootstrap finished: $(date) ==="
