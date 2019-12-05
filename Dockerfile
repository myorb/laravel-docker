FROM php:7.3-fpm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    nginx \
    supervisor \
    libzip-dev -y

RUN apt-get install nodejs -y
RUN apt-get install npm -y
RUN pecl install -o -f redis

RUN docker-php-ext-configure zip --with-libzip && \
    docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-enable redis

RUN docker-php-ext-install pdo pgsql pdo_pgsql  mbstring tokenizer xml pcntl bcmath zip opcache

RUN curl -s -f -L -o /tmp/installer.php https://getcomposer.org/installer && \
    php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog && \
    rm -rf /tmp/pear

WORKDIR /var/www

COPY . .

RUN npm install
RUN npm run prod

RUN chmod a+rw -R storage

ENV AWS_ENV_PATH=/api/delivery-service/
ENV AWS_REGION=eu-central-1

COPY deploy/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY deploy/nginx.conf /etc/nginx/nginx.conf

RUN composer install --no-scripts

EXPOSE 8080

ENTRYPOINT [ "bash", "./run.sh" ]
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
