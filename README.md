# Installation
## Informations
* **volumes** : `/var/www/html`
* **url**: _http(s)://localhost_
* **admin url**: _http(s)://localhost/admin_
* **user** : _johndoe@example.com_
* **pass**: _admin1234_

## SSL/HTTPS
Dans chrome : `chrome://flags/#allow-insecure-localhost` et activez l'accès aux sites "non verifiés"

## Lancement 
Lancer l'architecture via le fichier [docker-compose.yml](https://raw.githubusercontent.com/Treenity/orocommerce/master/docker-compose.yml) :  
```bash
docker-compose up -d
```

**Lors du premier lancement, une copie de OroCommerce sera déplacée dans /var/www/html si le fichier composer.lock n'existe pas**

## Premier lancement
**Lancez le bash dans le container :**  
```bash
docker exec -it oro_webserver bash
```

**Installez les dépendances composer (seulement si vous avez besoin des dépendances dev) :**  
```bash
composer install --optimize-autoloader
```

**Installation OroCommerce :**  
Ajoutez `--sample-data` si vous souhaitez des données de démonstration  

```bash
php bin/console --env=prod oro:install --no-interaction --timeout 3600 --drop-database --user-name=admin --user-firstname=John --user-lastname=Doe --user-password=admin1234 --user-email=johndoe@example.com --organization-name=Acme --application-url=http://localhost/
```

**Installation & dump des assets :**  

```bash
php bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build
```

**Relancer les services du serveur et sortir du shell**
```bash
supervisorctl restart all && exit
```
_PS: cela vous sortira du shell du container_

à ce stade, vous devriez pouvoir accèder au site.
## Fichiers
### [docker-compose.yml](https://raw.githubusercontent.com/Treenity/orocommerce/master/docker-compose.yml)
```yaml
version: "2"
services:
  webserver:
    container_name: oro_webserver
    image: treenity/orocommerce:latest
    depends_on:
      - mysql
    links:
      - mysql
      - mailhog
    ports:
      - "80:80"
      - "443:443"
      - "8088:8080"
    volumes:
      - "./:/var/www/html"
    environment:
      ENABLE_XDEBUG: 0
      XDEBUG_CONFIG: "remote_host=host.docker.internal remote_enable=1"
      PHP_IDE_CONFIG: "serverName=localhost"

  mysql:
    container_name: oro_mysql
    image: mysql:5.5
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: orocommerce
      MYSQL_USER: orocommerce
      MYSQL_PASSWORD: orocommerce
    volumes:
      - "mysql:/var/lib/mysql"

  mailhog:
    container_name: oro_mailhog
    image: mailhog/mailhog
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  mysql:
    driver: local
```
### [config/parameters.yml](https://raw.githubusercontent.com/Treenity/orocommerce/master/orocommerce/config/parameters.yml)
```yaml
# This file is auto-generated during the composer install
parameters:
    database_driver: pdo_mysql
    database_host: mysql
    database_port: 3306
    database_name: orocommerce
    database_user: orocommerce
    database_password: orocommerce
    database_driver_options: {  }
    mailer_transport: smtp
    mailer_host: mailhog
    mailer_port: 1025
    mailer_encryption: null
    mailer_user: null
    mailer_password: null
    websocket_bind_address: 0.0.0.0
    websocket_bind_port: 8080
    websocket_frontend_host: '*'
    websocket_frontend_port: 8088
    websocket_frontend_path: ''
    websocket_backend_host: '*'
    websocket_backend_port: 8080
    websocket_backend_path: ''
    websocket_backend_transport: tcp
    websocket_backend_ssl_context_options: {  }
    web_backend_prefix: /admin
    session_handler: session.handler.native_file
    secret: ThisTokenIsNotSoSecretChangeIt
    installed: null
    assets_version: dc6bd359
    assets_version_strategy: time_hash
    message_queue_transport: dbal
    message_queue_transport_config: null
    enable_price_sharding: false
```
