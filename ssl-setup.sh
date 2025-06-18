#!/bin/bash
# ssl-setup.sh - Complete SSL certificate setup

set -e

# Configuration
EMAIL="narankhetani+dc01.bhakti9.org@gmail.com"
STAGING=0  # Set to 1 for testing, 0 for production

echo "=== Complete SSL Certificate Setup ==="
echo "Email: $EMAIL"
echo "Mode: $([ $STAGING -eq 1 ] && echo 'STAGING' || echo 'PRODUCTION')"

# Function to check if certificate exists
cert_exists() {
    local domain=$1
    if [ -f "./certbot/conf/live/$domain/fullchain.pem" ]; then
        echo "✅ Certificate exists for $domain"
        return 0
    else
        echo "❌ No certificate found for $domain"
        return 1
    fi
}

# Function to check certificate expiry
check_expiry() {
    local domain=$1
    if cert_exists "$domain"; then
        local expiry=$(openssl x509 -noout -dates -in "./certbot/conf/live/$domain/fullchain.pem" | grep "notAfter" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry" +%s)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        echo "Certificate for $domain expires in $days_left days ($expiry)"
        
        if [ $days_left -lt 30 ]; then
            echo "⚠️  Certificate expires soon!"
            return 1
        fi
        return 0
    else
        return 1
    fi
}

# Create required directories
echo "Creating SSL directories..."
mkdir -p certbot/conf certbot/www/.well-known/acme-challenge
chmod -R 755 certbot/

# Download SSL configuration files
echo "Downloading SSL configuration..."
if [ ! -f "certbot/conf/options-ssl-nginx.conf" ]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
fi

if [ ! -f "certbot/conf/ssl-dhparams.pem" ]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem
fi

# Function to get certificate
get_certificate() {
    local domain_list=$1
    local cert_name=$2
    
    echo "Getting certificate for: $domain_list"
    echo "Certificate name: $cert_name"
    
    # Build domain arguments
    local domain_args=""
    IFS=',' read -ra DOMAINS <<< "$domain_list"
    for domain in "${DOMAINS[@]}"; do
        domain_args="$domain_args -d $domain"
    done
    
    # Set staging flag if testing
    local staging_arg=""
    if [ $STAGING = 1 ]; then
        staging_arg="--staging"
    fi
    
    # Request certificate
    docker compose run --rm certbot \
        certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        $staging_arg \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --cert-name $cert_name \
        --expand \
        $domain_args
}

# Check and get certificates for each domain group
echo "Checking/getting SSL certificates..."

# Main domain group
if ! check_expiry "ai-workflow-hub.com"; then
    get_certificate "ai-workflow-hub.com,www.ai-workflow-hub.com,automation.ai-workflow-hub.com" "ai-workflow-hub.com"
fi

# Reviews domain
if ! check_expiry "honest-ai-reviews.com"; then
    get_certificate "honest-ai-reviews.com,www.honest-ai-reviews.com" "honest-ai-reviews.com"
fi

# Fintech domain
if ! check_expiry "fintech-insider.com"; then
    get_certificate "fintech-insider.com,www.fintech-insider.com" "fintech-insider.com"
fi

echo "=== Certificate Status ==="
check_expiry "ai-workflow-hub.com" || true
check_expiry "honest-ai-reviews.com" || true  
check_expiry "fintech-insider.com" || true

echo "=== SSL Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Run: ./configure-ssl-nginx.sh (to enable HTTPS)"
echo "2. Set up auto-renewal: ./setup-renewal.sh"
echo "3. Test HTTPS: curl -I https://ai-workflow-hub.com"