# Переменные
MYSQL_ROOT_PASSWORD = !TESTPASS123
PHP_VERSION = 8.1
DISTRO = $(shell lsb_release -si)
DOMAIN = test.ru
EMAIL = test@gmail.com

# Основная цель
all: install_mysql install_php install_composer install_nginx install_certbot configure_ssl configure_nginx
# откат всех изменений
rollback: rollback_mysql rollback_php rollback_nginx rollback_ssl rollback_certbot rollback_nginx_config

# Установка MySQL
install_mysql:
	@echo "Installing MySQL..."
	@sudo apt update
	@sudo apt install -y mysql-server
	@echo "Setting MySQL root password..."
	@sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$(MYSQL_ROOT_PASSWORD)';"
	@sudo systemctl start mysql
	@sudo systemctl enable mysql
	@echo "MySQL installation completed."

rollback_mysql:
	@echo "Rolling back MySQL installation..."
	@sudo systemctl stop mysql
	@sudo apt remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
	@sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
	@echo "MySQL rollback completed."
# Установка PHP
install_php:
	@echo "Installing PHP $(PHP_VERSION)..."
	@sudo apt update
	@sudo apt install -y gnupg
	@echo "Adding PPA for PHP..."
	@sudo add-apt-repository ppa:ondrej/php -y
	@echo "Adding GPG key for PHP repository..."
	@wget -qO - https://packages.sury.org/php/apt.gpg | sudo tee /etc/apt/trusted.gpg.d/ondrej-ubuntu-php.gpg
	@sudo apt update
	@echo "Installing PHP packages..."
	@sudo apt install -y php$(PHP_VERSION) php$(PHP_VERSION)-cli php$(PHP_VERSION)-fpm php$(PHP_VERSION)-mysql php$(PHP_VERSION)-mbstring php$(PHP_VERSION)-xml php$(PHP_VERSION)-curl php$(PHP_VERSION)-zip php$(PHP_VERSION)-gd
	@echo "PHP $(PHP_VERSION) installation completed."

rollback_php:
	@echo "Rolling back PHP installation..."
	@sudo apt remove --purge -y php$(PHP_VERSION) php$(PHP_VERSION)-cli php$(PHP_VERSION)-fpm php$(PHP_VERSION)-mysql php$(PHP_VERSION)-mbstring php$(PHP_VERSION)-xml php$(PHP_VERSION)-curl php$(PHP_VERSION)-zip php$(PHP_VERSION)-gd
	@sudo apt autoremove -y
	@echo "PHP rollback completed."

# Установка Composer
install_composer:
	@echo "Installing Composer..."
	@curl -sS https://getcomposer.org/installer | php
	@sudo mv composer.phar /usr/local/bin/composer
	@echo "Composer installation completed."

# Установка Nginx
install_nginx:
	@echo "Installing Nginx..."
	@sudo apt update
	@sudo apt install -y nginx
	@if [ ! -f /etc/nginx/nginx.conf ]; then \
        echo "nginx.conf not found, restoring default configuration..."; \
        sudo cp /etc/nginx/nginx.conf.default /etc/nginx/nginx.conf; \
    fi
	@sudo systemctl start nginx
	@sudo systemctl enable nginx
	@echo "Nginx installation completed."

rollback_nginx:
	@echo "Rolling back Nginx installation..."
	@sudo systemctl stop nginx
	@sudo rm -rf /etc/nginx
	@sudo apt-get purge nginx nginx-common nginx-core
	@sudo apt remove --purge -y nginx
	@echo "Nginx rollback completed."

# Установка Certbot
install_certbot:
	@echo "Installing Certbot..."
	@sudo apt update
	@sudo apt install -y certbot python3-certbot-nginx
	@echo "Certbot installation completed."

rollback_certbot:
	@echo "Rolling back Certbot installation..."
	@sudo apt remove --purge -y certbot python3-certbot-nginx
	@echo "Certbot rollback completed."

# Настройка SSL с Certbot и настройка автоматического продления
configure_ssl:
	@echo "Configuring SSL with Certbot..."
	@sudo certbot --nginx -d $(DOMAIN) --non-interactive --agree-tos --email $(EMAIL)
	@echo "SSL certificate installation completed."

rollback_ssl:
	@echo "Rolling back SSL configuration..."
	@sudo certbot delete --cert-name $(DOMAIN)
	@echo "SSL rollback completed."
# Конфигурация Nginx для PHP
configure_nginx:
	@echo "Configuring Nginx for PHP..."
	@sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
	@sudo cp nginx.conf /etc/nginx/sites-available/default
	@sudo systemctl restart nginx
	@echo "Nginx configuration for PHP completed."

rollback_nginx_config:
	@echo "Rolling back Nginx configuration..."
	@sudo cp /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
	@sudo systemctl restart nginx
	@echo "Nginx configuration rollback completed."

# Настройка автопродления сертификата
configure_renewal:
	@echo "Configuring automatic certificate renewal..."
	@echo "0 0,12 * * * root certbot renew --quiet && systemctl reload nginx" | sudo tee /etc/cron.d/certbot-renew
	@sudo systemctl reload cron
	@echo "Automatic certificate renewal configured."

# Очистка
clean:
	@echo "Cleaning up..."
	@sudo apt autoremove -y
	@sudo apt clean
	@echo "Cleanup completed."
