#! /bin/bash

set -e
GITHUB_TOKEN=$1
echo "ghtoken: $GITHUB_TOKEN"

chmod +x /tmp/access-token.rb
TOKEN=$(gitlab-rails runner /tmp/access-token.rb)
TOKEN=$(echo $TOKEN | sed 's/.*: //')
rm /tmp/access-token.rb

echo "disabling public signups"
curl -X PUT -k https://localhost/api/v4/application/settings \
	-H "PRIVATE-TOKEN: $TOKEN" \
	-d "signup_enabled=false"
