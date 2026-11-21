#!/bin/sh
set -e

echo "Initializing ACME appliance..."

if [ -x /init/overlay.sh ]; then
    /init/overlay.sh
fi

if [ "$1" = "daemon" ]; then
    if [ ! -f "${LE_CONFIG_HOME}/crontab" ]; then
        echo "${LE_CONFIG_HOME}/crontab not found, generating one..."
        time=$(date -u "+%s")
        random_minute=$((time % 60))
        random_hour=$((time / 60 % 6))
        echo "${random_minute} ${random_hour},$((random_hour + 6)),$((random_hour + 12)),$((random_hour + 18)) * * * \"${LE_WORKING_DIR}/acme.sh\" --cron --home \"${LE_WORKING_DIR}\" --config-home \"${LE_CONFIG_HOME}\" --cert-home \"${LE_CERT_HOME}\"" > "${LE_CONFIG_HOME}/crontab"
    fi
    echo "Running Supercronic using crontab at ${LE_CONFIG_HOME}/crontab"
    exec /usr/bin/supercronic "${LE_CONFIG_HOME}/crontab"
elif [ "${1#--}" != "$1" ]; then
    # Allow passing acme.sh flags directly (e.g., CMD ["--help"] or docker run ... --issue ...)
    exec "${LE_WORKING_DIR}/acme.sh" --home "${LE_WORKING_DIR}" --config-home "${LE_CONFIG_HOME}" --cert-home "${LE_CERT_HOME}" "$@"
else
    exec "$@"
fi