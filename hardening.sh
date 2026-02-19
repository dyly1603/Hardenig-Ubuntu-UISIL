# =================================================================
# FASE 2: Blindaje de Acceso (SSH)
# =================================================================

echo "--- Iniciando Fase 2: Configuración Segura de SSH ---"

SSH_CONF="/etc/ssh/sshd_config"
NUEVO_PUERTO=2234 

# Respaldar configuración
sudo cp $SSH_CONF "$SSH_CONF.bak"

# 1. Cambiar puerto 22 al 2234 (Evita ataques de bots comunes)
sudo sed -i "s/#Port 22/Port $NUEVO_PUERTO/" $SSH_CONF
sudo sed -i "s/Port 22/Port $NUEVO_PUERTO/" $SSH_CONF

# 2. Deshabilitar login de root (Requisito del profesor)
sudo sed -i "s/#PermitrootLogin prohibit-password/PermitRootLogin no/" $SSH_CONF
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" $SSH_CONF

# 3. Solo permitir llaves públicas, no contraseñas
sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" $SSH_CONF
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" $SSH_CONF
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" $SSH_CONF

# Reiniciar para aplicar
sudo systemctl restart ssh

echo "Fase 2 completada. SSH ahora corre en el puerto $NUEVO_PUERTO y el acceso root está bloqueado."

# =================================================================
# FASE 3: Perímetro y Red (Firewall y Protección)
# =================================================================

echo "--- Iniciando Fase 3: Configuración de UFW y Fail2Ban ---"

# 1. Configurar UFW (Uncomplicated Firewall)
echo "Configurando el Firewall..."
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

# ¡OJO! Permitimos el puerto que configuramos en la Fase 2
# Si usaste el 2234, ponemos ese.
sudo ufw allow 2234/tcp
sudo ufw --force enable

# 2. Instalar y configurar Fail2Ban
echo "Instalando Fail2Ban para prevenir fuerza bruta..."
sudo apt install -y fail2ban

# Crear configuración local para SSH
sudo bash -c 'cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 2234
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF'

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

echo "Fase 3 completada: Firewall activo y Fail2Ban monitoreando el puerto 2234."

# =================================================================
# FASE 4: Gestión de Parches (Actualizaciones Automáticas)
# =================================================================

echo "--- Iniciando Fase 4: Configuración de Unattended-Upgrades ---"

sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Asegurar que las actualizaciones de seguridad estén activas
sudo bash -c 'cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF'

echo "Fase 4 completada: El servidor ahora se parchará solo ante riesgos de seguridad."
