cd /opt/content-empire

# Create main directory structure
sudo mkdir -p {nginx/conf.d,nginx/ssl,nginx/logs}
sudo mkdir -p {mysql/backup,mysql/conf.d,mysql/init}
sudo mkdir -p {postgres/backup}
sudo mkdir -p {n8n/backup}
sudo mkdir -p {backup-scripts,backups}

# Create WordPress directories for each site
sudo mkdir -p wordpress/main/{uploads,themes,plugins,backup}
sudo mkdir -p wordpress/reviews/{uploads,themes,plugins,backup}
sudo mkdir -p wordpress/fintech/{uploads,themes,plugins,backup}

# Set proper ownership
sudo chown -R $USER:$USER /opt/content-empire