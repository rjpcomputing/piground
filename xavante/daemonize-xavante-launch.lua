#!/usr/bin/env lua

function daemonize_xavante_launch()
	local serviceScript	=
[==[#!/bin/bash
### BEGIN INIT INFO
# Provides:          xavante
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start irssi daemon within screen session at boot time
# Description:       This init script will start an irssi session under screen using the settings provided in /etc/xavante.conf
### END INIT INFO

# Include the LSB library functions
. /lib/lsb/init-functions

# Setup static variables
# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
DESC="Lua web server"
NAME=xavante
DAEMON=/usr/local/bin/wsapi
DAEMON_ARGS=""
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
CONFIG_FILE=/etc/$NAME.conf

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Checks if the configuration files are available and properly setup.
#
# Return: 0 if xavante if properly configured, 1 otherwise.
#
function CheckConfig() {
    # Make sure the configuration file has been created
    if ! [[ -f $CONFIG_FILE ]]; then
        log_failure_msg "Please populate the configuration file '$CONFIG_FILE' \
before running."
        exit 6
    fi

    # Make sure the required options have been set
    local reqOptions=(user group port htdocs log)
    for option in "${reqOptions[@]}"; do
        if ! grep -q -e "^[[:blank:]]*$option=" "$CONFIG_FILE"; then
            log_failure_msg "Mandatory option '$option' was not specified in \
'$CONFIG_FILE'"
            exit 6
        fi
    done
}

#
# Loads the configuration file and performs any additional configuration steps.
#
function Configure() {
    . "$CONFIG_FILE"

    # Create document root if it does not exist
    if [ ! -d $htdocs ]; then
        mkdir -p $htdocs
    fi

    # Create the log file if it doesn't exist
    if [ ! -a $log ]; then
        touch $log
    fi
    chown $user:$group $log

    DAEMON_ARGS="$DAEMON_ARGS --port=$port --log=$log --op"
    [[ -n $args ]] && DAEMON_ARGS="$DAEMON_ARGS $args"
    DAEMON_ARGS="$DAEMON_ARGS $htdocs"
    #log_daemon_msg $DAEMON $DAEMON_ARGS
}

#
# Function that starts the daemon/service
#
do_start()
{
    #start-stop-daemon --start --quiet --oknodo --pidfile "$pidFile" \
    #    --make-pidfile --chuid "$user:$group" --background \
    #    --exec "$daemonExec" -- $daemonArgs

    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
            || return 1
    start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --make-pidfile --chuid "$user:$group" --background \
            --exec $DAEMON -- $DAEMON_ARGS \
            || return 2
    # Add code here, if necessary, that waits for the process to be ready
    # to handle requests from services started subsequently which depend
    # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    # Wait for children to finish too if this is a daemon that forks
    # and if the daemon is only ever run from this initscript.
    # If the above conditions are not satisfied then add some other code
    # that waits for the process to drop all resources that could be
    # needed by services started subsequently.  A last resort is to
    # sleep for some time.
    start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
    [ "$?" = 2 ] && return 2
    # Many daemons don't delete their pidfiles when they exit.
    rm -f $PIDFILE
    return "$RETVAL"
}

CheckConfig
Configure

case "$1" in
  start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  status)
       status_of_proc -p "$PIDFILE" "$DAEMON" "$NAME" && exit 0 || exit $?
       ;;
  #reload|force-reload)
        #
        # If do_reload() is not implemented then leave this commented out
        # and leave 'force-reload' as an alias for 'restart'.
        #
        #log_daemon_msg "Reloading $DESC" "$NAME"
        #do_reload
        #log_end_msg $?
        #;;
  restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting $DESC" "$NAME"
        do_stop
        case "$?" in
          0|1)
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
        exit 3
        ;;
esac
]==]
	local serviceConfigScript =
[==[#
# Configuration file for xavante init script
#
# Mandatory options:
#
#    user    - Specify user for running xavante.
#    group   - Specify group for running xavante.
#    port    - Binds to the specified port (default 8080)
#    htdocs  - Specify the directory for xavante to use as its document root.
#    log     - Specify the file for xavante to log to.
#
# Non-mandatory options:
#
#    args    - Pass additional arguments to xavante.
#
# Example configuration:
#user='john'
#group='users'
#htdocs='/var/xavante'
#log='/var/log/xavante.log'
#args='--config /home/john/.xavante/config_alternative'

user='www-data'
group='www-data'
port=8080
htdocs='/var/xavante'
log='/var/log/xavante.log'
]==]
	local serviceLocation = "/etc/init.d/xavante"
	local configLocation = "/etc/xavante.conf"
	-- Write the file out
	local f = io.output( serviceLocation )
	f:write( serviceScript )
	f:close()
	local f = io.output( configLocation )
	f:write( serviceConfigScript )
	f:close()

	-- Set permissions
	os.execute( ("chmod +x %s"):format( serviceLocation ) )
	os.execute( ("chmod +x %s"):format( configLocation ) )
	-- Make it start with the system boot
	os.execute( "update-rc.d xavante defaults" )
end

local function main()
	-- Check if script is being ran as root.
	local username = os.getenv( "USER" )
	if username ~= "root" then
		error( "Please run this as root. Use 'sudo' to run this as root", 0 )
	end
	
	daemonize_xavante_launch()
	print( "Make sure to start Xavante by\n\t'sudo service xavate start'" )
end

main()