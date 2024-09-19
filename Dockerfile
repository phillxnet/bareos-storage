# Rockstor Bareos server set
FROM opensuse/leap:15.6

# For our setup we explicitly use container's root user at '/':
USER root
WORKDIR /

# https://specs.opencontainers.org/image-spec/annotations/
LABEL maintainer="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.authors="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.description="Bareos Storage - deploys packages from https://download.bareos.org/"

# We only know if we are COMMUNIT or SUBSCRIPTION at run-time via env vars.
RUN zypper --non-interactive install wget iputils libcap-progs strace

# Create bareos group & user within container with set gid & uid.
# Docker host and docker container share uid & gid.
# Required ahead of package install, which would also do this, as we need to known gid & uid.
# We leave bareos home-dir to be created by the package install scriptlets.
RUN groupadd --system --gid 105 bareos
RUN useradd --system --uid 105 --comment "bareos" --home-dir /var/lib/bareos -g bareos -G disk,tape --shell /bin/false bareos

COPY docker-entrypoint.sh /usr/local/sbin
RUN chmod u+x /usr/local/sbin/docker-entrypoint.sh

# BareOS services have WorkingDirectory=/var/lib/bareos
# /etc/systemd/system/bareos-storage.service
# /usr/lib/systemd/system/bareos-sd.service
# https://docs.docker.com/reference/dockerfile/#workdir
WORKDIR /var/lib/bareos

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
VOLUME /var/lib/bareos/storage

# 'Storage' communications port.
EXPOSE 9103

# https://docs.docker.com/reference/dockerfile/#user
# https://docs.bareos.org/TasksAndConcepts/Plugins.html#security-setup
# Storage deamon normally runs as the `bareos` user & primary group, created by the packages themselves.
# The additional groups of disk,tape are also configured/requried.
# 'groups bareos' returns: "bareos : bareos disk tape"
# On docker host:
# To create 'bareos' user (& group) with disk,tape supplementary groups:
# - useradd -r --comment "bareos" --home /var/lib/bareos --user-group -G disk,tape --shell /bin/false bareos
# If 'bareos' group already exists:
# - useradd -r --comment "bareos" --home /var/lib/bareos -g bareos -G disk,tape --shell /bin/false bareos
USER bareos

ENTRYPOINT ["docker-entrypoint.sh"]
# /usr/sbin/bareos-sd --help
# e.g.: --test-config --verbose
# passed as a parameter to docker-entrypoint.sh
CMD ["/usr/sbin/bareos-sd", "--foreground", "--debug-level", "1"]
