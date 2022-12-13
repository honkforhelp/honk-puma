#!/usr/bin/env bash

set -e

# NOTE WELL: The shebang above MUST use "bash" to run on heroku successfully.

function cleanup()
{
	set +e
	local pids=`jobs -p`

	if [[ "$pids" != "" ]]; then
		kill $pids 2>/dev/null
	fi
}

trap cleanup EXIT

echo "Starting PUMA"
PUMA_STATE_FILE="$(pwd)/puma.state"
CONTROL_PORT="9293"

if [[ "$PORT" -eq "$CONTROL_PORT" ]]; then
  CONTROL_PORT="9294"
fi

CONTROL_TOKEN="$RANDOM-$RANDOM-$RANDOM"

# NOTE `watch` will take over your TTY in the console and make it where you can't really see the logs from Puma
# This doesn't happen in heroku because it's not TTY.
$1/bin/puma-status-service-agent.sh "$PUMA_STATE_FILE" &
bundle exec puma --state "$PUMA_STATE_FILE" --control-url "tcp://127.0.0.1:$CONTROL_PORT" --control-token "$CONTROL_TOKEN" -C "$1/config/honk-puma.rb"
