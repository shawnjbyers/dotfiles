# This file is executed by bash upon logout.
# We will attempt to clear the screen for privacy.

# Attempt to clear the terminal with clear_console.
# First check if clear_console exists and if this is a console.
if [ "$SHLVL" = 1 ]
then
	# This is a console.

	if [ -x /usr/bin/clear_console ]
	then
		# We have the clear_console command.

		# Try to use clear_console and ignore errors.
		/usr/bin/clear_console --quiet || true
	fi
fi

# Use the POSIX-defined tput to clear the screen regardless.
# The "command -p" ensures we have a $PATH that contains tput.
command -p tput clear
