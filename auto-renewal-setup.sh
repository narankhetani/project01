cd /opt/content-empire

# Create the cron jobs automatically
cat << 'EOF' | crontab -
# SSL certificate renewal - twice daily at 3 AM and 3 PM
0 3,15 * * * cd /opt/content-empire && docker compose run --rm certbot renew --quiet && docker compose exec nginx nginx -s reload >> /var/log/ssl-renewal.log 2>&1

# SSL status check - weekly on Monday at 9 AM  
0 9 * * 1 cd /opt/content-empire && echo "=== SSL Check $(date) ===" >> /var/log/ssl-check.log && docker compose run --rm certbot certificates >> /var/log/ssl-check.log 2>&1

# Log cleanup - monthly
0 0 1 * * find /var/log/ssl-*.log -mtime +30 -delete
EOF

# Verify cron jobs were added
crontab -l
