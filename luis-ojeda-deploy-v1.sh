#!/bin/bash
#Variables
REPO="https://github.com/roxsross/bootcamp-devops-2023.git"
DIR="bootcamp-devops-2023"
RAMA="clase2-linux-bash"
APP="app-295devops-travel"
USERID=$(id -u)
CONFIG_PHP="$DIR/$APP/config.php"

if [ "${USERID}" -ne 0 ]; then
    echo "Necesita ser usuario ROOT"
    exit
fi 

echo "=========STAGE 1: [Init]========="

apt-get update
echo -e "******El Servidor se encuentra Actualizado...******"

for programa in apache2 php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
do
    if dpkg -l | grep -q $programa ;
    then
        echo "******El programa $programa ya esta instalado******"
    else
        echo "******Instalando $programa******"
        apt install $programa -y
    fi
done

systemctl start apache2 
systemctl enable apache2

if dpkg -l | grep -q mariadb-server ;
then
    echo "******El programa mariadb-server ya esta instalado******"
else
    echo "******Instalando mariadb-server******"
    apt install mariadb-server -y
    systemctl start mariadb
    systemctl enable mariadb
fi

echo "=========STAGE 2: [Build]========="

# Clonando el repositorio validando si existe la carpeta o no
if [ -d "$DIR" ]; 
then
    echo "La carpeta $DIR ya existe ..."
    cd $DIR
    git pull origin $RAMA
    cd ../
else
    git clone $REPO --single-branch --branch $RAMA
fi

sleep 3

#Agregando contraseña al config.php

echo "STAGE 3: [Deploy]"

echo "Insertando contraseña a la base de datos...."
if [ -f "$CONFIG_PHP" ] ;
then
    sed -i 's/$dbPassword = "";/$dbPassword = "alpine";/' "$CONFIG_PHP"
    echo "La contraseña de la base de datos fue insertada en exitosamente en $CONFIG_PHP"
else
    echo "El archivo $CONFIG_PHP no existe en la ruta proporcionada."
    exit
fi

if [ -f "/var/www/html/index.html" ]; 
then
    mv /var/www/html/index.html /var/www/html/index.html.bkp
fi

#Moviendo archivos a la carpeta /var/www/html
cp -R $DIR/$APP/* /var/www/html/
echo "Se han copiado los archivos a la ruta /var/www/html." 
systemctl reload apache2

#Configurando la base de datos
if mysql -e "USE devopstravel;" 2>/dev/null; 
then
    echo "La base de datos 'devopstravel' ya existe..."
else
    echo "Configurando base de datos..."
    mysql -e "
    CREATE DATABASE devopstravel;
    CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'alpine';
    GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
    FLUSH PRIVILEGES;"
    mysql < $DIR/$APP/database/devopstravel.sql
fi 

echo "La applicacion ya esta en linea"

echo "=========Notificacion en discord========="

# Configura el token de acceso de tu bot de Discord
DISCORD="https://discord.com/api/webhooks/1154865920741752872/au1jkQ7v9LgQJ131qFnFqP-WWehD40poZJXRGEYUDErXHLQJ_BBszUFtVj8g3pu9bm7h"

# Cambia al directorio del repositorio
cd "$DIR"

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="192.168.56.102"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    ESTUDIANTE="Estudiante: Luis Ojeda"
    echo "$DEPLOYMENT_INFO"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
  echo "$DEPLOYMENT_INFO"
fi

# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION\n$ESTUDIANTE"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"