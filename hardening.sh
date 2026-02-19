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
