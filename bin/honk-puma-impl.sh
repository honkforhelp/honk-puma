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

# Check if running on macOS and set fork safety environment variable if needed
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Extract major version number
  if command -v sw_vers >/dev/null 2>&1; then
    MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
    # Check if macOS version is 10.14 (Mojave) or later (where the issue occurs)
    if [[ $MACOS_VERSION -ge 10 ]]; then
      echo "Detected macOS $MACOS_VERSION, setting OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES"
      export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
    fi
  else
    # If sw_vers not available but we know it's macOS, set the variable to be safe
    echo "Detected macOS, setting OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES"
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
  fi
fi

if [[ "$DYNO" = "" ]]; then
  # Don't bother running the control server etc. if we're not on Heroku,
  # if you run more than one project with this Gem locally you'll get into a problem
  # where the second honk-puma can't bind to the control port.
	bundle exec puma -C "$1/config/honk-puma.rb"
else
  $1/bin/puma-status-service-agent.sh "$PUMA_STATE_FILE" &
  bundle exec puma --state "$PUMA_STATE_FILE" --control-url "tcp://127.0.0.1:$CONTROL_PORT" --control-token "$CONTROL_TOKEN" -C "$1/config/honk-puma.rb"
fi
