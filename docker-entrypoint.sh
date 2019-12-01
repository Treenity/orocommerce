#!/bin/bash
set -euo pipefail

# If OroCommerce is installed but need dump
if [[ -f "/var/www/html/dev.json" && ! -f "/var/www/html/public/media/js/frontend_routes.json" ]];then
    echo ">>> Running console dumps"
    php /var/www/html/bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build && php bin/console --env=prod assetic:dump
    echo ">>> OroCommerce should be running now"
fi

if [[ ! -f "/var/www/html/dev.json" ]];then
    echo ">>> Installing OroCommerce from https://github.com/oroinc/orocommerce-application.git"
    git clone https://github.com/oroinc/orocommerce-application.git /var/www/html
    cd /var/www/html && composer install
    
    if [[ -d "/var/www/html/var/cache" ]];then
        echo ">>> cleaning /var/www/html/var/cache"
        rm -rf /var/www/html/var/cache
    fi

    echo ">>> Running oro:install with admin user : johndoe@example.com/admin1234"
    php /var/www/html/bin/console --env=prod oro:install --no-interaction --timeout 3600 --drop-database --user-name=admin --user-firstname=John --user-lastname=Doe --user-password=admin1234 --user-email=johndoe@example.com --organization-name=Acme --application-url=http://localhost/
    echo ">>> Running console dumps"
    php /var/www/html/bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build && php bin/console --env=prod assetic:dump
    echo ">>> OroCommerce installed"
    echo ">>> OroCommerce should be running now"
fi

# End this
if [[ -z "$@" ]]; then
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf --nodaemon
else
    exec "$@"
fi
