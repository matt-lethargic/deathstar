#!/bin/bash
## inspired by https://github.com/gcgarner/IOTstack

# get path right
pushd ~/deathstar

declare -A cont_array=(
    [portainer]="Portainer"
    [nodered="Node Red"]
    [mosquitto]="Eclipse-Mosquitto"
    [pihole]="Pi-Hole"
    [plex]="Plex media server"
    [nextcloud]="Next-Cloud"
    [nginx]="NGINX"
)

sys_arch=$(uname -m)

#timezones
timezones() {
	env_file=$1
	TZ=$(cat /etc/timezone)

	#test for TZ=
	[ $(grep -c "TZ=" $env_file) -ne 0 ] && sed -i "/TZ=/c\TZ=$TZ" $env_file
}

# this function creates the volumes, services and backup directories. It then assisgns the current user to the ACL to give full read write access
docker_setfacl() {
	[ -d ./services ] || mkdir ./services
	[ -d ./volumes ] || mkdir ./volumes
	[ -d ./backups ] || mkdir ./backups

	# give current user rwx on the volumes and backups
	[ $(getfacl ./volumes | grep -c "default:user:$USER") -eq 0 ] && sudo setfacl -Rdm u:$USER:rwx ./volumes
	[ $(getfacl ./backups | grep -c "default:user:$USER") -eq 0 ] && sudo setfacl -Rdm u:$USER:rwx ./backups
}

# tests for installed software
function command_exists() {
	command -v "$@" >/dev/null 2>&1
}

#---------------------------------------------------------------------------------------------------
# Project updates
echo "checking for project update"
git fetch origin master

if [ $(git status | grep -c "Your branch is up to date") -eq 1 ]; then
	#delete .outofdate if it exisist
	[ -f .outofdate ] && rm .outofdate
	echo "Project is up to date"

else
	echo "An update is available for the project"
	if [ ! -f .outofdate ]; then
		whiptail --title "Project update" --msgbox "An update is available for the project\nYou will not be reminded again until you next update" 8 78
		touch .outofdate
	fi
fi