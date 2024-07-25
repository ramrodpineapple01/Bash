#!/bin/bash
##Jorge Figoli

# Function to install Element
install_element() {
    # Update system
    sudo apt update && sudo apt upgrade -y

    # Install required dependencies
    sudo apt install -y wget

    # Create directory for Element
    sudo mkdir -p /var/www/element

    # Download the latest version of Element
    ELEMENT_VERSION=$(curl -s https://api.github.com/repos/vector-im/element-web/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    sudo wget -O /tmp/element.tar.gz https://github.com/vector-im/element-web/releases/download/${ELEMENT_VERSION}/element-${ELEMENT_VERSION}.tar.gz

    # Extract Element to the web directory
    sudo tar -xzf /tmp/element.tar.gz -C /var/www/element --strip-components=1

    # Remove the downloaded archive
    sudo rm /tmp/element.tar.gz

    echo "Element has been downloaded and extracted to /var/www/element"
}

# Function to configure Element
configure_element() {
    # Prompt for domain name
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

    # Prompt for Matrix homeserver URL
    read -p "Enter your Matrix homeserver URL (e.g., https://matrix.example.com): " HOMESERVER_URL

    # Create config.json for Element
    sudo tee /var/www/element/config.json <<EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "${HOMESERVER_URL}",
            "server_name": "${DOMAIN_NAME}"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "disable_custom_urls": false,
    "disable_guests": true,
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "brand": "Element",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "default_country_code": "GB",
    "show_labs_settings": false,
    "features": {},
    "default_federate": true,
    "default_theme": "light",
    "room_directory": {
        "servers": [
            "${DOMAIN_NAME}"
        ]
    },
    "enable_presence_by_hs_url": {
        "${HOMESERVER_URL}": true
    },
    "setting_defaults": {
        "breadcrumbs": true
    },
    "jitsi": {
        "preferred_domain": "meet.element.io"
    }
}
EOF

    echo "Element configuration file has been created."
}

# Function to configure Nginx for Element
configure_nginx() {
    # Prompt for domain name (if not already set)
    if [ -z "$DOMAIN_NAME" ]; then
        read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    fi

    # Create Nginx configuration for Element
    sudo tee /etc/nginx/sites-available/element <<EOF
server {
    listen 443 ssl;
    server_name ${DOMAIN_NAME};

    root /var/www/element;
    index index.html;

    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # Enable the new configuration
    sudo ln -s /etc/nginx/sites-available/element /etc/nginx/sites-enabled/

    # Test Nginx configuration
    sudo nginx -t

    # Reload Nginx
    sudo systemctl reload nginx

    echo "Nginx configuration for Element is complete."
}

# Main script execution
install_element
configure_element
configure_nginx

echo "Element installation and configuration are complete!"
echo "You can now access Element at https://${DOMAIN_NAME}"
