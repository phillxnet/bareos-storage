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
RUN zypper --non-interactive install tar gzip wget iputils libcap-progs strace

# Create bareos group & user within container with set gid & uid.
# Docker host and docker container share uid & gid.
# Pre-empting the bareos packages' installer doing the same, as we need to known gid & uid for host volume permissions.
# We leave bareos home-dir to be created by the package install scriptlets.
RUN groupadd --system --gid 105 bareos
RUN useradd --system --uid 105 --comment "bareos" --home-dir /var/lib/bareos -g bareos -G disk,tape --shell /bin/false bareos

RUN <<EOF
# https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions

# Autosetup capabilities on package install.
# See: https://docs.bareos.org/TasksAndConcepts/Plugins.html#security-setup
# With the following package flag, the included test script passes:
# /usr/lib/bareos/scripts/bareos-config check_scsicrypto_capabilities
# - Info: All tools have cap_sys_rawio=ep set.
# Above script sources: /usr/lib/bareos/scripts/bareos-config-lib.sh
# which contains rpm defaults re users/groups per daemon.
# I.e.: /usr/lib/bareos/scripts/bareos-config setup_sd_user
# getcap -v /usr/sbin/bareos-sd  # to check capabilities of the binary
touch /etc/bareos/.enable-cap_sys_rawio

# ADD REPOS (COMMUNITY OR SUBSCRIPTION)
# https://docs.bareos.org/IntroductionAndTutorial/WhatIsBareos.html#bareos-binary-release-policy
# - Empty/Undefined BAREOS_SUB_USER & BAREOS_SUB_PASS = COMMUNITY 'current' repo.
# -- Community current repo: https://download.bareos.org/current
# -- wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh
# - BAREOS_SUB_USER & BAREOS_SUB_PASS = Subscription rep credentials
# -- Subscription repo: https://download.bareos.com/bareos/release/
# User + Pass entered in the following retrieves the script pre-edited:
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories.sh
# or
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories_template.sh
# sed edit using BAREOS_SUB_USER & BAREOS_SUB_PASS
if [ ! -f  /etc/bareos/bareos-storage-install.control ]; then
  # Retrieve and Run Bareos's official repository config script
  wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh
  sh ./add_bareos_repositories.sh
  zypper --non-interactive --gpg-auto-import-keys refresh
  # File daemon
  zypper --non-interactive install bareos-storage bareos-storage-tape bareos-tools
  # Control file
  touch /etc/bareos/bareos-storage-install.control
fi
EOF

# Stash default package config: ready to populare host volume mapping
RUN tar czf bareos-sd_d.tgz /etc/bareos/bareos-sd.d

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

# See README.md 'Host User configuration' section.
USER bareos

ENTRYPOINT ["docker-entrypoint.sh"]
# /usr/sbin/bareos-sd --help
# e.g.: --test-config --verbose
# passed as a parameter to docker-entrypoint.sh
CMD ["/usr/sbin/bareos-sd", "--foreground", "--debug-level", "1"]
