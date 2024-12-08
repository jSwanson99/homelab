# CONFIG
JENKINS_URL="http://localhost:8080"
PLUGINS=(
  "git"
  "workflow-aggregator"
  "docker-workflow"
  "kubernetes"
  "credentials-binding"
  "timestamper"
  "matrix-auth"
  "ldap"
  "junit"
  "ssh-slaves"
)
jenkins_cli() {
  java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_INITIAL_ADMIN_USER:$JENKINS_INITIAL_ADMIN_PASSWORD" $1
}
install_plugin() {
  local plugin=$1
  echo "Installing plugin: $plugin"
  jenkins_cli "install-plugin \"$plugin:latest\" -deploy"
}

# INITIAL STARTUP
systemctl enable jenkins
systemctl start jenkins

echo "Waiting for Jenkins to generate initial admin password..."
while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  sleep 5
  ATTEMPTS=$((ATTEMPTS + 1))
done
if [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  echo "Error: Jenkins failed to create initialAdminPassword file after $MAX_ATTEMPTS attempts" >&2
  exit 1
fi


# INSTALL CLI
wget "$JENKINS_URL/jnlpJars/jenkins-cli.jar"


# SETUP INITIAL ADMIN USER
JENKINS_INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "jenkins.model.Jenkins.instance.securityRealm.createAccount(\"$JENKINS_INITIAL_ADMIN_USER\", \"$JENKINS_INITIAL_ADMIN_PASSWORD\")" \
  | java -jar ./jenkins-cli.jar \
  -s "$JENKINS_URL" \
  -auth "admin:$JENKINS_INITIAL_PASSWORD" \
  groovy = –

# INSTALL PLUGINS
#for plugin in "${PLUGINS[@]}"; do
  # install_plugin "$plugin"
#done
