#!/bin/bash

export RESOURCE_GROUP="rg-sprint3"
export LOCATION="westus"

export APP_NAME="sprint3-java-app"
export APP_RUNTIME="JAVA|17-java17"
export APP_INSIGHTS="ai-sprint3"

export GITHUB_REPO="omininola/sprint3_java_deploy"
export BRANCH="main"

export DB_SERVER_NAME="sprint3-cloud-rm554513"
export DB_NAME="sprint3"
export DB_USER="omininola"
export DB_PASS="SenhaForte123!"

# SPRING_DATASOURCE_URL = jdbc:sqlserver://sprint3-cloud-rm554513.database.windows.net:1433;database=sprint3;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;
# SPRING_DATASOURCE_USERNAME = omininola@sprint3-cloud-rm554513
# SPRING_DATASOURCE_PASSWORD = SenhaForte123!

# Registra os Providers
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ServiceLinker
az provider register --namespace Microsoft.Sql

# Criar o Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar o Application Insights
az monitor app-insights component create \
  --app $APP_INSIGHTS \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Criar o Plano de Serviço
az appservice plan create \
  --name $APP_NAME-plan \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku B1 \
  --is-linux

# Criar o Serviço de APlicativo
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_NAME-plan \
  --name $APP_NAME \
  --runtime $APP_RUNTIME

# Habilita a autenticação básica (SCM)
az resource update \
  --resource-group $RESOURCE_GROUP \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent sites/$APP_NAME \
  --set properties.allow=true

# Recuperar a String de Conexão do Application Insights
CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --query connectionString \
  --output tsv)

# Configurar as Variáveis de Ambiente
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="Recommended" \
    XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
    SPRING_DATASOURCE_USERNAME="$DB_USER@$DB_SERVER_NAME" \
    SPRING_DATASOURCE_PASSWORD="$DB_PASS" \
    SPRING_DATASOURCE_URL="jdbc:sqlserver://$DB_SERVER_NAME.database.windows.net:1433;database=$DB_NAME;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

# Reiniciar o App
az webapp restart \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP

# Criar a conexão App com o Application Insights
az monitor app-insights component connect-webapp \
  --app $APP_INSIGHTS \
  --web-app $APP_NAME \
  --resource-group $RESOURCE_GROUP

# Configurar Github Actions
az webapp deployment github-actions add \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --repo $GITHUB_REPO \
  --branch $BRANCH \
  --login-with-github

# Criar SQL Server 
az sql server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER_NAME \
  --location $LOCATION \
  --admin-user $DB_USER \
  --admin-password $DB_PASS \
  --enable-public-network true

# Criar o banco
az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server $DB_SERVER_NAME \
  --name $DB_NAME \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false

# Liberar os IPS de acesso ao banco
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $DB_SERVER_NAME \
  --name AllowAll \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255
