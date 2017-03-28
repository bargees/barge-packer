#!/bin/sh

if [ "$(id -u)" != "0" ]; then
  echo "$(basename $0): Operation not permitted" >&2
  exit 1
fi

: ${DOCKER_PROFILE:=/etc/default/docker}
if [ -f ${DOCKER_PROFILE} ]; then
  . ${DOCKER_PROFILE}
fi
: ${DOCKER_STORAGE:="overlay"}
: ${DOCKER_DIR:="/var/lib/docker"}
: ${DOCKER_HOST:="-H unix://"}
: ${DOCKER_EXTRA_ARGS="--userland-proxy=false"}
: ${DOCKER_ULIMITS:=1048576}
: ${DOCKER_LOGFILE:="/var/log/docker/docker.log"}
: ${DOCKER_TIMEOUT:=5}

: ${CERT_DIR:=/etc/docker}
: ${CERT_INTERFACES:="eth0 eth1"}

: ${CACERT:="${CERT_DIR}/ca.pem"}
: ${CAKEY:="${CERT_DIR}/cakey.pem"}
: ${SERVERCERT:="${CERT_DIR}/server.pem"}
: ${SERVERKEY:="${CERT_DIR}/serverkey.pem"}
: ${CERT:="${CERT_DIR}/cert.pem"}
: ${KEY:="${CERT_DIR}/key.pem"}

: ${ORG:=Bargees}
: ${SERVERORG:="${ORG}"}
: ${CAORG:="${ORG}CA"}

mkdir -p /opt/bin
if [ ! -f /opt/bin/generate_cert ]; then
  echo "Get generate_cert"
  wget -q -O /opt/bin/generate_cert https://github.com/SvenDowideit/generate_cert/releases/download/0.3/generate_cert-0.3-linux-amd64
  chmod +x /opt/bin/generate_cert
fi

CERT_HOSTNAMES="localhost,127.0.0.1,$(hostname -s),$(hostname -i)"
for interface in ${CERT_INTERFACES}; do
  IPS=$(ip addr show ${interface} 2>/dev/null | sed -nEe 's/^[ \t]*inet[ \t]*([0-9.]+)\/.*$/\1/p')
  for ip in $IPS; do
    CERT_HOSTNAMES="${CERT_HOSTNAMES},$ip"
  done
done

echo "Need TLS certs for ${CERT_HOSTNAMES}"
echo "-------------------"

mkdir -p "${CERT_DIR}"
chmod 700 "${CERT_DIR}"
if [ ! -f "${CACERT}" ] || [ ! -f "${CAKEY}" ]; then
  echo "Generate CA cert"
  /opt/bin/generate_cert --cert="${CACERT}" --key="${CAKEY}" --org="${CAORG}"
  rm -f "${SERVERCERT}" "${SERVERKEY}" "${CERT}" "${KEY}" "${CERT_DIR}/hostnames"
fi

CERTS_EXISTFOR=$(cat "${CERT_DIR}/hostnames" 2>/dev/null)
if [ "${CERT_HOSTNAMES}" != "${CERTS_EXISTFOR}" ]; then
  echo "Generate server cert"
  /opt/bin/generate_cert --host="${CERT_HOSTNAMES}" --ca="${CACERT}" --ca-key="${CAKEY}" --cert="${SERVERCERT}" --key="${SERVERKEY}" --org="${SERVERORG}"
  echo "${CERT_HOSTNAMES}" > "${CERT_DIR}/hostnames"
fi

if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
  echo "Generating client cert"
  /opt/bin/generate_cert --ca="${CACERT}" --ca-key="${CAKEY}" --cert="${CERT}" --key="${KEY}" --org="${ORG}"
fi

DOCKER_HOST="-H unix:// -H tcp://0.0.0.0:2376"
DOCKER_EXTRA_ARGS=`echo "${DOCKER_EXTRA_ARGS}" | sed 's/\s*--tls\S*//g'`
DOCKER_EXTRA_ARGS="${DOCKER_EXTRA_ARGS} --tlsverify --tlscacert=${CACERT} --tlscert=${SERVERCERT} --tlskey=${SERVERKEY}"
echo "DOCKER_STORAGE=\"${DOCKER_STORAGE}\""        > ${DOCKER_PROFILE}
echo "DOCKER_DIR=\"${DOCKER_DIR}\""               >> ${DOCKER_PROFILE}
echo "DOCKER_HOST=\"${DOCKER_HOST}\""             >> ${DOCKER_PROFILE}
echo "DOCKER_EXTRA_ARGS=\"${DOCKER_EXTRA_ARGS}\"" >> ${DOCKER_PROFILE}
echo "DOCKER_ULIMITS=${DOCKER_ULIMITS}"           >> ${DOCKER_PROFILE}
echo "DOCKER_LOGFILE=\"${DOCKER_LOGFILE}\""       >> ${DOCKER_PROFILE}
echo "DOCKER_TIMEOUT=${DOCKER_TIMEOUT}"           >> ${DOCKER_PROFILE}

# now make the client certificates available to the bargee user
USERCFG="/home/bargee/.docker"
mkdir -p "${USERCFG}"
chmod 700 "${USERCFG}"
cp "$CACERT" "${USERCFG}"
cp "$CERT" "${USERCFG}"
cp "$KEY" "${USERCFG}"
chown -R bargee:bargees "${USERCFG}"
