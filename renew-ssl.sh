#!/bin/bash
# renew-ssl.sh - Automatic SSL certificate renewal

set -e

cd /opt/content-empire

echo "=== SSL Certificate Renewal ==="
echo "Date: $(date)"

# Renew certificates
echo "Renewing SSL certificates..."
docker-compose run --rm certbot renew --quiet

# Reload nginx to pick up new certificates
echo "Reloading nginx..."
docker-compose exec nginx nginx -s reload

# Check certificate expiration dates
echo "Certificate expiration check:"
for domain in ai-workflow-hub.com honest-ai-reviews.com fintech-insider.com; do
    if [ -f "./certbot/conf/live/$domain/fullchain.pem" ]; then
        expiry=$(openssl x509 -noout -dates -in "./certbot/conf/live/$domain/fullchain.pem" | grep "notAfter" | cut -d= -f2)
        echo "$domain expires: $expiry"
    else
        echo "❌ Certificate not found for $domain"
    fi
done

echo "=== SSL Renewal Complete ==="
