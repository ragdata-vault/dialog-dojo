#!/usr/bin/env bash

# ==================================================================
# install.sh
# ==================================================================
# Dialog Dojo Installer
#
# File:         install.sh
# Author:       Ragdata
# Date:         12/09/2023
# License:      MIT License
# Copyright:    Copyright © 2023 Darren (Ragdata) Poulton
# ==================================================================
# PREFLIGHT
# ==================================================================
# set debug mode = false
declare -gx INSTALL_DEBUG=0
# if script is called with 'debug' as an argument, then set debug mode
if [[ "${1,,}" == "debug" ]]; then shift; INSTALL_DEBUG=1; set -- "${@}"; set -axeET; else set -aeET; fi
# check git is installed
if ! command -v git &> /dev/null; then
	echo "Installing Missing Dependency: Git"
	apt install -y git || exit 1
fi
# check dialog is installed
if ! command -v dialog &> /dev/null; then
	echo "Installing Missing Dependency: Dialog"
	apt install -y dialog || exit 1
fi
# ==================================================================
# VARIABLES
# ==================================================================
#
# PACKAGE VERSION
#
declare -gx INSTALL_VERSION="0.1.0"
declare -gx INSTALL_BUILD="1001"
declare -gx INSTALL_BUILD_DATE="20230818:0426"
#
# ANSI VARIABLES
#
declare -gx ANSI_ESC=$'\033'
declare -gx ANSI_CSI="${ANSI_ESC}["
#
# COLOR VARIABLES
#
declare -gx RED="$(printf '%s31m' "$ANSI_CSI")"
declare -gx BLUE="$(printf '%s94m' "$ANSI_CSI")"
declare -gx GREEN="$(printf '%s32m' "$ANSI_CSI")"
declare -gx GOLD="$(printf '%s33m' "$ANSI_CSI")"
declare -gx WHITE="$(printf '%s97m' "$ANSI_CSI")"
declare -gx RESET="$(printf '%s0m' "$ANSI_CSI")"
#
# SYMBOLS
#
[[ -z "${SYMBOL_ERROR}" ]] && declare -gx SYMBOL_ERROR="🚫"
[[ -z "${SYMBOL_WARNING}" ]] && declare -gx SYMBOL_WARNING="⚠️"
[[ -z "${SYMBOL_INFO}" ]] && declare -gx SYMBOL_INFO="ℹ️"
[[ -z "${SYMBOL_SUCCESS}" ]] && declare -gx SYMBOL_SUCCESS="✅"
# ==================================================================
# FUNCTIONS
# ==================================================================
# ------------------------------------------------------------------
# checkBash
# ------------------------------------------------------------------
# ------------------------------------------------------------------
checkBash() { if [[ "${BASH_VERSION:0:1}" -lt 4 ]]; then errorReturn "This script requires a minimum Bash version of 4+"; fi; }
# ------------------------------------------------------------------
# checkDeps
# ------------------------------------------------------------------
# @description Checks whether dependencencies listed in arg array are installed on the current system
# ------------------------------------------------------------------
checkDeps()
{
	local i

    [[ $# -eq 0 ]] && return
    [[ ! $(is::array "$1") ]] && errorReturn "'$1' Not an Array!" 1

    local -n TOOLS="$1"
    for i in "${!TOOLS[@]}"
    do
        if ! command -v "${TOOLS[$i]}" &> /dev/null; then
            errorReturn "ERROR :: Command '${TOOLS[$i]}' Not Found!" 1
        fi
    done
}
# ------------------------------------------------------------------
# checkRoot
# ------------------------------------------------------------------
# ------------------------------------------------------------------
checkRoot() { if [[ "$EUID" -ne 0 ]]; then errorReturn "This script MUST be run as root!"; fi; }
# ------------------------------------------------------------------
# echoAlias
# ------------------------------------------------------------------
# @description Master alias function for `echo` command
#
# @arg  $1			[string]        String to be rendered
# @arg  -c="$VAR"   [option]        Color alias as defined above 				(required)
# @arg  -p='string' [option]        String to prefix to $1 						(optional)
# @arg  -s='string' [option]        String to suffix to $1 						(optional)
# @arg  -e          [option]        Enable escape codes 						(optional)
# @arg  -n          [option]        Disable newline at end of rendered string 	(optional)
#
# @exitcode     0   Success
# @exitcode     1   Failure
# @exitcode     2   ERROR - Requires Argument
# @exitcode     3   ERROR - Invalid Argument
# ------------------------------------------------------------------
install::echoAlias()
{
    local msg="${1:-}"
    local COLOR=""
    local OUTPUT=""
    local PREFIX=""
    local SUFFIX=""
    local _0=""
    local STREAM=1
    local -a OUTARGS

    shift

    [[ -z "$msg" ]] && { echo "${RED}${SYMBOL_ERROR} ERROR :: install::echoAlias :: Requires Argument!${RESET}"; return 2; }

    options=$(getopt -l "color:,prefix:,suffix:,escape,noline" -o "c:p:s:en" -a -- "$@")

    eval set --"$options"

    while true
    do
        case "$1" in
            -c|--color)
                COLOR="$2"
                shift 2
                ;;
            -p|--prefix)
                PREFIX="$2"
                shift 2
                ;;
            -s|--suffix)
                SUFFIX="$2"
                shift 2
                ;;
            -e|--escape)
                OUTARGS+=("-e")
                shift
                ;;
            -n|--noline)
                OUTARGS+=("-n")
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "${RED}ERROR :: echoAlias ::Invalid Argument '$1'!${RESET}"
                return 1
                ;;
        esac
    done

    [[ -n "$COLOR" ]] && _0="${RESET}" || _0=""

    OUTPUT="${COLOR}${PREFIX}${msg}${SUFFIX}${_0}"

    [[ "$STREAM" -eq 2 ]] && echo "${OUTARGS[@]}" "${OUTPUT}" >&2 || echo "${OUTARGS[@]}" "${OUTPUT}"

#    return 0
}
#
# COLOUR ALIASES
#
echoRed() { install::echoAlias "$1" -c "${RED}" "${@:2}"; }
echoBlue() { install::echoAlias "$1" -c "${BLUE}" "${@:2}"; }
echoGreen() { install::echoAlias "$1" -c "${GREEN}" "${@:2}"; }
echoGold() { install::echoAlias "$1" -c "${GOLD}" "${@:2}"; }
echoWhite() { install::echoAlias "$1" -c "${WHITE}" "${@:2}"; }
#
# MESSAGE ALIASES
#
echoError() { install::echoAlias "$SYMBOL_ERROR $1" -e -c "${RED}" "${@:2}"; }
echoWarning() { install::echoAlias "$SYMBOL_WARNING $1" -e -c "${GOLD}" "${@:2}"; }
echoInfo() { install::echoAlias "$SYMBOL_INFO $1" -c "${BLUE}" "${@:2}"; }
echoSuccess() { install::echoAlias "$SYMBOL_SUCCESS $1" -c "${GREEN}" "${@:2}"; }
errorReturn() { echoError "$1"; return "${2:-1}"; }
#
# EXIT ALIASES
#
exitReturn() { local r="${1:-0}"; [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return "$r" || exit "$r"; }
errorExitReturn() { echoError "$1"; exitReturn "${2:-1}"; }
# ------------------------------------------------------------------
# scriptPath
# ------------------------------------------------------------------
# @description Determine the calling script's current path
#
# @noargs
#
# @stdout The calling script's current path
# ------------------------------------------------------------------
scriptPath() { printf '%s' "$(realpath "${BASH_SOURCE[0]}")"; }
# ------------------------------------------------------------------
# scriptDir
# ------------------------------------------------------------------
# @description Determine the calling script's current directory
#
# @noargs
#
# @stdout The calling script's current directory
# ------------------------------------------------------------------
scriptDir() { printf '%s' "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"; }
# ------------------------------------------------------------------
# install::install
# ------------------------------------------------------------------
install::install()
{
	local
}
# ------------------------------------------------------------------
# install::uninstall
# ------------------------------------------------------------------
install::uninstall()
{
	local
}
# ------------------------------------------------------------------
# install::upgrade
# ------------------------------------------------------------------
install::upgrade()
{
	local
}
# ------------------------------------------------------------------
# install::returnQuit
# ------------------------------------------------------------------
install::returnQuit()
{
    echo
    echoSuccess "DONE!"
    echoSuccess "Do you want to (R)eturn to the Menu, or (Q)uit? (R/${GOLD}Q${RESET}) " -n
    while [[ ! "${RESP,,}" =~ [rq] ]]
    do
        read -r -n 1 RESP
        [[ -z "$RESP" ]] && RESP="Q"
    done
    echo

    case "${RESP,,}" in
        r)
            unset INST
            unset RESP
            install::menu
            ;;
        q)
            install::quit
            ;;
    esac
}
# ------------------------------------------------------------------
# install::quit
# ------------------------------------------------------------------
install::quit()
{
    echo
    echoGold "Program terminated at user request"
    echo

    tput cnorm

    exit 0
}
# ------------------------------------------------------------------
# install::version
# ------------------------------------------------------------------
# @description Reports the version and build date of this release
#
# @noargs
#
# @stdout Version, Copyright, & Build Information
# ------------------------------------------------------------------
install::version()
{
	local verbosity="${1:-}"

	if [[ -z "$verbosity" ]]; then
		echo "${INSTALL_VERSION}"
	else
		echo
		echo "Dialog Dojo Installer"
		echoWhite "Dialog Dojo Installer ${INSTALL_VERSION}"
		echo "Copyright © 2022-2023 Darren (Ragdata) Poulton"
		echo "Build: ${INSTALL_BUILD}"
		echo "Build Date: ${INSTALL_BUILD_DATE}"
		echo
	fi
}
# ------------------------------------------------------------------
# install::menu
# ------------------------------------------------------------------
install::menu()
{
	local option status

	option=$(dialog --title "INSTALLER MENU" --backtitle "DIALOG DOJO INSTALLER" --clear --default-item "1" --menu "Select from the following options:" 15 50 5 \
					  "Install" "" \
					  "Uninstall" "" \
					  "Update" "" \
					  "About" "" \
					  "Quit" "" 3>&1 1>&2 2>&3)

	status=$?

	if [[ "$status" = 0 ]]; then
		case "$option" in
			"Install") install::install;;
			"Uninstall") install::uninstall;;
			"Update") install::update;;
			"About") install::version verbose;;
			"Quit") install::quit;;
		esac
	fi
}
# ==================================================================
# MAIN
# ==================================================================
checkBash
checkRoot

options=$(getopt -l "version::" -o "v::" -a -- "$@")

eval set --"$options"

while true
do
	case "$1" in
		-v|--version)
			if [[ -n "${2}" ]]; then
				install::version "${2}"
				shift 2
			else
				install::version
				shift
			fi
			exit 0
			;;
		--)
			shift
			tput civis

			install::menu

			tput cnorm
			break
			;;
		*)
			echoError "Invalid Argument!"
			exit 2
			;;
	esac
done



