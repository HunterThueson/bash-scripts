#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# Quick script to generate thumbnails from a given video to ~/.temp/

#############################
#  Set/unset shell options  #
#############################

if [[ ! "${BASHOPTS}" =~ "extglob" ]]; then
    shopt -s extglob
    EXTGLOB=0
else
    EXTGLOB=1
fi

###########################
#  Variable declarations  #
###########################

# generate a thumbnail every $frameskip frames
declare -i frameskip
frameskip=7

# thumbnail output directory
output_dir="$HOME/.temp"

###########################
#  Function declarations  #
###########################

# unset extglob if it wasn't set before running command
# NOTE: must be passed one argument to use as exit code

cleanup () {
    if [[ $EXTGLOB = 0 ]]; then
        shopt -u extglob
        exit $1
    else
        exit $1
    fi
};

fatal () {
    printf "$0: fatal: $*\n" >&2
    cleanup 1
}

# give the user one more chance to enter a valid answer
# takes one argument: the number of retries already given
bad_answer (){
    [[ $1 > 0 ]] && fatal could not understand user input
    printf "\nI couldn't understand your answer. Please enter yes or no: "
    read answer
    if [[ ! $answer = "" ]]; then
        return $answer
    else
        fatal could not understand user input
    fi
};

#####################
#  Check arguments  #
#####################

[[ $# < 1 ]] && fatal 'not enough arguments'

while [[ $1 != "" ]]; do
    case $1 in
        "-f"|"--frameskip") frameskip=$2; shift 2;;
        "-d"|"--output-dir") output_dir=${2%/}; shift 2;;
        (*) break;;
    esac
done

# TODO: Test that non-option arguments are files that exist and are *.mp4

# TODO: Test that variable following '-f' is an int

intermediate_filename=${1##*/}
filename=${intermediate_filename%%.*}

retries=0

##########################################
#  Create output directory if necessary  #
##########################################

if [[ ! -d $output_dir ]]; then
    printf "Output directory $output_dir does not exist.\n"
    printf "Do you want to create it? (y/N): "; read answer
    while [[ ! $answer = "" ]]; do
        case $answer in
            ("y"/"Y"/"yes"/"YES") mkdir $output_dir && \
                printf "\nCreated output directory: $output_dir\n"; break;;
            ("n"/"N"/"no"/"NO") printf "Aborting...\n"; cleanup 1;;
            (*) bad_answer $retries; answer=$?; retries=1;;
        esac
    done
fi

#########################
#  Generate thumbnails  #
#########################

if [[ ( $frameskip = 0 || $frameskip = 1 ) ]]; then
    ffmpeg -hide_banner -i $1 -f image2 $output_dir/nail_$filename-%04d.png
else
    ffmpeg -hide_banner -i $1 -vf "select='not(mod(n,$frameskip))',setpts='N/(30*TB)'" -f image2 $output_dir/nail_$filename-%04d.png
fi

#####################
#  Exit gracefully  #
#####################

cleanup 0