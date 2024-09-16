# Rockstor Bareos server set
FROM opensuse/leap:15.6

# https://specs.opencontainers.org/image-spec/annotations/
LABEL maintainer="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.authors="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.description="Bareos Storage - deploys packages from https://download.bareos.org/"

# We only know if we are COMMUNIT or SUBSCRIPTION at run-time via env vars.
RUN zypper --non-interactive install wget iputils libcap-progs strace

# The firt two VOLUME entries can be inherited from a local/associated Director, e.g. via `--volumes-from bareos-director`.
# Volume sharing is not requried for non-local Bareos 'Storage' daemons instantiated by this image.
# However if resulting containers share at least /etc/bareos the resulting Daemon will have it's configuration backedup,
# via the default MyCatalog backup; which includes /et/bareos.
# Config
VOLUME /etc/bareos
# Data/status (working directory)
# Also default Director DB dump/backup file (bareos.sql) location (see FileSet 'Catalog')
VOLUME /var/lib/bareos

# Storage location for this daemons associated Archives
VOLUME /var/lib/bareos/archive

# 'Storage' communications port.
EXPOSE 9103

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

# BareOS services have WorkingDirectory=/var/lib/bareos
# /etc/systemd/system/bareos-storage.service

# https://docs.bareos.org/TasksAndConcepts/Plugins.html#security-setup
# Storage deamon normally runs as the `bareos` user & group, created by the packages themselves.

ENTRYPOINT ["/docker-entrypoint.sh"]
# /usr/sbin/bareos-sd --help
# e.g.: --test-config --verbose
CMD ["/usr/sbin/bareos-sd", "--user", "bareos", "--group", "bareos", "--foreground", "--debug-level", "1"]
