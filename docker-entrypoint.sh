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
    git clone https://github.com/oroinc/orocommerce-application.git /var/www/html/app
    cd /var/www/html/app/ && git checkout tags/${ORO_VERSION} && cd ..
    mv /var/www/html/app/* /var/www/html/

    if [[ -d "/var/www/html/var/cache" ]];then
        echo ">>> cleaning /var/www/html/var/cache"
        rm -rf /var/www/html/var/cache
    fi

    echo "**********************************"
    echo "run :"
    echo "docker exec -it oro_webserver bash"
    echo "then :"
    echo "composer install"
    echo "You should be asked for parameters.yml settup"
    echo "php /var/www/html/bin/console --env=prod oro:install --no-interaction --timeout 3600 --drop-database --user-name=admin --user-firstname=John --user-lastname=Doe --user-password=admin1234 --user-email=johndoe@example.com --organization-name=Acme --application-url=http://localhost/"
    echo "php /var/www/html/bin/console --env=prod fos:js-routing:dump && php bin/console --env=prod oro:localization:dump && php bin/console --env=prod oro:assets:install && php bin/console --env=prod oro:translation:dump && php bin/console --env=prod oro:requirejs:build && php bin/console --env=prod assetic:dump"
    echo "**********************************"
fi

# Enable xdebug
XdebugFile='/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'
if [[ "$ENABLE_XDEBUG" == "1" ]] ; then
  if [[ -f ${XdebugFile} ]]; then
  	echo "Xdebug enabled"
  else
  	echo "Enabling xdebug"
  	echo "If you get this error, you can safely ignore it: /usr/local/bin/docker-php-ext-enable: line 83: nm: not found"
  	# see https://github.com/docker-library/php/pull/420
    docker-php-ext-enable xdebug
    # see if file exists
    if [[ -f ${XdebugFile} ]]; then
        # See if file contains xdebug text.
        if grep -q xdebug.remote_enable "$XdebugFile"; then
            echo "Xdebug already enabled... skipping"
        else
            echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > ${XdebugFile} # Note, single arrow to overwrite file.
            echo "xdebug.remote_enable=1 "  >> ${XdebugFile}
            echo "xdebug.remote_log=/tmp/xdebug.log"  >> ${XdebugFile}
            echo "xdebug.remote_autostart=false "  >> ${XdebugFile} # I use the xdebug chrome extension instead of using autostart
            # NOTE: xdebug.remote_host is not needed here if you set an environment variable in docker-compose like so `- XDEBUG_CONFIG=remote_host=192.168.111.27`.
            #       you also need to set an env var `- PHP_IDE_CONFIG=serverName=docker`
        fi
    fi
  fi
else
    if [[ -f ${XdebugFile} ]]; then
        echo "Disabling Xdebug"
      rm ${XdebugFile}
    fi
fi


# End this
if [[ -z "$@" ]]; then
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf --nodaemon
else
    exec "$@"
fi
