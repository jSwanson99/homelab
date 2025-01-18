#!/bin/bash

set -e  # Exit on any error
set -x  # Print commands as they're executed

echo 'export VAULT_ADDR="https://${split("/", pg_vault_ip)[0]}:8200"' >> /etc/profile
source /etc/profile

info=$(vault operator init -format=json)
echo $info
unseals=$(echo $info | jq -r '.unseal_keys_b64[]')
echo "$unseals" | while read -r key; do
    vault operator unseal "$key"
done

root_token=$(echo $info | jq -r '.root_token')
echo $info > /tmp/secret.json
vault login $root_token

pg_database_vault=$1
pg_user_vault=$2
pg_password_vault=$3

# Try to get vault status first to check connectivity
vault status || {
    echo "Failed to connect to Vault"
    echo "Vault Address: $VAULT_ADDR"
    exit 1
}

# Enable database secrets engine
vault secrets enable database || {
    echo "Failed to enable database secrets engine"
    exit 1
}

# Rest of your commands with error checking
vault write database/config/${pg_database_vault} \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="vault_temp_user" \
    connection_url="postgresql://${pg_user_vault}:${pg_password_vault}@localhost:5432/${pg_database_vault}" \
    username="${pg_user_vault}" \
    password="${pg_password_vault}" \
    password_authentication="scram-sha-256" || {
    echo "Failed to configure database connection"
    exit 1
}

vault write database/roles/vault_temp_user \
    db_name="${pg_database_vault}" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h" || {
    echo "Failed to configure database role"
    exit 1
}
