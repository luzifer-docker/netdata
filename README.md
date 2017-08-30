# Luzifer-Docker / netdata

This repository contains a dockerized version of the [netdata](https://github.com/firehol/netdata) daemon. It supports adding and overriding configurations and plugins through overrides.

The expected structure on the `/override` volume mount is as following:

```
/override
├── charts.d
├── conf.d
├── node.d
├── plugins.d
└── python.d
```
