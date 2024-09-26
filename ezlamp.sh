#!/bin/bash

# Function to pause for a specified duration or until Enter is pressed
pause() {
    echo "Press Enter to continue or wait for 3 seconds..."
    
    # Use a background job to wait for user input
    read -t 3 -p "" # -t specifies timeout in seconds

    # If the user pressed Enter, we simply return. If the timeout happens, continue.
    if [ $? -eq 0 ]; then
        echo "Continuing..."
    else
        echo "Continuing automatically after 3 seconds..."
    fi
}


# Define colors for the rainbow gradient
colors=(31 33 32 36 34 35 37) # ANSI color codes

# ASCII art to be colorized
ascii_art="
 ░▒▓██████▓▒░░▒▓██████████████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓███████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓███████▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░ ░▒▓██████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░  ░▒▓█▓▒░          ░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░  ░▒▓█▓▒░          ░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓███████▓▒░   ░▒▓█▓▒░   ░▒▓███████▓▒░  
"

# Function to print colored ASCII art
print_colored_ascii() {
    local line
    local color_index=0

    while IFS= read -r line; do
        # Print each character with the corresponding color
        for (( i=0; i<${#line}; i++ )); do
            char="${line:i:1}"
            # Print the character with the color
            if [[ "$char" =~ [░▒▓█] ]]; then
                # Use color from the colors array
                echo -ne "\033[${colors[$color_index]}m$char"
                # Cycle through colors
                color_index=$(( (color_index + 1) % ${#colors[@]} ))
            else
                echo -n "$char" # Print uncolored characters as they are
            fi
        done
        echo -ne "\033[0m" # Reset color
        echo # New line
    done <<< "$1"
}

# Print the welcome banner
print_colored_ascii "$ascii_art"
echo "Welcome to the ezlamp installation script!"


# Ask for sudo password and preauthorize
echo "You may be prompted for your sudo password during the installation process."

# Update package list
echo "Updating package list..."
sudo apt update

# Install Apache2
echo "Installing Apache2..."
sudo apt install -y apache2

# Check UFW Firewall
echo "Checking UFW Firewall configuration..."
sudo ufw app list
pause

# Whitelist Apache in UFW
echo "Allowing Apache through UFW..."
sudo ufw allow in "Apache"
pause

# Check UFW status
echo "Verifying UFW status..."
sudo ufw status
pause



# Function to print text in color
print_color() {
    case $1 in
        "red")
            echo -e "\e[31m$2\e[0m"  # Red
            ;;
        "green")
            echo -e "\e[32m$2\e[0m"  # Green
            ;;
        *)
            echo "$2"  # Default
            ;;
    esac
}


# Check Apache2 status
echo "Checking Apache2 status..."
if systemctl is-active --quiet apache2; then
    print_color "green" "Apache2 is running."
else
    print_color "red" "Apache2 is not running."
fi


# Check if MySQL or MySQL Server is installed
if ! dpkg -l | grep -qE 'mysql|mysql-server'; then
    echo "MySQL or MySQL Server is not installed."
    
    # Install MySQL Server
    echo "Installing MySQL Server..."
    sudo apt update
    sudo apt install -y mysql-server

    # Check installation status
    if dpkg -l | grep -q mysql-server; then
        echo "MySQL Server installed successfully."
    else
        echo "Failed to install MySQL Server."
        exit 1
    fi
else
    echo "MySQL or MySQL Server is already installed."
fi


# Prompt to change MySQL root password
read -p "Would you like to change the MySQL root password? (Y/N, Default: [N]): " change_password
change_password="${change_password:-no}"  # Default to "no" if no input

if [[ "$change_password" == "yes" ]]; then
    read -sp "Enter new MySQL root password: " new_password
    echo
    echo "Configuring MySQL..."
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$new_password';"
    echo "MySQL root password changed successfully."
else
    echo "MySQL root password remains unchanged."
fi

# Prompt to run MySQL secure installation
read -p "Would you like to run MySQL secure installation? (Y/N, Default: [N]): " run_secure_installation
run_secure_installation="${run_secure_installation:-no}"  # Default to "no" if no input

if [[ "$run_secure_installation" == "yes" ]]; then
    echo "Running MySQL secure installation..."
    sudo mysql_secure_installation
else
    echo "MySQL secure installation skipped."
fi

# Check PHP version
echo "Checking PHP version..."
php_version=$(php -v | grep -oP 'PHP \K[0-9.]+')
latest_php_version="8.2" # Update this to the latest PHP version as necessary

if [[ -z "$php_version" ]]; then
    echo "PHP is not installed. Installing latest PHP version..."
    sudo apt update
    sudo apt install -y php libapache2-mod-php php-mysql
elif [[ "$php_version" < "$latest_php_version" ]]; then
    echo "PHP version $php_version is outdated. Updating to latest PHP version..."
    sudo apt update
    sudo apt install -y php libapache2-mod-php php-mysql
else
    echo "PHP version $php_version is the latest. Skipping installation."
fi

# Check if Certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Certbot is not installed. Installing Certbot with Apache and Python plugins..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-apache
    echo "Certbot installed successfully."
else
    echo "Certbot is already installed."
fi


# Prompt for domain name
read -p "Enter the domain name (without www): " domainname

# Prompt to ask if the domain requires a www
read -p "Does the domain require a 'www' subdomain? (yes/no, default: no): " require_www
require_www="${require_www:-no}"

# Set the ServerAlias based on user input
if [[ "$require_www" == "yes" ]]; then
    server_alias="www.$domainname"
else
    server_alias=""
fi

# Prompt for Apache directory location, default to /var/www/$domainname
read -p "Enter the Apache document root directory (default: /var/www/$domainname): " apache_dir
apache_dir="${apache_dir:-/var/www/$domainname}"

# Prompt for the admin email
read -p "Enter the email address for the admin contact: " server_admin

# Check if the domain already exists
if [ -d "/var/www/$domainname" ]; then
    read -p "$domainname already exists. Would you like to replace it? ([Y/N], Default: [N]): " replace
    replace="${replace:-n}"  # Default to "n" if no input

    if [[ "$replace" != "y" && "$replace" != "Y" ]]; then
        echo "Exiting script."
        exit 1
    fi

    sudo rm -rf /var/www/$domainname
fi

# Create directory for the domain
echo "Creating directory for $domainname..."
sudo mkdir /var/www/$domainname



# Check if the Apache configuration file already exists
config_file="/etc/apache2/sites-available/$domainname.conf"
if [[ -f "$config_file" ]]; then
    echo "Apache configuration file for $domainname already exists. Skipping file generation."
else
    # Generate Apache configuration file
    cat <<EOL | sudo tee "$config_file"
<VirtualHost *:80>
    ServerAdmin $server_admin
    DocumentRoot $apache_dir
    ServerName $domainname
    $(if [ -n "$server_alias" ]; then echo "ServerAlias $server_alias"; fi)

    <Directory $apache_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$domainname-error.log
    CustomLog \${APACHE_LOG_DIR}/$domainname-access.log combined
</VirtualHost>
EOL

    echo "Apache configuration file for $domainname created successfully."
fi

# Check if the domain is enabled
if apache2ctl -S 2>/dev/null | grep -q "$domainname"; then
    echo "The domain $domainname is already enabled."
else
    echo "The domain $domainname is not enabled. Enabling now..."
    sudo a2ensite "$domainname.conf"
    sudo systemctl reload apache2
    echo "The domain $domainname has been enabled."
fi

# Disable default site
echo "Disabling the default site..."
sudo a2dissite 000-default

# Delete both default Apache configuration files
echo "Deleting default Apache configuration files..."
sudo rm -f /etc/apache2/sites-available/000-default.conf
sudo rm -f /etc/apache2/sites-enabled/000-default.conf

echo "Default site disabled and configuration files deleted successfully."

# Apache config test
echo "Testing Apache configuration..."
if sudo apache2ctl configtest; then
    echo "Apache configuration test successful."

    # Reload Apache
    echo "Reloading Apache..."
    sudo systemctl reload apache2
else
    echo "Apache configuration test failed. Please check the configuration."
    read -p "Would you like to retry the configuration creation or quit? (retry/q): " user_choice
    if [[ "$user_choice" == "q" ]]; then
        echo "Exiting script."
        exit 0
    fi
    echo "Retrying configuration creation..."
fi

# Download index.html from the specified URL
echo "Downloading index.html..."
sudo curl -o /var/www/$domainname/index.html https://raw.githubusercontent.com/omnisophia/omnisys---auto-lamp/refs/heads/main/index.html

# Change ownership of index.html to www-data
echo "Changing ownership of index.html to www-data..."
sudo chown www-data:www-data /var/www/$domainname/index.html

echo "index.html downloaded and ownership set successfully."


# Create SSL configuration using Certbot 
if [[ "$require_www" == "yes" ]]; then
    echo "Creating SSL configuration for $domainname and www.$domainname using Certbot..."
    sudo certbot --apache -d "$domainname" -d "www.$domainname"
else
    echo "Creating SSL configuration for $domainname using Certbot..."
    sudo certbot --apache -d "$domainname"
fi

# Check if the SSL configuration was successful
if [ $? -eq 0 ]; then
    echo "SSL configuration for $domainname created successfully."
else
    echo "Failed to create SSL configuration for $domainname. Please check the output for errors."
fi

# Output the domain URL
echo "You can now visit your domain at http://$domainname"

echo "ezlamp installation completed!"
