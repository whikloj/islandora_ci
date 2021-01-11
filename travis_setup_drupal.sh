#!/bin/bash
echo "Setup database for Drupal"
mysql -h 127.0.0.1 -u root -e "GRANT ALL PRIVILEGES ON drupal.* To 'drupal'@'%' IDENTIFIED BY 'drupal';"
mysql -h 127.0.0.1 -u drupal -pdrupal -e "SHOW DATABASES;"
if [ $# -ne 0 ]; then
  exit 1
fi

echo "Install utilities needed for testing"
mkdir /opt/utils
cd /opt/utils
if [ -z "$COMPOSER_PATH" ]; then
  composer require drupal/coder ^8.3.11
  composer require sebastian/phpcpd ^6
else
  php -dmemory_limit=-1 $COMPOSER_PATH require drupal/coder ^8.3.11
  php -dmemory_limit=-1 $COMPOSER_PATH require sebastian/phpcpd ^6
fi
sudo ln -s /opt/utils/vendor/bin/phpcs /usr/bin/phpcs
sudo ln -s /opt/utils/vendor/bin/phpcpd /usr/bin/phpcpd
phpenv rehash
phpcs --config-set installed_paths /opt/utils/vendor/drupal/coder/coder_sniffer

echo "Composer install drupal site"
if [ -z "$DRUPAL_VERSION" ]; then
    DRUPAL_VERSION=8.9.11
fi
cd /opt
composer create-project drupal/recommended-project:$DRUPAL_VERSION drupal
cd drupal
if [ -z "$COMPOSER_PATH" ]; then
  composer install
else
  php -dmemory_limit=-1 $COMPOSER_PATH install
fi

composer require "drupal/core-dev:$DRUPAL_VERSION"
DRUPAL_MAJOR=$(echo "$DRUPAL_VERSION" | cut -d. -f1)
if [ $DRUPAL_MAJOR -ge 9 ]; then
   composer require phpspec/prophecy-phpunit:^2
fi
composer require drush/drush
echo "Setup Drush"
sudo ln -s /opt/drupal/vendor/bin/drush /usr/bin/drush
phpenv rehash

echo "Drush setup drupal site"
cd web
drush si --db-url=mysql://drupal:drupal@127.0.0.1/drupal --yes
drush runserver 127.0.0.1:8282 &
until curl -s 127.0.0.1:8282; do true; done > /dev/null
echo "Enable simpletest module"
drush --uri=127.0.0.1:8282 en -y simpletest

# Install pdfjs
cd /opt/drupal
if [ -z "$COMPOSER_PATH" ]; then
  composer require "zaporylie/composer-drupal-optimizations:^1.0" "drupal/pdf:1.x-dev"
else
  php -dmemory_limit=-1 $COMPOSER_PATH require "zaporylie/composer-drupal-optimizations:^1.0" "drupal/pdf:1.x-dev"
fi

cd web
mkdir libraries
cd libraries
wget "https://github.com/mozilla/pdf.js/releases/download/v2.0.943/pdfjs-2.0.943-dist.zip"
mkdir pdf.js
unzip pdfjs-2.0.943-dist.zip -d pdf.js
rm pdfjs-2.0.943-dist.zip

cd ..
drush -y en pdf

#echo "Setup ActiveMQ"
#cd /opt
#wget "http://archive.apache.org/dist/activemq/5.14.3/apache-activemq-5.14.3-bin.tar.gz"
#tar -xzf apache-activemq-5.14.3-bin.tar.gz
#apache-activemq-5.14.3/bin/activemq start
