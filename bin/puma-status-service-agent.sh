#!/usr/bin/env bash

set -e

function cleanup()
{
	set +e
	local pids=`jobs -p`
	if [[ "$pids" != "" ]]; then
		kill $pids 2>/dev/null
	fi
	if [[ "$TEMPDIR" != "" ]]; then
		rm -rf "$TEMPDIR"
	fi
}

if [[ -e Gemfile ]]; then
	BUNDLE_EXEC="bundle exec"
else
	BUNDLE_EXEC=
fi

LOG_PREFIX="puma-status-service-agent"
TEMPDIR=`mktemp -d /tmp/puma-status-service-agent.XXXXXX`
HOSTNAME=`hostname -f`
INTERVAL=${PUMA_STATUS_FREQUENCY:-30}

if [[ "$DYNO" = "" ]]; then
	echo "$LOG_PREFIX: will not be activated, because not running on Heroku."
	exit 0
fi

trap cleanup EXIT

while true; do
	echo "$LOG_PREFIX: waiting $INTERVAL seconds"
	sleep $INTERVAL
	echo "$LOG_PREFIX: Querying status"

	if env NO_COLOR=1 $BUNDLE_EXEC puma-status "$1" > "$TEMPDIR/status.txt"; then
    while read -r line
    do
      echo "${LOG_PREFIX}: $line"
    done <"$TEMPDIR/status.txt"
	fi
done
