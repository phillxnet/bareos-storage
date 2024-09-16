# Bareos Storage

Bareos (Backup Archiving REcovery Open Sourced) Architecture overview: https://www.bareos.com/software/

Follows Bareos's own install instructions as closely as possible: given container limitations.
Initially uses only Bareos distributed community packages [Bareos Community Repository](https://download.bareos.org/current) `Current` variant.

Intended future capability, upon instantiation, is to use the [Official Bareos Subscription Repository](https://download.bareos.com/bareos/release/),
if non-empty subscription credentials are passed by environmental variables.

See: [Decide about the Bareos release to use](https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#decide-about-the-bareos-release-to-use)

Based on opensuse/leap:15.6 as per BareOS instructions:
[SUSE Linux Enterprise Server (SLES), openSUSE](https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions)

Inspired & informed by the many years of Bareos container maintenance done by Marc Benslahdine https://github.com/barcus/bareos, and contributors.

This images' resulting container's /etc/bareos & /var/lib/bareos is intended to be inherited from the same-author bareos-director container.
This enables a similarly configured Director-local FILE daemon to include this images container config in the default MyCatalog job.
The MyCatalog backup job includes the director's /etc/bareos.

The image is also compatible with independent instantiation: i.e. to create a stand-along Bareos Storage instance;
non-local/no-shares, to/with, an associated Bareos Directors.

The intention here is to simplifying/containerise a Bareos server set deployment:
i.e. Director/Catalog/Storage/File/WebUI server set.

## Environmental Variables

Director & File deamons contact Storage daemons with instructions on what files to:
- (Backup) receive from a director associated File daemon.
- (Restore) send to a director associated File deamon.
This password must tally with that held by the Director for this image's resulting container hostname.

- BAREOS_DIR_NAME: Tally with Director's 'Name' in /etc/bareos/bareos-dir.d/director/bareos-dir.conf
- BAREOS_SD_PASSWORD: Tally with a Director's config in /etc/bareos/bareos-dir.d/storage/

## Local Build
- -t tag <name>
- . indicates from-current directory

```
docker build -t bareos-storage .
# to pune build workspace:
docker system prune -a --volumes
```

## Local Run

```
docker run --name bareos-storage bareos-storage
# skip entrypoint and run shell
docker run -it --entrypoint sh bareos-storage
```

## Interactive shell

```
docker run -it --name bareos-storage bareos-storage sh
# to an already running container
docker exec -it bareos-storage sh
```

## Diagnosing CMD issues

```shell
zypper in strace less
strace /usr/sbin/bareos-sd -f > out.txt 2>&1
less out.txt
strace sh -c "/usr/sbin/bareos-sd -u bareos -g bareos -f -debug-level 2"
ldd /usr/sbin/bareos-sd
```

## BareOS rpm package scriptlet actions

### bareos-storage

```shell
tape:x:488:
disk:x:493:
Info: replacing 'XXX_REPLACE_WITH_STORAGE_PASSWORD_XXX' in /etc/bareos/bareos-sd.d/director/bareos-dir.conf
Info: replacing 'XXX_REPLACE_WITH_STORAGE_MONITOR_PASSWORD_XXX' in /etc/bareos/bareos-sd.d/director/bareos-mon.conf
Info: replacing 'XXX_REPLACE_WITH_STORAGE_MONITOR_PASSWORD_XXX' in /etc/bareos/tray-monitor.d/storage/StorageDaemon-local.conf
```
