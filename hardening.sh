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

# =================================================================
# FASE 5: Ajustes Finos y Seguridad del Kernel (Sysctl)
# =================================================================

echo "--- Iniciando Fase 5: Ajustes de Kernel y Permisos ---"

# 1. Fortalecimiento del Kernel (Previene ataques de red comunes)
cat <<EOF | sudo tee /etc/sysctl.d/99-hardening.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv6.conf.all.disable_ipv6 = 1
kernel.sysrq = 0
EOF

# Aplicar cambios del Kernel
sudo sysctl -p /etc/sysctl.d/99-hardening.conf

# 2. Restricción de permisos en archivos críticos
sudo chmod 600 /etc/crontab
sudo chmod 700 /etc/cron.d
sudo chmod 700 /etc/cron.daily
sudo chmod 700 /etc/cron.hourly

# 3. Instalación de Escáner de Malware (Requerido por Lynis)
# Esto quitará la [X] en Malware Scanner y subirá varios puntos
sudo apt install -y rkhunter chkrootkit
sudo rkhunter --propupd  # Actualizar base de datos

echo "Fase 5 completada: Kernel protegido y escáneres de seguridad instalados."

# =================================================================
# FASE 6: Ajustes de Cumplimiento y Banners (Meta +75)
# =================================================================

echo "--- Iniciando Fase 6: Banners Legales y Auditoría de Sistema ---"

# 1. Configurar Banners Legales (Corrige BANN-7126 y BANN-7130)
# Lynis otorga puntos por advertir a usuarios no autorizados
MENSAJE_LEGAL="ADVERTENCIA: El acceso a este sistema esta restringido a usuarios autorizados. Todas las actividades son monitoreadas."
echo "$MENSAJE_LEGAL" | sudo tee /etc/issue /etc/issue.net

# 2. Instalar Auditoría del Sistema (Corrige ACCT-9622 y ACCT-9628)
# Esto activa el monitoreo de procesos y eventos, sube muchos puntos
sudo apt install -y auditd audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd

# 3. Restringir Compiladores (Corrige HRDN-7222)
# Evita que un atacante compile exploits localmente
sudo chmod 700 /usr/bin/gcc /usr/bin/g++ 2>/dev/null

# 4. Ajustes de Contraseñas y Umask (Corrige AUTH-9328 y AUTH-9286)
sudo sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs

echo "Fase 6 completada: Banners configurados y auditoria activada."

# =================================================================
# FASE 7: Ajustes de Oro para llegar a +75
# =================================================================

echo "--- Iniciando Fase 7: Ajustes Finales de Auditoría ---"

# 1. Instalar debsums (Sugerencia PKGS-7370 de tu reporte)
# Esto verifica la integridad de los paquetes instalados
sudo apt install -y debsums apt-show-versions

# 2. Deshabilitar protocolos de red poco comunes (Sugerencia NETW-3200)
# Lynis resta puntos por protocolos que no se usan como dccp o sctp
cat <<EOF | sudo tee /etc/modprobe.d/dev-protocols.conf
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF

# 3. Fortalecer permisos del compilador (Más estricto para HRDN-7222)
sudo chmod 700 /usr/bin/as /usr/bin/ld 2>/dev/null

# 4. Ajustar el Banner de Postfix (Corrige el Warning MAIL-8818)
# Lynis odia que el servidor de correo diga qué versión de SO usa
sudo postconf -e 'smtpd_banner = $myhostname ESMTP'
sudo systemctl restart postfix

echo "Fase 7 completada. Realizando auditoría final..."

# =================================================================
# FASE 8: Fortalecimiento de Políticas de Autenticación
# =================================================================

echo "--- Iniciando Fase 8: Ajustes de Seguridad de Cuentas ---"

# 1. Configurar tiempo de espera de la sesión (TMOUT)
# Si un usuario deja la terminal abierta, se cierra sola tras 15 min. 
# Lynis valora mucho esto en la sección [Shells]
echo "readonly TMOUT=900" | sudo tee /etc/profile.d/timeout.sh
echo "readonly HISTSIZE=5000" | sudo tee -a /etc/profile.d/timeout.sh

# 2. Deshabilitar el almacenamiento de volcados de memoria (Core Dumps)
# Corrige la sugerencia [KRNL-5820]
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf

# 3. Reforzar el hashing de contraseñas (SHA512 con más rondas)
# Corrige la sugerencia [AUTH-9230]
sudo sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs
echo "SHA512_CRYPT_MIN_ROUNDS 5000" | sudo tee -a /etc/login.defs
echo "SHA512_CRYPT_MAX_ROUNDS 10000" | sudo tee -a /etc/login.defs

echo "Fase 8 completada. Auditoría definitiva en proceso..."
