#!/bin/bash

# ==========================================================
# VARIABLES - AJUSTA ESTOS VALORES SEGÚN TU PASSA 1
# ==========================================================
DOMINIO="intranet.primernomdedomini.com"
EMAIL="admin@$DOMINIO"
PAIS="ES"
PROVINCIA="Barcelona"
LOCALIDAD="Barcelona"
ORGANIZACION="MiEmpresa"

# ==========================================================
# 1. ACTUALIZACIÓN E INSTALACIÓN DE APACHE
# ==========================================================
sudo apt update && sudo apt install apache2 -y

# ==========================================================
# 2. GENERACIÓN DEL CERTIFICADO AUTOFIRMADO (Passa 1 y 2)
# ==========================================================
# Creamos el directorio para los certificados
sudo mkdir -p /etc/apache2/ssl

# Generamos la clave privada y el certificado en un solo paso
# -days 365: Validez de un año
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/apache.key \
  -out /etc/apache2/ssl/apache.crt \
  -subj "/C=$PAIS/ST=$PROVINCIA/L=$LOCALIDAD/O=$ORGANIZACION/OU=IT/CN=$DOMINIO/emailAddress=$EMAIL"

# ==========================================================
# 3. CONFIGURACIÓN DEL VIRTUALHOST HTTPS (Passa 2)
# ==========================================================
CONFIG_FILE="/etc/apache2/sites-available/intranet-ssl.conf"

sudo bash -c "cat <<EOF > $CONFIG_FILE
<VirtualHost *:443>
    ServerAdmin $EMAIL
    ServerName $DOMINIO
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"

# ==========================================================
# 4. ACTIVAR MÓDULOS Y SITIO
# ==========================================================
sudo a2enmod ssl
sudo a2ensite intranet-ssl.conf

# Reiniciar Apache para aplicar cambios
sudo systemctl restart apache2

# ==========================================================
# 5. MENSAJE FINAL (Para tu Wiki)
# ==========================================================
echo "-------------------------------------------------------"
echo "✅ Configuración HTTPS completada para: $DOMINIO"
echo "📂 Certificado: /etc/apache2/ssl/apache.crt"
echo "📂 Clave privada: /etc/apache2/ssl/apache.key"
echo "🌐 Prueba el acceso en: https://$DOMINIO"
echo "-------------------------------------------------------"