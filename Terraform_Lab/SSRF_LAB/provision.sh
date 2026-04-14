#!/bin/bash

# SELF-DIAGNOSING PROVISIONING SCRIPT
LOG_FILE="/var/log/lab-setup.log"
STATUS_FILE="/var/www/provisioning_status.json"

# Capture all output
exec &>> >(tee -a "$LOG_FILE")

echo "[$(date)] --- STARTING DIAGNOSTIC PROVISIONING ---"

# Step 1: Robust Apt Install with Retries
echo "[$(date)] Step 1: Installing dependencies (with retries)..."
SUCCESS=false
for i in {1..5}; do
    if sudo apt-get update && sudo apt-get install -y python3-flask python3-requests; then
        echo "Apt install successful on attempt $i"
        SUCCESS=true
        break
    fi
    echo "Apt lock or network failure (Attempt $i). Waiting 30s..."
    sleep 30
done

if [ "$SUCCESS" = false ]; then
    echo "FATAL: Apt installation failed after 5 attempts."
    PROV_STATUS="failed_apt"
else
    # Step 2: Directory setup
    sudo mkdir -p /var/www
    sudo chown -R root:root /var/www
    
    # Step 3: Service configuration
    cat << 'SERVICE' > /etc/systemd/system/vuln-api.service
[Unit]
Description=Vulnerable SSRF API (Diagnostic Build)
After=network.target

[Service]
User=root
WorkingDirectory=/var/www
ExecStart=/usr/bin/python3 /var/www/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

    sudo systemctl daemon-reload
    sudo systemctl enable vuln-api.service
    sudo systemctl start vuln-api.service
    PROV_STATUS="success"
fi

# Create status file for the UI
echo "{\"status\": \"$PROV_STATUS\", \"timestamp\": \"$(date)\"}" > $STATUS_FILE

echo "[$(date)] --- PROVISIONING COMPLETE ($PROV_STATUS) ---"

# --- CALL HOME FEATURE ---
# Upload this log back to the Storage account for remote debugging
echo "[$(date)] Calling Home: Uploading diagnostic_boot.log..."
TOKEN=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://storage.azure.com/" | sed -E 's/.*"access_token":"([^"]+)".*/\1/')

# Use the environment variable passed from Terraform for the URL
# Actually, I'll just hardcode it using the interpolation from TF compute.tf
# No, let's just use the logic from compute.tf bootstrap to find it.
# Actually, the bootstrap script already knows the URL. 
# I'll have the bootstrap script pass the LOG_UPLOAD_URL as an environment variable or just run it there.
