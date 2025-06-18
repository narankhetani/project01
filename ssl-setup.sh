#!/bin/bash
# ssl-setup.sh - Setup Let's Encrypt SSL certificates

set -e

# Configuration
DOMAINS=(
    "ai-workflow-hub.com"
    "www.ai-workflow-hub.com" 
    "honest-ai-reviews.com"
    "www.honest-ai-reviews.com"
    "fintech-insider.com"
    "www.fintech-insider.com"
    "automation.ai-workflow-hub.com"
)

EMAIL="narankhetani+@dc01.bhakti9.org@gmail.com"
STAGING=0  # Set to 1 for testing

echo "=== Let's Encrypt SSL Setup ==="
echo "Domains: ${DOMAINS[*]}"
echo "Email: $EMAIL"

# Create required directories
echo "Creating SSL directories..."
mkdir -p certbot/conf certbot/www
mkdir -p nginx/ssl

# Stop nginx if running
echo "Stopping nginx..."
docker-compose stop nginx

# Download recommended SSL configuration
echo "Downloading SSL configuration..."
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem

# Create temporary nginx config for certificate generation
echo "Creating temporary nginx config..."
cat > nginx/conf.d/temp-ssl.conf << 'EOF'
server {
    listen 80;
    server_name ai-workflow-hub.com www.ai-workflow-hub.com honest-ai-reviews.com www.honest-ai-reviews.com fintech-insider.com www.fintech-insider.com automation.ai-workflow-hub.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 "Certificate generation in progress...";
        add_header Content-Type text/plain;
    }
}
EOF

# Start nginx with temporary config
echo "Starting nginx with temporary config..."
docker-compose up -d nginx

# Wait for nginx to start
sleep 5

# Function to get certificate
get_certificate() {
    local domain=$1
    local domain_args=""
    
    # Build domain arguments
    if [[ $domain == "ai-workflow-hub.com" ]]; then
        domain_args="-d ai-workflow-hub.com -d www.ai-workflow-hub.com -d automation.ai-workflow-hub.com"
    elif [[ $domain == "honest-ai-reviews.com" ]]; then
        domain_args="-d honest-ai-reviews.com -d www.honest-ai-reviews.com"
    elif [[ $domain == "fintech-insider.com" ]]; then
        domain_args="-d fintech-insider.com -d www.fintech-insider.com"
    else
        return 0  # Skip if not a primary domain
    fi
    
    echo "Getting certificate for: $domain_args"
    
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
        $domain_args
}

# Get certificates for each primary domain
echo "Requesting SSL certificates..."
get_certificate "ai-workflow-hub.com"
get_certificate "honest-ai-reviews.com" 
get_certificate "fintech-insider.com"

# Remove temporary config
echo "Removing temporary config..."
rm nginx/conf.d/temp-ssl.conf

# Copy the SSL-enabled config
echo "Installing SSL-enabled nginx config..."
# You'll need to copy the SSL config from the artifact manually here

# Restart nginx with SSL config
echo "Restarting nginx with SSL..."
docker-compose stop nginx
docker-compose up -d nginx

# Test SSL certificates
echo "Testing SSL certificates..."
sleep 10

for domain in ai-workflow-hub.com honest-ai-reviews.com fintech-insider.com; do
    echo "Testing https://$domain"
    curl -I https://$domain || echo "Failed to connect to https://$domain"
done

echo "=== SSL Setup Complete ==="
echo "Your sites should now be accessible via HTTPS!"
echo ""
echo "Next steps:"
echo "1. Update Cloudflare to DNS-only (gray cloud)"
echo "2. Test all your domains via HTTPS"
echo "3. Set up WordPress with HTTPS URLs"