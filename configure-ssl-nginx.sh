#!/bin/bash
# configure-ssl-nginx.sh - Configure nginx with SSL certificates

set -e

echo "=== Configuring Nginx with SSL ==="

# Backup current nginx config
if [ -f "nginx/conf.d/default.conf" ]; then
    echo "Backing up current nginx config..."
    cp nginx/conf.d/default.conf nginx/conf.d/default.conf.backup.$(date +%s)
fi

# Create SSL-enabled nginx configuration
echo "Creating SSL-enabled nginx configuration..."
cat > nginx/conf.d/default.conf << 'EOF'
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=wp_login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=5r/s;

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name ai-workflow-hub.com www.ai-workflow-hub.com honest-ai-reviews.com www.honest-ai-reviews.com fintech-insider.com www.fintech-insider.com automation.ai-workflow-hub.com;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# AI Workflow Hub - Main Site (HTTPS)
server {
    listen 443 ssl http2;
    server_name ai-workflow-hub.com www.ai-workflow-hub.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/ai-workflow-hub.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ai-workflow-hub.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # WordPress security
    location ~ /\.ht { deny all; }
    location ~* \.(txt|log|conf)$ { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
    
    # Rate limiting for login
    location = /wp-login.php {
        limit_req zone=wp_login burst=5 nodelay;
        proxy_pass http://wordpress_ai_workflow:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Rate limiting for admin
    location ~ ^/wp-admin {
        limit_req zone=wp_admin burst=10 nodelay;
        proxy_pass http://wordpress_ai_workflow:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://wordpress_ai_workflow:80;
        proxy_set_header Host $host;
    }
    
    # WordPress REST API
    location ~ ^/wp-json/ {
        proxy_pass http://wordpress_ai_workflow:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Main WordPress proxy
    location / {
        proxy_pass http://wordpress_ai_workflow:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}

# Honest AI Reviews Site (HTTPS)
server {
    listen 443 ssl http2;
    server_name honest-ai-reviews.com www.honest-ai-reviews.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/honest-ai-reviews.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/honest-ai-reviews.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location ~ /\.ht { deny all; }
    location ~* \.(txt|log|conf)$ { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
    
    location = /wp-login.php {
        limit_req zone=wp_login burst=5 nodelay;
        proxy_pass http://wordpress_ai_reviews:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location ~ ^/wp-admin {
        limit_req zone=wp_admin burst=10 nodelay;
        proxy_pass http://wordpress_ai_reviews:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://wordpress_ai_reviews:80;
        proxy_set_header Host $host;
    }
    
    location ~ ^/wp-json/ {
        proxy_pass http://wordpress_ai_reviews:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        proxy_pass http://wordpress_ai_reviews:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}

# Fintech Insider Site (HTTPS)
server {
    listen 443 ssl http2;
    server_name fintech-insider.com www.fintech-insider.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/fintech-insider.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fintech-insider.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location ~ /\.ht { deny all; }
    location ~* \.(txt|log|conf)$ { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
    
    location = /wp-login.php {
        limit_req zone=wp_login burst=5 nodelay;
        proxy_pass http://wordpress_fintech:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location ~ ^/wp-admin {
        limit_req zone=wp_admin burst=10 nodelay;
        proxy_pass http://wordpress_fintech:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://wordpress_fintech:80;
        proxy_set_header Host $host;
    }
    
    location ~ ^/wp-json/ {
        proxy_pass http://wordpress_fintech:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        proxy_pass http://wordpress_fintech:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}

# n8n Automation Server (HTTPS)
server {
    listen 443 ssl http2;
    server_name automation.ai-workflow-hub.com;
    
    # SSL Configuration (uses same cert as main domain)
    ssl_certificate /etc/letsencrypt/live/ai-workflow-hub.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ai-workflow-hub.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        proxy_pass http://n8n_automation:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

# Test nginx configuration
echo "Testing nginx configuration..."
docker-compose exec nginx nginx -t

if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid!"
    
    # Reload nginx
    echo "Reloading nginx with SSL configuration..."
    docker-compose exec nginx nginx -s reload
    
    echo "=== SSL Configuration Complete! ==="
    echo ""
    echo "Your sites should now be accessible via HTTPS:"
    echo "- https://ai-workflow-hub.com"
    echo "- https://honest-ai-reviews.com" 
    echo "- https://fintech-insider.com"
    echo "- https://automation.ai-workflow-hub.com"
    echo ""
    echo "Testing HTTPS access..."
    sleep 3
    
    # Test SSL certificates
    for domain in ai-workflow-hub.com honest-ai-reviews.com fintech-insider.com; do
        echo "Testing https://$domain"
        curl -I https://$domain 2>/dev/null | head -1 || echo "❌ Failed to connect to https://$domain"
    done
else
    echo "❌ Nginx configuration has errors! Please check the logs."
    exit 1
fi
