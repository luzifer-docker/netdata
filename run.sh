#!/bin/bash

set -ex
set -o pipefail

# fix permissions due to netdata running as root
chown -R root:root /usr/share/netdata/web/
echo -n "" > /usr/share/netdata/web/version.txt

# set up ssmtp
if [[ $SSMTP_TO ]] && [[ $SSMTP_USER ]] && [[ $SSMTP_PASS ]]; then
cat << EOF > /etc/ssmtp/ssmtp.conf
root=$SSMTP_TO
mailhub=$SSMTP_SERVER:$SSMTP_PORT
AuthUser=$SSMTP_USER
AuthPass=$SSMTP_PASS
UseSTARTTLS=$SSMTP_TLS
hostname=$SSMTP_HOSTNAME
FromLineOverride=NO
EOF

cat << EOF > /etc/ssmtp/revaliases
netdata:netdata@$SSMTP_HOSTNAME:$SSMTP_SERVER:$SSMTP_PORT
root:netdata@$SSMTP_HOSTNAME:$SSMTP_SERVER:$SSMTP_PORT
EOF
fi

if [[ $NETDATA_IP ]]; then
  NETDATA_ARGS="${NETDATA_ARGS} -i ${NETDATA_IP}"
fi

# on a client netdata set this destination to be the [PROTOCOL:]HOST[:PORT] of the
# central netdata, and give an API_KEY that is secret and only known internally
# to the netdata clients, and netdata central
if [[ $NETDATA_STREAM_DESTINATION ]] && [[ $NETDATA_STREAM_API_KEY ]]; then
  cat << EOF > /etc/netdata/stream.conf
[stream]
  enabled = yes
  destination = $NETDATA_STREAM_DESTINATION
  api key = $NETDATA_STREAM_API_KEY
EOF
fi

# set 1 or more NETADATA_API_KEY_ENABLE env variables, such as NETDATA_API_KEY_ENABLE_1h213ch12h3rc1289e=1
# that matches the API_KEY that you used on the client above, this will enable the netdata client
# node to communicate with the netdata central
if printenv | grep -q 'NETDATA_API_KEY_ENABLE_'; then
  printenv | grep -oe 'NETDATA_API_KEY_ENABLE_[^=]\+' | sed 's/NETDATA_API_KEY_ENABLE_//' | xargs -n1 -I{} echo '['{}$']\n\tenabled = yes' >> /etc/netdata/stream.conf
fi

# Execute templates
korvike -i /src/templates/health_alarm_notify.conf -o /etc/netdata/health_alarm_notify.conf

# Pull in overrides and additions for config and plugins
[ -e /override/conf.d ] && rsync -arv /override/conf.d/ /etc/netdata/
for dir in charts.d node.d plugins.d python.d; do
  [ -e "/override/${dir}" ] && rsync -arv "/override/${dir}/" "/usr/libexec/netdata/${dir}/"
done

# exec custom command
if [[ $# -gt 0 ]] ; then
  exec "$@"
  exit
fi

if [[ -d "/fakenet/" ]]; then
  echo "Running fakenet config reload in background"
  ( sleep 10 ; curl -s http://localhost:${NETDATA_PORT}/netdata.conf | sed -e 's/# filename/filename/g' | sed -e 's/\/host\/proc\/net/\/fakenet\/proc\/net/g' > /etc/netdata/netdata.conf ; pkill -9 netdata ) &
  /usr/sbin/netdata -D -u root -s /host -p ${NETDATA_PORT}
  # add some artificial sleep because netdata might think it can't bind to $NETDATA_PORT
  # and report things like "netdata: FATAL: Cannot listen on any socket. Exiting..."
  sleep 1
fi

# main entrypoint
exec /usr/sbin/netdata -D -u root -s /host -p ${NETDATA_PORT} ${NETDATA_ARGS}
