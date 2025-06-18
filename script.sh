cd /opt/content-empire

# Create main directory structure
mkdir -p {nginx/conf.d,nginx/ssl,nginx/logs}
mkdir -p {mysql/backup,mysql/conf.d,mysql/init}
mkdir -p postgres/backup
mkdir -p n8n/backup
mkdir -p {backup-scripts,backups}

# Create WordPress directories for each site
mkdir -p wordpress/main/{uploads,themes,plugins,backup}
mkdir -p wordpress/reviews/{uploads,themes,plugins,backup}
mkdir -p wordpress/fintech/{uploads,themes,plugins,backup}
chown -R $USER:$USER /opt/content-empire