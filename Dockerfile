FROM php:7.2-apache

MAINTAINER Ronan Pozzi <contact@treenity-web.fr>

ARG DEBIAN_FRONTEND=noninteractive

ENV ORO_VERSION="4.0.0" \
    NOTVISIBLE="in users profile" \
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
COPY ./etc/php/conf.d $PHP_INI_DIR/conf.d/
COPY ./etc/supervisor/conf.d /etc/supervisor/conf.d/
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Install deps
RUN apt-get update -qq && apt-get install -yqq software-properties-common gnupg apt-transport-https && \
    add-apt-repository main && \
    apt-get update -qq && \
    apt-get install -yqq \
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
        rsync \
        python-certbot-apache

# Install nodejs 12
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -yqq \
        gcc g++ make \
        nodejs \
        yarn

# Add composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/ && \
    ln -s /usr/local/bin/composer.phar /usr/local/bin/composer && \
    composer global require hirak/prestissimo

# Install php libraries
RUN pecl install -o -f xdebug redis imagick && \
    docker-php-source extract && \
    docker-php-ext-enable redis imagick && \
    docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure intl && \
    docker-php-ext-install -j$(nproc) \
        intl \
        gd \
        imap \
        opcache \
        zip \
        tidy \
        json \
        bcmath \
        ctype \
        curl \
        mysqli \
        exif \
        soap \
        mbstring \
        iconv \
        pdo \
        pdo_pgsql \
        pdo_mysql \
        sockets \
        xml \
        xmlrpc && \
    docker-php-source delete && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Clean tmp directories
    docker-php-source delete && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/pear/* && \
    # Set server tokens for prod mod
    sed -i 's/ServerTokens .*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf && \
    sed -i 's/ServerSignature .*/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Install custom apache conf & ssl
COPY ./etc/apache2/sites-available /etc/apache2/sites-available/

# Active apache mods
RUN a2enmod rewrite \
        deflate \
        headers \
        expires \
        ssl \
        http2 \
        actions && \
        a2ensite default-ssl

COPY ./etc/apache2/ssl /etc/apache2/ssl/

# Install OroCommerce
COPY orocommerce/config/parameters.yml /tmp/oro-parameters.yml

RUN git clone -b ${ORO_VERSION} https://github.com/oroinc/orocommerce-application.git /tmp/orocommerce && \
    mv /tmp/oro-parameters.yml /tmp/orocommerce/config/parameters.yml && \
    composer install --no-interaction --no-suggest --no-dev --prefer-dist --working-dir /tmp/orocommerce && \
    rm -rf /tmp/orocommerce/.git && \
    chown www-data:www-data /tmp/orocommerce -R

EXPOSE 80 443 8080

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord"]
