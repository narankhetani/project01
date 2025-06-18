#!/bin/bash
# backup-scripts/backup.sh

# Configuration
BACKUP_DIR="/output"
DATE=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

echo "Starting backup process at $(date)"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Backup WordPress files
log_message "Backing up WordPress files..."
tar -czf $BACKUP_DIR/$DATE/wordpress_files_$DATE.tar.gz -C /backup/wordpress . 2>/dev/null
if [ $? -eq 0 ]; then
    log_message "WordPress files backup completed successfully"
else
    log_message "WordPress files backup failed"
fi

# Backup WordPress database
log_message "Backing up WordPress database..."
mysqldump -h mysql -u wordpress_user -pwp_secure_password_2025 wordpress_main > $BACKUP_DIR/$DATE/wordpress_db_$DATE.sql 2>/dev/null
if [ $? -eq 0 ]; then
    gzip $BACKUP_DIR/$DATE/wordpress_db_$DATE.sql
    log_message "WordPress database backup completed successfully"
else
    log_message "WordPress database backup failed"
fi

# Backup n8n data
log_message "Backing up n8n data..."
tar -czf $BACKUP_DIR/$DATE/n8n_data_$DATE.tar.gz -C /backup/n8n . 2>/dev/null
if [ $? -eq 0 ]; then
    log_message "n8n data backup completed successfully"
else
    log_message "n8n data backup failed"
fi

# Backup n8n database
log_message "Backing up n8n database..."
pg_dump -h postgres -U n8n_user -d n8n > $BACKUP_DIR/$DATE/n8n_db_$DATE.sql 2>/dev/null
export PGPASSWORD=n8n_secure_password_2025
if [ $? -eq 0 ]; then
    gzip $BACKUP_DIR/$DATE/n8n_db_$DATE.sql
    log_message "n8n database backup completed successfully"
else
    log_message "n8n database backup failed"
fi

# Create backup summary
log_message "Creating backup summary..."
cat > $BACKUP_DIR/$DATE/backup_summary.txt << EOF
Backup Summary - $DATE
=====================================
Date: $(date)
Server: $(hostname)

Files included:
- WordPress files: wordpress_files_$DATE.tar.gz
- WordPress database: wordpress_db_$DATE.sql.gz
- n8n data: n8n_data_$DATE.tar.gz
- n8n database: n8n_db_$DATE.sql.gz

Backup size: $(du -sh $BACKUP_DIR/$DATE | cut -f1)
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh $BACKUP_DIR/$DATE | cut -f1)
log_message "Backup completed. Total size: $BACKUP_SIZE"

# Clean up old backups
log_message "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -type d -name "2*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
log_message "Cleanup completed"

# Optional: Upload to cloud storage (uncomment and configure as needed)
# log_message "Uploading to cloud storage..."
# aws s3 sync $BACKUP_DIR s3://your-backup-bucket/content-empire-backups/ --delete

log_message "Backup process completed at $(date)"

# Send backup notification (optional)
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"Backup completed successfully on '$(hostname)' at '$(date)'"}' \
#   YOUR_SLACK_WEBHOOK_URL