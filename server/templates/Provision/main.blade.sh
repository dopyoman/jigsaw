#!/usr/bin/env bash

@include('Provision._variables')

sudo sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf

@include('Provision._apt')

@include('Provision.packages._base')

@include('Provision.packages._httpie')

@include('Provision.setup._ssh')

@include('Provision.setup._hostname')

@include('Provision.setup._timezone')

@include('Provision.setup._user')

@include('Provision._forgeEnv')

@include('Provision.setup._firewall')

@include('Provision.php._setup')

@include('Provision.php._composer')

@include('Provision.php._configurations')

@include('Provision.nginx._setup')

@include('Provision.nginx._fastcgi')

@include('Provision.nginx._disableDefault')

@include('Provision.nginx._catchall')

@include('Provision.php._fpmSettings')

@include('Provision.php._restart')

@include('Provision.nginx._restart')

# Add User To www-data Group

usermod -a -G www-data ${sudo_user}
id ${sudo_user}
groups ${sudo_user}

@include('Provision.node._setup')

@include('Provision.DB._mariaSetup')

@include('Provision.DB._postgresSetup')

@include('Provision.DB._redis')

@include('Provision.DB._beanstalk')

@include('Provision.packages._backfire')

@include('Provision.packages._mailhog')

@include('Provision.setup._supervisor')

@include('Provision.setup._autoUpgrades')

