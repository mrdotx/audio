#!/bin/sh

# path:       /home/klassiker/.local/share/repos/audio/audio.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/audio
# date:       2020-09-16T09:48:28+0200

script=$(basename "$0")
help="$script [-h/--help] -- script to change audio output
  Usage:
    $script [-tog/-inc/-dec/-mute] [percent]

  Settings:
    [-tog]    = toggle output from analog to hdmi stereo
    [-mute]   = mute volume
    [-inc]    = increase in percent (0-100)
    [-dec]    = decrease in percent (0-100)
    [percent] = how much percent to increase/decrease the brightness

  Examples:
    $script -tog
    $script -mute
    $script -inc 10
    $script -dec 10"

# use pulseaudio (1) or alsa (0)
pulse=0

[ $pulse = 1 ] \
    && pacmd_sink=$(pacmd list-sinks \
    | grep "index:" \
    | awk -F ': ' '{print $2}' \
)

pulseaudio() {
    pacmd_name=$(pacmd list-cards \
        | grep "active profile:" \
        | awk -F ': ' '{print $2}' \
    )
    if [ "$pacmd_name" = "<output:analog-stereo+input:analog-stereo>" ] \
            || [ "$pacmd_name" = "<output:analog-stereo>" ]; then
        pacmd set-card-profile 0 "output:hdmi-stereo-extra1"
        pactl set-sink-volume $((pacmd_sink+2)) 100%
    else
        pacmd set-card-profile 0 "output:analog-stereo+input:analog-stereo"
        pactl set-sink-volume $((pacmd_sink+2)) 25%
    fi
}

alsa() {
    alsadevice() {
        printf "defaults.pcm.!type hw\n" > "$HOME/.asoundrc"
        printf "defaults.pcm.!card 0\n" >> "$HOME/.asoundrc"
        printf "defaults.pcm.!device %s" "$1" >> "$HOME/.asoundrc"
    }

    if grep -q -s "defaults.pcm.!device 7" "$HOME/.asoundrc"; then
        alsadevice 0
    else
        alsadevice 7
    fi
}

volume() {
    if [ "$2" -ge 0 ] && [ "$2" -le 100 ]; then
        [ $pulse = 1 ] && pactl set-sink-volume "$pacmd_sink" "$1$2%"
        [ $pulse = 0 ] && amixer -q set Master "$2%$1"
    else
        printf "%s\n" "$help"
        exit 1
    fi
}

case "$1" in
    -h | --help)
        printf "%s\n" "$help"
        ;;
    -tog)
        [ $pulse = 1 ] && pulseaudio
        [ $pulse = 0 ] && alsa
        ;;
    -mute)
        [ $pulse = 1 ] && pactl set-sink-mute "$pacmd_sink" toggle
        [ $pulse = 0 ] && amixer -q set Master toggle
        ;;
    -inc)
        volume "+" "$2"
        ;;
    -dec)
        volume "-" "$2"
        ;;
    *)
        printf "%s\n" "$help"
        exit 1
        ;;
esac
