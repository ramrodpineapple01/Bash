#!/bin/bash
# Jorge Figoli 
# Im still working on my some of my commands so this is for testing only//NOT FOR PUBLICATION YET
# Function to install Matrix Synapse
install_matrix_synapse() {
    # Update and upgrade the system
    sudo apt update && sudo apt upgrade -y

    # Install required dependencies
    sudo apt install -y python3-pip python3-venv

    # Add Matrix repository
    sudo apt install -y lsb-release wget apt-transport-https
    sudo wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/matrix-org.list

    # Update package list
    sudo apt update

    # Install Matrix Synapse
    sudo apt install -y matrix-synapse-py3

    # Generate a configuration file
    sudo matrix-synapse-generate-config

    # Prompt for server name
    read -p "Enter your server name (e.g., matrix.example.com): " SERVER_NAME

    # Update the configuration file with the server name
    sudo sed -i "s/server_name: \"localhost\"/server_name: \"$SERVER_NAME\"/" /etc/matrix-synapse/homeserver.yaml

    # Start Matrix Synapse service
    sudo systemctl start matrix-synapse

    # Enable Matrix Synapse to start on boot
    sudo systemctl enable matrix-synapse

    echo "Matrix Synapse installation complete!"
}

# Function to install and configure Nginx
install_configure_nginx() {
    # Install Nginx
    sudo apt install -y nginx

    # Prompt for domain name
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

    # Create Nginx configuration for Matrix Synapse
    sudo tee /etc/nginx/sites-available/matrix-synapse <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    location /_matrix {
        proxy_pass http://localhost:8008;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable the new configuration
    sudo ln -s /etc/nginx/sites-available/matrix-synapse /etc/nginx/sites-enabled/

    # Remove default Nginx configuration
    sudo rm /etc/nginx/sites-enabled/default

    # Test Nginx configuration
    sudo nginx -t

    # Reload Nginx
    sudo systemctl reload nginx

    echo "Nginx installation and configuration complete!"
}

# Function to install and configure Certbot
install_configure_certbot() {
    # Install Certbot
    sudo apt install -y certbot python3-certbot-nginx

    # Obtain SSL certificate
    sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME

    # Set up auto-renewal
    echo "0 0,12 * * * root /usr/bin/certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null

    echo "SSL certificate installation complete!"
}

# Main script execution
install_matrix_synapse
install_configure_nginx
install_configure_certbot

echo "Installation and configuration of Matrix Synapse, Nginx, and SSL certificate are complete!"
echo "Your Matrix server should now be accessible at https://$DOMAIN_NAME"
