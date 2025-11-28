#!/bin/bash
set -xe
exec > >(tee /var/log/user-data.log | logger -t user-data ) 2>&1

#
# VARIABLES REEMPLAZADAS POR crear_infra.py
#
DB_HOST="__DB_HOST__"
DB_PORT="__DB_PORT__"
DB_APP_USER="__DB_APP_USER__"
DB_APP_PASSWORD="__DB_APP_PASSWORD__"
DB_NAME="__DB_APP_NAME__"

DB_MASTER_USER="__DB_MASTER_USER__"
DB_MASTER_PASSWORD="__DB_MASTER_PASSWORD__"

APP_REPO_URL="__APP_REPO_URL__"
APP_ADMIN_USER="__APP_ADMIN_USER__"
APP_ADMIN_PASSWORD="__APP_ADMIN_PASSWORD__"

APP_DIR="/var/www/html"
SAFE_DIR="/var/www"

###############################################
# 1) Actualizar sistema e instalar Apache + PHP
###############################################
dnf clean all
dnf makecache
dnf -y update

dnf -y install httpd php php-cli php-fpm php-common php-mysqlnd mariadb105 git

systemctl enable --now httpd
systemctl enable --now php-fpm

# Configurar PHP-FPM
cat > /etc/httpd/conf.d/php-fpm.conf <<'EOF'
<FilesMatch \.php$>
  SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
</FilesMatch>
EOF

###############################################
# 2) Clonar la aplicación
###############################################
git clone ${APP_REPO_URL} /tmp/app
chown -R apache:apache /tmp/app

###############################################
# 3) Copiar app al webroot
###############################################
rm -rf ${APP_DIR}/*
cp -R /tmp/app/* ${APP_DIR}/
chown -R apache:apache ${APP_DIR}

###############################################
# 4) Mover init_db.sql fuera del webroot
###############################################
if [ -f /tmp/app/init_db.sql ]; then
  cp /tmp/app/init_db.sql ${SAFE_DIR}/init_db.sql
  chown apache:apache ${SAFE_DIR}/init_db.sql
  chmod 600 ${SAFE_DIR}/init_db.sql
fi

###############################################
# 5) Crear archivo .env en el MISMO DIRECTORIO
#    que config.php → /var/www/html/.env
###############################################
cat > ${APP_DIR}/.env <<EOF
DB_HOST=${DB_HOST}
DB_NAME=${DB_NAME}
DB_USER=${DB_APP_USER}
DB_PASS=${DB_APP_PASSWORD}

APP_USER=${APP_ADMIN_USER}
APP_PASS=${APP_ADMIN_PASSWORD}
EOF

chown apache:apache ${APP_DIR}/.env
chmod 600 ${APP_DIR}/.env

###############################################
# 6) Crear BD y usuario de aplicación (admin)
###############################################
mysql -h "${DB_HOST}" -u "${DB_MASTER_USER}" -p"${DB_MASTER_PASSWORD}" <<MYSQL_EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_APP_USER}'@'%' IDENTIFIED BY '${DB_APP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_APP_USER}'@'%';
FLUSH PRIVILEGES;
MYSQL_EOF

###############################################
# 7) Ejecutar init_db.sql completo como ADMIN
###############################################
if [ -f ${SAFE_DIR}/init_db.sql ]; then
  mysql -h "${DB_HOST}" -u "${DB_MASTER_USER}" -p"${DB_MASTER_PASSWORD}" < ${SAFE_DIR}/init_db.sql
fi

###############################################
# 8) Permisos finales y reinicio
###############################################
chown -R apache:apache ${APP_DIR}
systemctl restart httpd php-fpm
