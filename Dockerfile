# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: lverdoes <lverdoes@student.codam.nl>         +#+                      #
#                                                    +#+                       #
#    Created: 2020/08/07 18:31:56 by lverdoes      #+#    #+#                  #
#    Updated: 2020/10/05 13:31:57 by lverdoes      ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

# update debian
RUN apt-get update
RUN apt-get upgrade -y

# install nginx
RUN apt-get install nginx -y

# install MYSQL
RUN apt-get install mariadb-server mariadb-client -y

# install PHP
RUN apt-get install php7.3 php7.3-fpm php7.3-mysql php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline php-mbstring php7.3-curl php7.3-dom php7.3-imagick php7.3-zip php7.3-gd -y

# install wget
RUN apt-get install wget -y

#install sudo
RUN apt-get install sudo -y

# install emacs
RUN apt-get install emacs -y

# Install sendmail
RUN apt-get install sendmail -y

# SSL certificate
RUN wget -O mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64
RUN chmod +x mkcert && mv mkcert /tmp/ && tmp/mkcert -install && \
	tmp/mkcert localhost && mv localhost.pem /root/ && mv localhost-key.pem /root/

# Install phpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-all-languages.tar.gz
RUN tar -zxvf phpMyAdmin-4.9.5-all-languages.tar.gz
RUN mv phpMyAdmin-4.9.5-all-languages /var/www/html/phpMyAdmin

#MYSQL - Creating a user called 'admin' for wordpress_db.
RUN service mysql start && \
	mysql -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'password';" && \
	mysql -e "CREATE DATABASE wordpress_db;" && \
	mysql -e "CREATE DATABASE phpmyadmin;" && \
	mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'admin'@'localhost';" && \
	mysql -e "FLUSH PRIVILEGES;" && \
	mysql phpmyadmin </var/www/html/phpMyAdmin/sql/create_tables.sql

# Install Wordpress
RUN wget https://wordpress.org/latest.tar.gz -P /tmp
RUN tar xzf /tmp/latest.tar.gz --strip-components=1 -C /var/www/html/

# Config Wordpress
COPY /srcs/wordpress/wp-config.php /var/www/html/
RUN adduser --disabled-password -gecos "" admin && \
	sudo adduser admin sudo
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN chown -R admin /var/www

RUN service mysql start && \
	sudo -u admin -i wp core install --url=localhost \
	--path=/var/www/html/ --title="lverdoes" --admin_name=admin \
	--admin_password=password --admin_email=lverdoes@student.codam.nl
RUN chown -R www-data:www-data /var/www
RUN rm -r /var/www/html/index.nginx-debian.html

# copy directories
COPY /srcs/nginx/nginx.conf /tmp/
COPY /srcs/phpMyAdmin/config.inc.php /tmp/
COPY /srcs/phpMyAdmin/phpMyAdmin.conf /tmp/
COPY /srcs/phpMyAdmin/php.ini /tmp/

# config files
RUN mv /tmp/nginx.conf /etc/nginx/sites-available/default
RUN mv /tmp/config.inc.php /var/www/html/phpMyAdmin/
RUN mv /tmp/phpMyAdmin.conf /etc/nginx/conf.d/
RUN mv /tmp/php.ini /etc/php/7.3/fpm/

# create tmp folder in phpMyAdmin
RUN mkdir /var/www/html/phpMyAdmin/tmp
RUN chmod 755 /var/www/html/phpMyAdmin/tmp
RUN chown -R www-data:www-data /var/www/html/phpMyAdmin

# Expose ports (80 for HTTP, 443 for SSL cert, 25 for sendmail)
EXPOSE 80
EXPOSE 443
EXPOSE 25 

CMD service php7.3-fpm start && \
	service nginx start && \
	service mysql start && \
	echo "$(hostname -i) $(hostname) $(hostname).localhost" >> /etc/hosts && \
	service sendmail start && \
	tail -f /dev/null
