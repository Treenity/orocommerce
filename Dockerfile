FROM php:7.2-apache

MAINTAINER Ronan Pozzi <contact@treenity-web.fr>

ARG DEBIAN_FRONTEND=noninteractive

ENV NOTVISIBLE="in users profile" \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_SERVERADMIN=contact@treenity-web.fr \
    APACHE_SERVERNAME=localhost \
    APACHE_DOCUMENTROOT=/var/www/html/public \
    COMPOSER_ALLOW_SUPERUSER=1 \
    TZ=Europe/Paris \
    COMPOSER_MEMORY_LIMIT=-1

# Config files
COPY conf.d $PHP_INI_DIR/conf.d/
COPY supervisor /etc/supervisor/conf.d/
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Install deps
RUN echo 'deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main' >> /etc/apt/sources.list \
    && apt-get update -qq \
    && apt-get install -yq gnupg apt-transport-https \
    && apt-get update -qq \
    && apt-get install -yqq \
        libfreetype6-dev \
        libpng-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libicu-dev \
        libxml2-dev \
        libsasl2-modules \
        libtidy-dev \
        libcurl4-gnutls-dev \
        libpq-dev \
        libmagickwand-dev libmagickcore-dev \
        libc-client-dev libkrb5-dev \
        mariadb-client \
        apt-utils \
        build-essential patch \
        vim \
        unzip \
        git \
        curl \
        openssh-client \
        cron \
        supervisor \
        rsync

# Install nodejs 12
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get install -yqq \
        nodejs \
        npm \
        yarn

# Active apache mods
RUN a2enmod rewrite \
        deflate \
        headers \
        expires \
        ssl \
        actions

# Install php libraries
RUN pecl install -o -f xdebux redis imagick \
    && docker-php-source extract \
    && docker-php-ext-enable redis imagick \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install -j$(nproc) opcache zip tidy json bcmath ctype curl mysqli exif soap mbstring intl iconv pdo pdo_pgsql pdo_mysql sockets xml xmlrpc \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) gd imap \
    && docker-php-source delete \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    # Clean tmp directories
    && docker-php-source delete \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/pear/* \
    && sed -i 's/ServerTokens .*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf \
    && sed -i 's/ServerSignature .*/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Add composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

# Install custom apache conf
COPY etc/apache2/sites-available/ /etc/apache2/sites-available/

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord"]
