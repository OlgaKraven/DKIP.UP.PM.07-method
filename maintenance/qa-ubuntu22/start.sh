#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld /var/lib/mysql
if [[ ! -d /var/lib/mysql/mysql ]]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=socket --skip-test-db
fi
printf 'module(load="imuxsock")\n*.* /var/log/syslog\n' > /tmp/pm07-rsyslog.conf
rsyslogd -f /tmp/pm07-rsyslog.conf -i /run/pm07-rsyslog.pid
/usr/sbin/service mariadb start
exec /usr/sbin/cron -f -L 15
