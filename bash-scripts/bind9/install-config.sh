#!/bin/bash

# Prompt for the domain name
read -p "Enter the domain name (e.g., example.com): " domain

# Prompt for the number of subdomains
read -p "Enter the number of subdomains: " num_subdomains

# Prompt for the IP address for domain resolving
read -p "Enter the IP address for domain resolving: " ip_address

# Create the zones directory if it doesn't exist
zones_dir="/etc/bind/named/zones"
if [ ! -d "$zones_dir" ]; then
  sudo mkdir -p "$zones_dir"
fi

# Install Bind9 if not already installed
sudo apt-get update
sudo apt-get install bind9

# Create a new zone file for the domain
cat <<EOF | sudo tee "$zones_dir/db.$domain"
\$TTL    604800
@       IN      SOA     ns1.$domain. admin.$domain. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain.
ns1     IN      A       $ip_address
EOF

# Add the zone configuration to named.conf.local
echo "zone \"$domain\" {
    type master;
    file \"$zones_dir/db.$domain\";
};" | sudo tee -a /etc/bind/named.conf.local

# Create subdomains if specified
for ((i=1; i<=$num_subdomains; i++)); do
    read -p "Enter subdomain $i: " subdomain
    echo "$subdomain     IN      A       $ip_address" | sudo tee -a "$zones_dir/db.$domain"
done

# Reload Bind9 to apply changes
sudo systemctl reload bind9

echo "DNS zone for $domain has been configured."
