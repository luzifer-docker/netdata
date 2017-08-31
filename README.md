# Luzifer-Docker / netdata

This repository contains a dockerized version of the [netdata](https://github.com/firehol/netdata) daemon. It supports adding and overriding configurations and plugins through overrides and partially configuration through environment variables.

## Usage

```
docker run -d --cap-add SYS_PTRACE \
           -v /proc:/host/proc:ro \
           -v /sys:/host/sys:ro \
           -p 19999:19999 quay.io/luzifer/netdata
```

## Configuration

To configure alerts have a look at the [`health_alarm_notify.conf` template](templates/health_alarm_notify.conf). There you can see all variable names you need to specify as environment variables.

When using the override mount you can add configuration files and plugins. The expected structure on the `/override` volume mount is as following:

```
/override
├── charts.d
├── conf.d
├── node.d
├── plugins.d
└── python.d
```

