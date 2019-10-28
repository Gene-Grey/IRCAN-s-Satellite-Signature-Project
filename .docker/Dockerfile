FROM php:7.1.8-apache

COPY . /srv/app

RUN chown -R www-data:www-data /srv/app \
&& a2enmod rewrite
