#!/bin/bash

# ==========================================
# 1. VARIABLES (Ajustadas a tu red 192.168.3.x)
# ==========================================
DOMINIO_1="www.intranet.kuy.com"
DOMINIO_2="www.sistema.kuy.org"
IP_RED="192.168.3.0/24"

ROOT_1="/var/www/appintranet"
ROOT_2="/var/www/appsistema"
PRIV_1="/srv/www/appintranet/privado"

# ==========================================
# 2. INSTALACIÓN Y DIRECTORIOS
# ==========================================
sudo apt update && sudo apt install apache2 apache2-utils -y
sudo a2enmod ssl cgi
sudo mkdir -p $ROOT_1/logs $ROOT_2/logs $PRIV_1 /etc/apache2/ssl

# Archivos base y Error 404 exacto de la tabla
echo "<h1>Benvinguts a Intranet</h1>" | sudo tee $ROOT_1/index.html
echo "Error en la aplicacion web appintranet - archivo no encontrado" | sudo tee $ROOT_1/404.html
echo "<h1>Zona Privada Confirmada</h1>" | sudo tee $PRIV_1/index.html

# ==========================================
# 3. CERTIFICADO SSL (Dominio correcto)
# ==========================================
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/apache.key \
  -out /etc/apache2/ssl/apache.crt \
  -subj "/C=ES/ST=Barcelona/L=Barcelona/O=KuyG8/CN=$DOMINIO_1"

# ==========================================
# 4. USUARIOS (htpasswd)
# ==========================================
# Crear usuarios de la tabla con password '1234'
sudo htpasswd -bc /etc/apache2/.htpasswd_intra Usuari01 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari02 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari03 1234

# ==========================================
# 5. CONFIGURACIÓN VIRTUALHOSTS (Con RequireAll)
# ==========================================

# --- Aplicación 1 (Intranet) ---
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/appintranet-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_1
    DocumentRoot $ROOT_1
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    ErrorDocument 404 /404.html
    ErrorLog $ROOT_1/logs/error.log

    Alias /privado $PRIV_1
    <Directory $PRIV_1>
        AuthType Basic
        AuthName \"Acces Restringit Intranet\"
        AuthUserFile /etc/apache2/.htpasswd_intra
        <RequireAll>
            Require valid-user
            Require ip $IP_RED
        </RequireAll>
    </Directory>
</VirtualHost>
EOF"

# --- Aplicación 2 (Sistema) ---
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/appsistema-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_2
    DocumentRoot $ROOT_2
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    <Directory $ROOT_2>
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 6. PERMISOS Y ACTIVACIÓN
# ==========================================
sudo chown -R www-data:www-data /var/www/ /srv/www/
sudo a2ensite appintranet-ssl.conf appsistema-ssl.conf
sudo systemctl restart apache2

echo "✅ Script corregido y ejecutado. Prueba ahora en el navegador."
