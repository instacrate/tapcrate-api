#!/usr/bin/env bash

reset_production_server() {

	local prodServiceFileName="tapcrated.service.txt"
	local prodServiceName="tapcrated.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload
}

reset_development_server() {

	local prodServiceFileName="dev-tapcrated.service.txt"
	local prodServiceName="dev-tapcrated.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload
}

CURRENT_GIT_SHA="$(git rev-parse HEAD)"

echo "\n>>>> git pull origin"
git pull origin

if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- nginx/)" ]; then
	echo "    \n>>>> sudo cp -ru nginx/* /etc/nginx/"
	sudo cp -ru nginx/* /etc/nginx/

	nginx_config_test="$(sudo nginx -t)"
	test_string="test is successful"
	if [ -z "${nginx_config_test##*$test_string*}" ]; then
		echo "    >>>> sudo systemctl restart nginx"
		sudo systemctl restart nginx
	else
		echo "\nSyntax error in Nginx configuration..."
		echo "$nginx_config_test"
	fi
fi

if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- ./Package.pins)" ]; then
	echo "\n>>>> vapor fetch --verbose"
	vapor fetch --verbose
fi

if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- ./Package.swift)" ]; then
	echo "\n>>>> vapor fetch --verbose"
	vapor fetch --verbose
fi

if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ]; then
	echo "\n>>>> vapor build --release=true --fetch=false --verbose"
	vapor build --release=true --fetch=false --verbose

	if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- tapcrated.service.txt)" ]; then
    	echo "    \n>>>> Detected changes in production server configuration files!"
		reset_production_server
	fi

	echo "\n>>>> sudo systemctl restart tapcrated.service"
	sudo systemctl restart tapcrated.service

	echo "\n>>>> sudo systemctl status tapcrated.service"
	sudo systemctl status tapcrated.service
else
	echo "\n>>>> vapor build --release=false --fetch=false --verbose"
	vapor build --release=false --fetch=false --verbose

	if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- dev-tapcrated.service.txt)" ]; then
    	echo "    \n>>>> Detected changes in development server configuration files!"
		reset_development_server
	fi

	echo "\n>>>> sudo systemctl restart dev-tapcrated.service"
	sudo systemctl restart dev-tapcrated.service

	echo "\n>>>> sudo systemctl status dev-tapcrated.service"
	sudo systemctl status dev-tapcrated.service
fi


