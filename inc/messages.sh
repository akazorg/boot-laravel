#!/bin/bash

#
# Provides colourful messages for states (alert, error, success)
#

# Colour Variables
_rev=$(tput rev)
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

#############
# Functions #
#############
_error() {
    printf "${_red}✖ Error $1${_reset}\n\n"
}
_alert() {
    printf "${_rev}${_red}$1 ❗${_reset}\n"
}
_success() {
    printf "${_green}✔ $1${_reset}\n" "$@"
}
