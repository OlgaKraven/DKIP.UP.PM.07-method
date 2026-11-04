FROM mariadb:10.11@sha256:d769e37960821dfdcf096954f6e7ac89f747e116c1bba98e48edd265dfc7deae
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cron rsyslog nano ca-certificates && apt-get clean
COPY start.sh /opt/pm07/start.sh
ENTRYPOINT ["/bin/bash", "/opt/pm07/start.sh"]
LABEL purpose="pm07-method-qa"
