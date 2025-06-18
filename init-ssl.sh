#!/bin/bash
# init-ssl.sh - Initialize SSL certificates for all domains

set -e

# Configuration
EMAIL="narankhetani+dc01.bhakti9.org@gmail.com"  # CHANGE THIS TO YOUR EMAIL
STAGING=0  # Set to 1 for testing, 0 for production

# Domain groups (primary domain includes www and subdomains)
DOMAIN_GROUPS=(
    "ai-workflow-hub.com,www.ai-workflow-hub.com,automation.ai-workflow-hub.com"
    "honest-ai-reviews.com,www.honest-ai-reviews.com"
    "fintech-insider.com,www.fintech-insider.com"
)

echo "=== SSL Certificate Initialization ==="
echo "Email: $EMAIL"
echo "Staging: $STAGING"

# Function to check if certificate exists
cert_exists() {
    local domain=$1
    if [ -f "./certbot/conf/live/$domain/fullchain.pem" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get certificate
get_certificate() {
    local domains=$1
    local primary_domain=$(echo $domains | cut -d',' -f1)
    
    echo "Getting certificate for: $domains"
    
    # Build domain arguments
    local domain_args=""
    IFS=',' read -ra DOMAIN_ARRAY <<< "$domains"
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain_args="$domain_args -d $domain"
    done
    
    # Set staging flag if testing
    local staging_arg=""
    if [ $STAGING = 1 ]; then
        staging_arg="--staging"
    fi
    
    # Request certificate
    docker-compose run --rm certbot \
        certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        $staging_arg \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        $domain_args
}

# Create required directories
echo "Creating SSL directories..."
mkdir -p certbot/conf certbot/www nginx/ssl

# Download recommended SSL configuration
echo "Downloading SSL configuration files..."
if [ ! -f "certbot/conf/options-ssl-nginx.conf" ]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
fi

if [ ! -f "certbot/conf/ssl-dhparams.pem" ]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem
fi

# Create temporary nginx config for ACME challenge
echo "Creating temporary nginx config for certificate generation..."
cat > nginx/conf.d/temp-ssl.conf << 'EOF'
server {
    listen 80;
    server_name ai-workflow-hub.com www.ai-workflow-hub.com honest-ai-reviews.com www.honest-ai-reviews.com fintech-insider.com www.fintech-insider.com automation.ai-workflow-hub.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 "SSL certificate generation in progress...\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Reload nginx with temporary config
echo "Reloading nginx with temporary config..."
docker-compose exec nginx nginx -s reload

# Wait for nginx to reload
sleep 3

# Get certificates for each domain group
echo "Requesting SSL certificates..."
for domain_group in "${DOMAIN_GROUPS[@]}"; do
    primary_domain=$(echo $domain_group | cut -d',' -f1)
    
    if cert_exists "$primary_domain" && [ $STAGING = 0 ]; then
        echo "Certificate for $primary_domain already exists, skipping..."
    else
        get_certificate "$domain_group"
    fi
done

# Remove temporary config
echo "Removing temporary nginx config..."
rm -f nginx/conf.d/temp-ssl.conf

echo "=== SSL certificates obtained! ==="
echo "Next steps:"
echo "1. Install SSL-enabled nginx configuration"
echo "2. Restart nginx with SSL config"
echo "3. Test HTTPS access"
echo ""
echo "Run: ./configure-ssl-nginx.sh"
