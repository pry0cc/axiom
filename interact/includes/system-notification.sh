NOTIFY_CMD=notify
BASEOS="$(uname)"

# method issuing notifications for at least most ubuntu like systems
# expects a title as first and a notification as second argument
function notify {
  notify-send "display notification \"$2\" with title \"$1\""
}

# method issuing notifications in place of notify-send on OSX
# expects a title as first and a notification as second argument
function notifyOSX {
  osascript -e "display notification \"$2\" with title \"$1\""
}

if [ $BASEOS == "Darwin" ]; then NOTIFY_CMD=notifyOSX; fi
