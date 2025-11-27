#!/bin/bash
set -xe
# -x imprime cada comando antes de ejecutarlo
# -e el script se detiene si hay un error

exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1
# stdout y stderr del script se mandan a /var/log/user-data.log
# tambien se envia a /var/log/messages


EC2_APP_USER="__EC2_APP_USER__"
EC2_APP_GROUP="__EC2_APP_GROUP__"
APP_REPO_URL="__APP_REPO_URL__"
APP_DIR="__APP_DIR__"
APP_PORT="__APP_PORT__"
DB_HOST="__DB_HOST__"
DB_PORT="__DB_PORT__"
DB_APP_USER="__DB_APP_USER__"
DB_APP_PASSWORD="__DB_APP_PASSWORD__"
DB_NAME="__DB_APP_NAME__"

DB_MASTER_USER="__DB_MASTER_USER__"
DB_MASTER_PASSWORD="__DB_MASTER_PASSWORD__"
APP_ADMIN_PASSWORD="__APP_ADMIN_PASSWORD__"
APP_ADMIN_USER="__APP_ADMIN_USER__"

# actualizar paquetes e instalar aplicaciones necesarias
dnf update -y
dnf install -y mariadb105-server-utils.x86_64 git nginx 

# levantar el nginx
systemctl enable nginx 
systemctl start nginx 

# instalar nodejs en version 20.x
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs 

# instalar pm2 globalmente
npm install -g pm2 

# Crear el directorio de la app node
mkdir -p /var/www 
chown -R ${EC2_APP_USER}:${EC2_APP_GROUP} /var/www

# Clonamos el repositorio
sudo -u ${EC2_APP_USER} -H bash -lc "
  cd /var/www
  git clone ${APP_REPO_URL} socios-app
"

# Instalar las dependecias de la app nodejs
sudo -u ${EC2_APP_USER} -H bash -lc "
  cd ${APP_DIR}
  npm install
  mkdir -p logs
"

# Crear el archivo .env para la app nodejs
sudo -u ${EC2_APP_USER} -H bash -lc "
  cat > ${APP_DIR}/.env <<EOF
PORT=${APP_PORT}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_APP_USER}
DB_PASSWORD=${DB_APP_PASSWORD}
DB_NAME=${DB_NAME}
SESSION_SECRET=$(openssl rand -hex 32)
EOF
"

# Crear base de datos y usuario app_user usando el USUARIO MAESTRO
mysql -h "${DB_HOST}" -u "${DB_MASTER_USER}" -p"${DB_MASTER_PASSWORD}" <<EOSQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_APP_USER}'@'%' IDENTIFIED BY '${DB_APP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_APP_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

# 2) Crear tablas con schema.sql usando app_user
mysql -h "${DB_HOST}" -u "${DB_APP_USER}" -p"${DB_APP_PASSWORD}" "${DB_NAME}" < "${APP_DIR}/sql/schema.sql"

# 3) Crear usuario admin en la tabla users
#    - Generamos el hash con generate_hash.js
#    - Creamos un insert_admin.sql con ese hash
cd "${APP_DIR}"

HASH=$(node sql/generate_hash.js "${APP_ADMIN_PASSWORD}" | grep "Hash generado" | awk '{print $3}')

cat > sql/insert_admin.sql <<EOSQL
INSERT IGNORE INTO users (username, password_hash)
VALUES ('${APP_ADMIN_USER}', '${HASH}');
EOSQL

# Ejecutar el insert del admin
mysql -h "${DB_HOST}" -u "${DB_APP_USER}" -p"${DB_APP_PASSWORD}" "${DB_NAME}" < "${APP_DIR}/sql/insert_admin.sql"

# Iniciar aplicación con PM2 (como ec2-user)
sudo -u ${EC2_APP_USER} -H bash -lc "
  cd ${APP_DIR}
  pm2 start ecosystem.config.js --env production
  pm2 save
"

# Registrar PM2 como servicio de systemd para ec2-user
pm2 startup systemd -u ${EC2_APP_USER} --hp /home/${EC2_APP_USER}

# Configurar Nginx como reverse proxy
cat > /etc/nginx/conf.d/socios-app.conf <<EOF
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_read_timeout 60s;
    }
}
EOF

nginx -t
systemctl reload nginx
