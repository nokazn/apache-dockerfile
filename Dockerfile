FROM php:7.3.10-apache

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    curl sendmail zip unzip libz-dev libpq-dev libzip-dev \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libssl-dev libmcrypt-dev \
  && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) pdo_mysql \
  && docker-php-ext-install -j$(nproc) pdo_pgsql \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install -j$(nproc) zip \
  && pecl install redis \
  && docker-php-ext-enable redis

ENV APACHE_DOCUMENT_ROOT /var/www/public

COPY ./ssl /etc/apache2/ssl

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
  && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
  && sed -ri -e 's!/etc/ssl/certs/ssl-cert-snakeoil.pem!/etc/apache2/ssl/localhost+3.pem!g' /etc/apache2/sites-available/default-ssl.conf \
  && sed -ri -e 's!/etc/ssl/private/ssl-cert-snakeoil.key!/etc/apache2/ssl/localhost+3-key.pem!g' /etc/apache2/sites-available/default-ssl.conf \
  && a2enmod rewrite \
  && a2enmod headers \
  && a2enmod ssl \
  && a2ensite default-ssl

RUN echo '#!/bin/sh\nphp artisan "$@"' >> /bin/pa \
  && chmod u+x /bin/pa

WORKDIR /var/www
