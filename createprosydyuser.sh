# Create admin user
read -p "Enter username for admin: " ADMIN_USER
read -s -p "Enter password for admin: " ADMIN_PASS
echo
sudo prosodyctl register $ADMIN_USER $DOMAIN $ADMIN_PASS