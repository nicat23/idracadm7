# syntax=docker/dockerfile:1
FROM nicat23/racadm:latest

USER root

ARG ACME_VERSION=3.1.0
ARG AUTO_UPGRADE=0

ENV PAGER=cat \
    LE_WORKING_DIR=/acmebin \
    LE_CONFIG_HOME=/acme.sh \
    LE_CERT_HOME=/certs \
    HOME=/acme.sh \
    AUTO_UPGRADE=${AUTO_UPGRADE}

RUN set -eux; \
    apk add --no-cache \
        bind-tools \
        curl \
        jq \
        openssh-client \
        openssl \
        #socat \ 
        # Socat is used for standalone mode which is not supported in this image.
        supercronic \
        tzdata \
        yq; \
    addgroup -g 1000 acme; \
    adduser -h "${LE_CONFIG_HOME}" -s /bin/sh -G acme -D -H -u 1000 acme; \
    mkdir -p \
        "${LE_WORKING_DIR}" \
        "${LE_CONFIG_HOME}" \
        "${LE_CERT_HOME}" \
        /hooks \
        /init \
        /usr/local/bin \
        /tmp/install_acme; \
    curl -fsSL "https://github.com/acmesh-official/acme.sh/archive/refs/tags/${ACME_VERSION}.tar.gz" \
        | tar -xz -C /tmp/install_acme; \
    cd "/tmp/install_acme/acme.sh-${ACME_VERSION}"; \
    ./acme.sh --install \
        --nocron \
        --no-profile \
        --home "${LE_WORKING_DIR}" \
        --config-home "${LE_CONFIG_HOME}" \
        --cert-home "${LE_CERT_HOME}"; \
    rm -rf /tmp/install_acme; \
    ln -sf "${LE_WORKING_DIR}/acme.sh" /usr/local/bin/acme.sh; \
    ln -sf /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm

# Create upstream --<verb> wrapper commands in /usr/local/bin
RUN set -eux; \
    for verb in \
        help version install uninstall upgrade issue signcsr deploy \
        install-cert renew renew-all revoke remove list info showcsr \
        install-cronjob uninstall-cronjob cron toPkcs toPkcs8 \
        update-account register-account create-account-key \
        create-domain-key createCSR deactivate deactivate-account \
        set-notify set-default-ca set-default-chain \
        make-dns-persist-value update-account-key list-profiles; \
    do \
        printf '#!/usr/bin/env sh\nexec "%s/acme.sh" --%s --config-home "%s" --cert-home "%s" "$@"\n' \
            "${LE_WORKING_DIR}" "${verb}" "${LE_CONFIG_HOME}" "${LE_CERT_HOME}" \
            > "/usr/local/bin/--${verb}"; \
        chmod 755 "/usr/local/bin/--${verb}"; \
    done

COPY --chown=acme:acme init/overlay.sh /init/overlay.sh
COPY --chown=acme:acme entry.sh /entry.sh

RUN sed -i 's/\r$//' /init/overlay.sh /entry.sh && \
    chmod 755 /init/overlay.sh /entry.sh && \
    chown -R acme:acme \
        "${LE_WORKING_DIR}" \
        "${LE_CONFIG_HOME}" \
        "${LE_CERT_HOME}" \
        /hooks \
        /init

VOLUME ["/acme.sh", "/certs", "/hooks"]

USER acme
WORKDIR /acmebin

ENTRYPOINT ["/entry.sh"]
CMD ["daemon"]