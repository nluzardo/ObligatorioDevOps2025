#!/bin/bash
set -xe
# -x imprime cada comando antes de ejecutarlo
# -e detiene el script si hay error

exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

# Variables reemplazadas por Python al crear la EC2
DB_HOST="__DB_HOST__"
DB_PORT="__DB_PORT__"
DB_APP_USER="__DB_APP_USER__"
DB_APP_PASSWORD="__DB_APP_PASSWORD__"
DB_NAME="__DB_APP_NAME__"

DB_MASTER_USER="__DB_MASTER_USER__"
DB_MASTER_PASSWORD="__DB_MASTER_PASSWORD__"
APP_ADMIN_USER="__APP_ADMIN_USER__"
APP_ADMIN_PASSWORD="__APP_ADMIN_PASSWORD__"
APP_REPO_URL="__APP_REPO_URL__"

# --- 1) Actualizar paquetes e instalar dependencias ---
dnf update -y
dnf install -y httpd php php-cli php-fpm php-mysqlnd mariadb105 git

# Habilitar y arrancar Apache + PHP-FPM
systemctl enable --now httpd php-fpm

# --- 2) Clonar la aplicación PHP ---
git clone ${APP_REPO_URL} /var/www/html
chown -R apache:apache /var/www/html

# --- 3) Crear archivo .env para la app ---
cat > /var/www/.env <<EOF
DB_HOST=${DB_HOST}
DB_NAME=${DB_NAME}
DB_USER=${DB_APP_USER}
DB_PASS=${DB_APP_PASSWORD}

APP_USER=${APP_ADMIN_USER}
APP_PASS=${APP_ADMIN_PASSWORD}
EOF

chown apache:apache /var/www/.env
chmod 600 /var/www/.env

# --- 4) Inicializar base de datos ---
mysql -h "${DB_HOST}" -u "${DB_MASTER_USER}" -p"${DB_MASTER_PASSWORD}" <<EOSQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_APP_USER}'@'%' IDENTIFIED BY '${DB_APP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_APP_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

# Ejecutar script init_db.sql si existe en el repo
if [ -f /var/www/init_db.sql ]; then
  mysql -h "${DB_HOST}" -u "${DB_APP_USER}" -p"${DB_APP_PASSWORD}" "${DB_NAME}" < /var/www/init_db.sql
fi

# --- 5) Archivo de prueba PHP ---
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown apache:apache /var/www/html/info.php

# --- 6) Reiniciar servicios ---
systemctl restart httpd php-fpm