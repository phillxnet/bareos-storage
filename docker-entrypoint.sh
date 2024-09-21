#!/usr/bin/sh

# https://docs.bareos.org/Configuration/CustomizingTheConfiguration.html#configurechapter
# https://docs.bareos.org/Configuration/StorageDaemon.html
# https://docs.bareos.org/Configuration/CustomizingTheConfiguration.html#names-passwords-and-authorization
if [ ! -f /etc/bareos/bareos-storage-config.control ]; then
  # Populate host volume map with package defaults from docker build steps:
  tar xfz /bareos-sd_d.tgz --backup=simple --suffix=.before-storage-config --strip 2 --directory /etc/bareos
  # if BAREOS_SD_PASSWORD is unset, set from directors config via shared /etc/bareos, if found.
  if [ -z "${BAREOS_SD_PASSWORD}" ] && [ -f /etc/bareos/bareos-dir.d/storage/File.conf ]; then
    # Use Director's default defined "File" storage: "Password = ".
    # TODO set BAREOS_SD_PASSWORD from directors default ./storage/File.conf
    echo
  fi
  # if BAREOS_DIR_NAME is unset, set from directors bareos-dir.conf via shared /etc/bareos, if found.
  # Otherwise default to "bareos-dir"
  if [ -z "${BAREOS_DIR_NAME}" ] && [ -f /etc/bareos/bareos-dir.d/director/bareos-dir.conf ]; then
    # Use Director's config "Name = bareos-dir".
    # TODO set BAREOS_DIR_NAME from directors default bareos-dir.conf config if possible
    echo
  fi

  if [ -z "${BAREOS_DIR_NAME}" ]; then
    BAREOS_DIR_NAME="bareos-dir"
  fi

  if [ -z "${BAREOS_SD_NAME}" ]; then
    BAREOS_SD_NAME="bareos-sd"
  fi

  # Set this Storage daemon's Name:
  sed -i 's#Name = .*#Name = '\""${BAREOS_SD_NAME}"\"'#' \
    /etc/bareos/bareos-sd.d/storage/bareos-sd.conf
  # Set this Storage daemon's authorized director credentials (Name/Password)
  sed -i 's#Name = .*#Name = '\""${BAREOS_DIR_NAME}"\"'#' \
    /etc/bareos/bareos-sd.d/director/bareos-dir.conf
  sed -i 's#Password = .*#Password = '\""${BAREOS_SD_PASSWORD}"\"'#' \
    /etc/bareos/bareos-sd.d/director/bareos-dir.conf

  # Control file
  touch /etc/bareos/bareos-storage-config.control
fi

# Run Dockerfile CMD
exec "$@"
