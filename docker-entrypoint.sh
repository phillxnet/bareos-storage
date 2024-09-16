#!/usr/bin/sh

# https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions
# https://docs.bareos.org/IntroductionAndTutorial/WhatIsBareos.html#bareos-binary-release-policy

# ADD REPOS (COMMUNITY OR SUBSCRIPTION)
# Later pick according to variables entered at Rock-on
# - empty = community
# - BareOS subscription credentials = Subscription repository

# Official Bareos Subscription Repository
# - https://download.bareos.com/bareos/release/
# User + Pass entered in the following retrieves the script pre-edited:
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories.sh
# or
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories_template.sh
# sed edit with BareOS subscription credentials and execute it.

# Community current: https://download.bareos.org/current
# - wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh

# Autosetup capabilities on package install.
# See: https://docs.bareos.org/TasksAndConcepts/Plugins.html#security-setup
touch /etc/bareos/.enable-cap_sys_rawio

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

# https://docs.bareos.org/Configuration/CustomizingTheConfiguration.html#configurechapter
# https://docs.bareos.org/Configuration/StorageDaemon.html
# https://docs.bareos.org/Configuration/CustomizingTheConfiguration.html#names-passwords-and-authorization
if [ ! -f /etc/bareos/bareos-storage-config.control ]; then
  # if BAREOS_SD_PASSWORD is unset, set from directors config via shared /etc/bareos, if found.
  if [ -z "${BAREOS_SD_PASSWORD}" ] && [ -f /etc/bareos/bareos-dir.d/storage/File.conf ]; then
    # Use Director's default defined "File" storage: "Password = ".
    # TODO set BAREOS_SD_PASSWORD from directors default ./storage/File.conf
    echo
  fi
  # if BAREOS_DIR_NAME is unset, set from directors bareos-dir.conf via shared /etc/bareos, if found.
  # Otherwise default to "bareos-dir"
  if [ -z "${BAREOS_DIR_NAME}" ]; then
    if [ -f /etc/bareos/bareos-dir.d/director/bareos-dir.conf ]; then
      # Use Director's config "Name = bareos-dir".
      # TODO set BAREOS_DIR_NAME from directors default bareos-dir.conf config if possible
      echo
    else
      BAREOS_DIR_NAME="bareos-dir"
    fi
    echo
  fi
  # Set Storage daemon's authorized director credentials (Name/Password)
  sed -i 's#Name = .*#Name = '\""${BAREOS_DIR_NAME}"\"'#' \
    /etc/bareos/bareos-sd.d/director/bareos-dir.conf
  sed -i 's#Password = .*#Password = '\""${BAREOS_SD_PASSWORD}"\"'#' \
    /etc/bareos/bareos-sd.d/director/bareos-dir.conf

  # Control file
  touch /etc/bareos/bareos-storage-config.control
fi

# set/check capabilities:
# https://docs.bareos.org/TasksAndConcepts/Plugins.html#security-setup
# /usr/lib/bareos/scripts/bareos-config
# which sources: /usr/lib/bareos/scripts/bareos-config-lib.sh  # contains rpm defaults re users/groups per daemon
# E.g.:
# /usr/lib/bareos/scripts/bareos-config check_scsicrypto_capabilities
# /usr/lib/bareos/scripts/bareos-config setup_sd_user
# getcap -v /usr/sbin/bareos-sd  # to check capabilities of the binary

# Run Dockerfile CMD
exec "$@"
