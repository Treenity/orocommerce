# Installation
Lancer l'architecture :
```docker-compose up -d```

**Lors du premier lancement, l'image va télécharger Orocommerce et lancer le processus d'installation, cela peut prendre quelques minutes...**

## Docker-compose
```yaml
version: "2"
services:
  webserver:
    container_name: oro_webserver
    image: treenity/orocommerce
    depends_on:
      - mysql
    links:
      - mysql
      - mailhog
      - rabbitmq
    ports:
      - "80:80"
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

  rabbitmq:
    container_name: oro_rabbitmq
    image: rabbitmq:3-management
    ports:
      - 5672:5672
      - 15672:15672
    environment:
      RABBITMQ_DEFAULT_USER: root
      RABBITMQ_DEFAULT_PASS: root

volumes:
  mysql:
    driver: local
```

## Commandes utiles
Lancer l'installation de OroCommerce
```docker exec -i orocommerce_php php bin/console --env=prod oro:install --no-interaction --timeout 3600 --drop-database --user-name=admin --user-firstname=John --user-lastname=Doe --user-password=admin1234 --user-email=johndoe@example.com --organization-name=Acme --application-url=http://localhost/```

puis :
```docker exec -i orocommerce_php php bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build && php bin/console --env=prod assetic:dump```


