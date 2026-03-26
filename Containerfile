# SPDX-FileCopyrightText: © 2026 Nfrastack <code@nfrastack.com>
#
# SPDX-License-Identifier: MIT

ARG \
    BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL \
        org.opencontainers.image.title="Invoice Ninja" \
        org.opencontainers.image.description="Containerized Invoicing and Billing platform" \
        org.opencontainers.image.url="https://hub.docker.com/r/nfrastack/invoiceninja" \
        org.opencontainers.image.documentation="https://github.com/nfrastack/container-invoiceninja/blob/main/README.md" \
        org.opencontainers.image.source="https://github.com/nfrastack/container-invoiceninja.git" \
        org.opencontainers.image.authors="Nfrastack <code@nfrastack.com>" \
        org.opencontainers.image.vendor="Nfrastack <https://www.nfrastack.com>" \
        org.opencontainers.image.licenses="MIT"

ARG \
    INVOICENINJA_VERSION="v5.13.7" \
    INVOICENINJA_REACT_VERSION="09.03.2026.1" \
    INVOICENINJA_REPO_URL=https://github.com/invoiceninja/invoiceninja \
    INVOICENINJA_REACT_REPO_URL=https://github.com/invoiceninja/ui

ENV \
    SNAPPDF_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    IMAGE_NAME="nfrastack/invoiceninja" \
    IMAGE_REPO_URL="https://github.com/nfrastack/container-invoiceninja/"

COPY CHANGELOG.md /usr/src/container/CHANGELOG.md
COPY LICENSE /usr/src/container/LICENSE
COPY README.md /usr/src/container/README.md

RUN echo "" && \
    BUILD_ENV=" \
                10-nginx/NGINX_WEBROOT=/www/html \
                10-nginx/NGINX_SITE_ENABLED=invoiceninja \
                20-php-fpm/PHP_CREATE_SAMPLE_PHP=FALSE \
                20-php-fpm/PHP_MODULE_ENABLE_BCMATH=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_CURL=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_CTYPE=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_EXIF=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_FILEINFO=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_GD=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_GMP=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_ICONV=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_IGBINARY=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_IMAGICK=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_IMAP=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_INTL=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_MBSTRING=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_OPENSSL=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_SODIUM=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_XML=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_TOKENIZER=TRUE \
                20-php-fpm/PHP_MODULE_ENABLE_ZIP=TRUE \
                20-php-fpm/PHP_MEMORY_LIMIT=512M \
                " \
                && \
    \
    INVOICENINJA_BUILD_DEPS_ALPINE=" \
                                        git \
                                        nodejs \
                                        npm \
                                   " \
                                   && \
    \
    INVOICENINJA_RUN_DEPS_ALPINE=" \
                                    chromium \
                                    font-isas-misc \
                                    gnu-libiconv \
                                    sed \
                                    ttf-freefont \
                                 " \
                                 && \
    \
    source /container/base/functions/container/build && \
    container_build_log image && \
    package update && \
    package upgrade && \
    package install \
                    INVOICENINJA_BUILD_DEPS \
                    INVOICENINJA_RUN_DEPS \
    php-ext prepare && \
    php-ext reset && \
    php-ext enable core && \
    clone_git_repo "${INVOICENINJA_REPO_URL}" "${INVOICENINJA_VERSION}" /container/data/invoiceninja/install && \
    \
    npm install && \
    composer install --no-dev && \
    npm run production && \
    \
    clone_git_repo "${INVOICENINJA_REACT_REPO_URL}" "${INVOICENINJA_REACT_VERSION}" /usr/src/invoiceninja-react && \
    cd /usr/src/invoiceninja-react && \
    npm install && \
    npm run build && \
    cp -r dist/* /container/data/invoiceninja/install/public/ && \
    mv /container/data/invoiceninja/install/public/index.html /container/data/invoiceninja/install/resources/views/react/index.blade.php && \
    \
    chown -R "${NGINX_USER}":"${NGINX_GROUP}" /container/data/invoiceninja/install && \
    rm -rf \
            /container/data/invoiceninja/install/.env.example \
            /container/data/invoiceninja/install/.env.travis \
            /container/data/invoiceninja/install/.git \
            /container/data/invoiceninja/install/docs \
            /container/data/invoiceninja/install/tests \
            && \
    package remove \
                    INVOICENINJA_BUILD_DEPS \
                    && \
    package cleanup

COPY rootfs /
