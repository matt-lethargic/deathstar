#!/bin/bash
## inspired by https://github.com/gcgarner/IOTstack

# get path right
pushd ~/deathstar

declare -A cont_array=(
    [portainer]="Portainer"
    [nodered]="Node Red"
    [mosquitto]="Eclipse-Mosquitto"
    [pihole]="Pi-Hole"
    [plex]="Plex media server"
    [nextcloud]="Next-Cloud"
    [nginx]="NGINX"
)

declare -a armhf_keys=("portainer" "nodered" "influxdb" "grafana" "mosquitto" "telegraf" "mariadb" "postgres"
	"adminer" "openhab" "zigbee2mqtt" "pihole" "plex" "tasmoadmin" "rtl_433" "espruinohub"
	"motioneye" "webthings_gateway" "blynk_server" "nextcloud" "diyhue" "homebridge" "python")

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
#------------------------------------------------------
# Updating system
#sudo apt update && sudo apt upgrade -y

#------------------------------------------------------
# Menu
#------------------------------------------------------

# Display main menu
mainmenu_selection=$(whiptail --title "Main Menu" --menu --notags \
	"" 20 78 12 -- \
	"install" "Install Docker" \
	"build" "Build Stack" \
	"hassio" "Install Hass.io (Requires Docker)" \
	"native" "Native Installs" \
	"commands" "Docker commands" \
	"backup" "Backup options" \
	"misc" "Miscellaneous commands" \
	"update" "Update IOTstack" \
	3>&1 1>&2 2>&3)

case $mainmenu_selection in
"install")
    if command_exists docker; then
		echo "docker already installed"
	else
		echo "Install Docker"
		curl -fsSL https://get.docker.com | sh
		sudo usermod -aG docker $USER
	fi

	if command_exists docker-compose; then
		echo "docker-compose already installed"
	else
		echo "Install docker-compose"
		sudo apt install -y docker-compose
	fi

	if (whiptail --title "Restart Required" --yesno "It is recommended that you restart you device now. Select yes to do so now" 20 78); then
		sudo reboot
	fi
	;;
"build")

	title=$'Container Selection'
	message=$'Use the [SPACEBAR] to select which containers you would like to install'
	entry_options=()

	#check architecture and display appropriate menu
	if [ $(echo "$sys_arch" | grep -c "arm") ]; then
		keylist=("${armhf_keys[@]}")
	else
		echo "your architecture is not supported yet"
		exit
	fi

	#loop through the array of descriptions
	for index in "${keylist[@]}"; do
		entry_options+=("$index")
		entry_options+=("${cont_array[$index]}")

		#check selection
		if [ -f ./services/selection.txt ]; then
			[ $(grep "$index" ./services/selection.txt) ] && entry_options+=("ON") || entry_options+=("OFF")
		else
			entry_options+=("OFF")
		fi
	done

    ;;

esac

popd