#!/bin/bash

# ==========================================
# 1. VARIABLES SEGÚN TABLA DE EXAMEN
# ==========================================
# Dominios y Correos
DOMINIO_1="www.intranet.kuy.com"
ALIAS_1="aplicacion.intranet.kuy.com"
EMAIL_1="contacto@kuy.com"

DOMINIO_2="www.sistema.kuy.org"
ALIAS_2="aplicacion.sistema.kuy.org"
EMAIL_2="contacto@kuy.org"

# Rutas de Directorio Raíz
ROOT_1="/var/www/appintranet"
ROOT_2="/var/www/appsistema"

# Rutas de Directorio Privado (según tabla)
PRIV_1="/srv/www/appintranet/privado"
PRIV_2="/srv/www/appsistema/privado"

# ==========================================
# 2. INSTALACIÓN Y DIRECTORIOS
# ==========================================
sudo apt update && sudo apt install apache2 apache2-utils -y
sudo a2enmod ssl cgi rewrite authz_host

# Crear carpetas de aplicación y logs
sudo mkdir -p $ROOT_1/logs $ROOT_2/logs $PRIV_1 $PRIV_2 /etc/apache2/ssl

# Crear archivos index y error 404 (con el texto exacto de la tabla)
echo "<h1>Benvinguts a $DOMINIO_1</h1>" | sudo tee $ROOT_1/index.html
echo "Error en la aplicacion web appintranet - archivo no encontrado" | sudo tee $ROOT_1/404.html

echo "<h1>Benvinguts a $DOMINIO_2</h1>" | sudo tee $ROOT_2/index.html
echo "Error en la aplicacion web appsistema - archivo no encontrado" | sudo tee $ROOT_2/404.html

# ==========================================
# 3. GENERACIÓN DEL CERTIFICADO (CN CORRECTO)
# ==========================================
# Se genera para el dominio principal de la tabla
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/apache.key \
  -out /etc/apache2/ssl/apache.crt \
  -subj "/C=ES/ST=Barcelona/L=Barcelona/O=KuyG8/OU=IT/CN=$DOMINIO_1/emailAddress=$EMAIL_1"

# ==========================================
# 4. CONFIGURACIÓN USUARIOS RESTRINGIDOS
# ==========================================
# Usuarios para Intranet (Usuari01, 02, 03)
sudo htpasswd -bc /etc/apache2/.htpasswd_intra Usuari01 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari02 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari03 1234

# Usuarios para Sistema (Usuari04, 05, 06)
sudo htpasswd -bc /etc/apache2/.htpasswd_sist Usuari04 1234
sudo htpasswd -b /etc/apache2/.htpasswd_sist Usuari05 1234
sudo htpasswd -b /etc/apache2/.htpasswd_sist Usuari06 1234

# ==========================================
# 5. VIRTUALHOSTS HTTPS
# ==========================================

# --- Aplicación 1 (Intranet) ---
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/appintranet-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_1
    ServerAlias $ALIAS_1
    ServerAdmin $EMAIL_1
    DocumentRoot $ROOT_1

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    ErrorDocument 404 /404.html
    ErrorLog $ROOT_1/logs/error.log
    CustomLog $ROOT_1/logs/access.log combined

    Alias /privado $PRIV_1
    <Directory $PRIV_1>
        AuthType Basic
        AuthName \"Acces Restringit Intranet\"
        AuthUserFile /etc/apache2/.htpasswd_intra
        Require valid-user
        Require ip 127.0.0.1 192.168.3.0/24
    </Directory>
</VirtualHost>
EOF"

# --- Aplicación 2 (Sistema con CGI) ---
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/appsistema-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_2
    ServerAlias $ALIAS_2
    ServerAdmin $EMAIL_2
    DocumentRoot $ROOT_2

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    ErrorDocument 404 /404.html
    ErrorLog $ROOT_2/logs/error.log

    <Directory $ROOT_2>
        Options +ExecCGI
        AddHandler cgi-script .sh
        AuthType Basic
        AuthName \"Acces Restringit Sistema\"
        AuthUserFile /etc/apache2/.htpasswd_sist
        Require valid-user
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 6. ACTIVACIÓN Y REINICIO
# ==========================================
sudo a2ensite appintranet-ssl.conf appsistema-ssl.conf
sudo systemctl restart apache2

echo "✅ HTTPS configurado según tabla Kuy G8"
