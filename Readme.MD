# Installation
Lancer l'architecture :
```docker-compose up -d```

**Lors du premier lancement, l'image va télécharger Orocommerce et lancer le processus d'installation, cela peut prendre quelques minutes...**


## Commandes utiles
Lancer l'installation de OroCommerce
```docker exec -i orocommerce_php php bin/console --env=prod oro:install --no-interaction --timeout 3600 --drop-database --user-name=admin --user-firstname=John --user-lastname=Doe --user-password=admin1234 --user-email=johndoe@example.com --organization-name=Acme --application-url=http://localhost/```

puis :
```docker exec -i orocommerce_php php bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build && php bin/console --env=prod assetic:dump```


