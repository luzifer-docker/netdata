#!/bin/bash
set -ex
set -o pipefail

DEBIAN_FRONTEND=noninteractive

# install dependencies for build

apt-get -qq update
apt-get -y install zlib1g-dev uuid-dev libmnl-dev gcc make curl git autoconf autogen automake pkg-config netcat-openbsd jq \
                   autoconf-archive lm-sensors nodejs python python-mysqldb python-yaml \
                   ssmtp mailutils apcupsd rsync

# fetch netdata

git clone https://github.com/firehol/netdata.git /netdata.git
cd /netdata.git
TAG=$(</src/git-tag)
if [ ! -z "$TAG" ]; then
  echo "Checking out tag: $TAG"
  git checkout tags/$TAG
else
  echo "No tag, using master"
fi

# use the provided installer

./netdata-installer.sh --dont-wait --dont-start-it

# remove build dependencies

cd /
rm -rf /netdata.git

apt-get purge -y zlib1g-dev uuid-dev libmnl-dev gcc make git autoconf autogen automake pkg-config
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log

# Install korvike for template substitution
curl -sSLfo /usr/local/bin/korvike https://github.com/Luzifer/korvike/releases/download/v0.4.1/korvike_linux_amd64
chmod +x /usr/local/bin/korvike
echo 'f791fecdc62b2e2ff07342b41fdf165ee40c2a8a286f1c2c0f48228b982e2953  /usr/local/bin/korvike' | sha256sum -c
