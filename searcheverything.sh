#!/bin/bash

# script by melon
# this script is best understood reading from the bottom
# the later a function is called the further to the top it will be
# but global variables are defined at the top
# also ensure fzf(fuzzy finder) is in the path environment variable

# configure editor $com and configuration file $conffiles
com="vim"; conffiles="$HOME/path/to/config"

# function to check user permissions of the selected file and then call your selected editor $com
# if owner of file doesn't match user calling this script it will call the editor with sudo
call_editor(){
	[ "$(stat -c '%U' "$sel")" = "$USER" ] && { $com $sel; exit; } \
	|| { com="sudo $com"; $com $sel; exit; }
}

# function to execute fuzzy finder
call_fzf(){ sel=$(echo "$files" | fzf); [ -n "$sel" ] && call_editor || exit 0; }

# this function runs the find command to the specified depth
# then greps through output to include or exclude as specified in config
call_find(){
	[ $dpth = 0 ] && fndcom="find $d -type f" || fndcom="find $d -maxdepth $dpth -type f"
	[ -n "$exc" ] && $fndcom -name "*" | grep -e "$inc" | grep -ve "$exc" || $fndcom -name "*" | grep -e "$inc"
}

# this function is the loop that reads the $conffiles config file excluding any line opening with #
# note how it reads the config 3 lines at a time $line1 $line2 $line3
# $dpth is the recursive search depth to look for files with 0 being fully recursive
# $d is the base directory to search and is evaluated to allow environment vars like $HOME to be used in the config
# $inc is the included search params to grep through the files and $exc is the excluded search params for grep
call_conf(){
	while read line1; read line2; read line3; do
		dpth=$(echo "$line1" | cut -d ' ' -f1); d=$(eval echo $(echo "$line1" | cut -d ' ' -f2-))
		inc=$(echo "$line2" | sed 's: :\n:g'); exc=$(echo "$line3" | sed 's: :\n:g')
		call_find
	done < <(cat $conffiles | sed "/^#/d")
}

# this functions defines the lists of $files to be piped into fzf
# it calls call_conf function in this way to allow the variable $files to be defined from a while loop
call_search(){ files=$(cat <(call_conf)); }

# check for arguments
# --dump just outputs the list of files the config produces, very useful in managing a bare git repo
# --dump could also be used to create a static list of files which could be incorporated into a new function
case $1 in
	'') call_search; call_fzf ;;
	'--dump') call_search; echo -e "$files";;
	*) echo "Invalid argument" ; exit 1 ;;
esac
