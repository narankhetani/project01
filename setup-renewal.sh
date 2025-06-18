#!/bin/bash
# setup-renewal.sh - Set up automatic SSL certificate renewal

set -e

echo "=== Setting Up SSL Auto-Renewal ==="

# Create renewal script
echo "Creating renewal script..."
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
# renew-ssl.sh - Automatic SSL certificate renewal

set -e

cd /opt/content-empire

echo "=== SSL Certificate Renewal - $(date) ==="

# Function to check certificate expiry
check_expiry() {
    local domain=$1
    if [ -f "./certbot/conf/live/$domain/fullchain.pem" ]; then
        local expiry=$(openssl x509 -noout -dates -in "./certbot/conf/live/$domain/fullchain.pem" | grep "notAfter" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry" +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        echo "$domain expires in $days_left days"
        
        if [ $days_left -lt 30 ]; then
            echo "⚠️  $domain expires soon, renewal needed"
            return 1
        fi
        return 0
    else
        echo "❌ Certificate not found for $domain"
        return 1
    fi
}

# Check all certificates
echo "Checking certificate expiry..."
check_expiry "ai-workflow-hub.com"
check_expiry "honest-ai-reviews.com"
check_expiry "fintech-insider.com"

# Attempt renewal
echo "Running certificate renewal..."
docker compose run --rm certbot renew --quiet

# Check if any certificates were renewed
if [ $? -eq 0 ]; then
    echo "✅ Certificate renewal completed successfully"
    
    # Reload nginx to pick up new certificates
    echo "Reloading nginx..."
    docker compose exec nginx nginx -s reload
    
    echo "✅ Nginx reloaded with new certificates"
else
    echo "ℹ️  No certificates needed renewal"
fi

# Final certificate status
echo "=== Certificate Status After Renewal ==="
check_expiry "ai-workflow-hub.com" || echo "Issue with ai-workflow-hub.com"
check_expiry "honest-ai-reviews.com" || echo "Issue with honest-ai-reviews.com"
check_expiry "fintech-insider.com" || echo "Issue with fintech-insider.com"

echo "=== SSL Renewal Complete - $(date) ==="
EOF

# Make renewal script executable
chmod +x renew-ssl.sh

# Create certificate check script
echo "Creating certificate check script..."
cat > check-ssl.sh << 'EOF'
#!/bin/bash
# check-ssl.sh - Check SSL certificate status

cd /opt/content-empire

echo "=== SSL Certificate Status Check ==="
echo "Date: $(date)"
echo ""

# Function to check certificate
check_cert() {
    local domain=$1
    echo "Checking $domain..."
    
    if [ -f "./certbot/conf/live/$domain/fullchain.pem" ]; then
        local expiry=$(openssl x509 -noout -dates -in "./certbot/conf/live/$domain/fullchain.pem" | grep "notAfter" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -d "$(echo $expiry | sed 's/GMT/UTC/')" +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        if [ $days_left -gt 30 ]; then
            echo "✅ $domain: $days_left days remaining (expires: $expiry)"
        elif [ $days_left -gt 7 ]; then
            echo "⚠️  $domain: $days_left days remaining (expires: $expiry) - RENEWAL SOON"
        else
            echo "🚨 $domain: $days_left days remaining (expires: $expiry) - URGENT RENEWAL"
        fi
        
        # Test HTTPS connectivity
        if curl -s -I https://$domain > /dev/null 2>&1; then
            echo "   🌐 HTTPS connectivity: OK"
        else
            echo "   ❌ HTTPS connectivity: FAILED"
        fi
    else
        echo "❌ $domain: No certificate found"
    fi
    echo ""
}

# Check all certificates
check_cert "ai-workflow-hub.com"
check_cert "honest-ai-reviews.com"
check_cert "fintech-insider.com"

# Check nginx SSL configuration
echo "Checking nginx SSL configuration..."
if docker compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration: OK"
else
    echo "❌ Nginx configuration: ERRORS"
fi

echo "=== Check Complete ==="
EOF

chmod +x check-ssl.sh

# Set up cron jobs
echo "Setting up automatic renewal..."

# Create cron job entries
CRON_RENEWAL="0 12 * * * cd /opt/content-empire && ./renew-ssl.sh >> /var/log/ssl-renewal.log 2>&1"
CRON_CHECK="0 9 * * 1 cd /opt/content-empire && ./check-ssl.sh >> /var/log/ssl-check.log 2>&1"

# Add to crontab
(crontab -l 2>/dev/null || echo "") | grep -v "renew-ssl.sh" | grep -v "check-ssl.sh" > /tmp/crontab_temp
echo "$CRON_RENEWAL" >> /tmp/crontab_temp
echo "$CRON_CHECK" >> /tmp/crontab_temp
crontab /tmp/crontab_temp
rm /tmp/crontab_temp

# Create log files with proper permissions
sudo touch /var/log/ssl-renewal.log /var/log/ssl-check.log
sudo chown $(whoami):$(whoami) /var/log/ssl-renewal.log /var/log/ssl-check.log

echo "✅ Cron jobs configured:"
echo "   - Daily renewal check at 12:00 PM"
echo "   - Weekly status check on Mondays at 9:00 AM"

# Test the renewal script
echo ""
echo "Testing renewal script..."
./check-ssl.sh

echo ""
echo "=== SSL Auto-Renewal Setup Complete! ==="
echo ""
echo "📋 Summary:"
echo "✅ Created renew-ssl.sh (manual renewal)"
echo "✅ Created check-ssl.sh (status check)"
echo "✅ Configured automatic daily renewal at 12:00 PM"
echo "✅ Configured weekly status check on Mondays at 9:00 AM"
echo ""
echo "📝 Useful commands:"
echo "   ./check-ssl.sh          - Check certificate status"
echo "   ./renew-ssl.sh          - Manual renewal"
echo "   tail -f /var/log/ssl-renewal.log  - View renewal logs"
echo "   crontab -l              - View scheduled jobs"
echo ""
echo "🎉 Your SSL certificates will now renew automatically!"