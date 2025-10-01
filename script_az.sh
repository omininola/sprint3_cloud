az login

RESOURCE_GROUP=rg_sprint3
LOCATION=eastus2
APP_NAME=sprint3-java-app
GITHUB_REPO=omininola/sprint3_java
BRANCH=main
DB_SERVER_NAME=sprint3-java
DB_NAME=sprint3
DB_USER=omininola
DB_PASS=SenhaForte123!

az group create --name $RESOURCE_GROUP --location $LOCATION

az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.Web

az sql server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER_NAME \
  --location $LOCATION \
  --admin-user $DB_USER \
  --admin-password $DB_PASS \
  --enable-public-network true

az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server $DB_SERVER_NAME \
  --name $DB_NAME
  --backup-storage-redundancy Local \
  --zone-redundant false

az mysql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER_NAME \
  --name AllowAzureIP \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az appservice plan create \
  --name $APP_NAME-plan \
  --resource-group $RESOURCE_GROUP \
  --sku F1 \
  --is-linux

az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_NAME-plan \
  --name $APP_NAME \
  --runtime "JAVA|17-java17"

az resource update \
  --resource-group $RESOURCE_GROUP \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent sites/$APP_NAME \
  --set properties.allow=true

az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $DB_SERVER_NAME \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    SPRING_DATASOURCE_USERNAME="$DB_USER@$DB_SERVER_NAME" \
    SPRING_DATASOURCE_PASSWORD="$DB_PASS" \
    SPRING_DATASOURCE_URL="jdbc:sqlserver://$DB_SERVER_NAME.database.windows.net:1433;database=$DB_NAME;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

az webapp restart \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP

az webapp deployment github-actions add \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --repo $GITHUB_REPO \
  --branch $BRANCH \
  --login-with-github

az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME
az sql server show --resource-group $RESOURCE_GROUP --name $DB_SERVER_NAME