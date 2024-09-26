# LAMP Stack Setup Script

This script automates the installation and configuration of an Apache web server as part of a LAMP (Linux, Apache, MySQL, PHP) stack for a specified domain.

## Features

- Checks if the Apache configuration file for the domain already exists.
- Generates a new Apache virtual host configuration file if it does not exist.
- Enables the specified site and disables the default site.
- Tests the Apache configuration for errors before reloading.
- Creates a basic `index.html` file containing colorful ASCII art.
- Provides the URL for accessing the newly created domain.

## Requirements
- Sufficient permissions to run the script (e.g., root or sudo access).

## Usage

1. Clone the repository or download the script.
2. Make the script executable:
   ```bash
   chmod +x OmnisysAutoLAMP.sh
