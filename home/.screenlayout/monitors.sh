#!/bin/sh
xrandr --output DisplayPort-0 --off 
xrandr --output DisplayPort-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --rate 144
xrandr --output DisplayPort-2 --off 
xrandr --output HDMI-A-0 --off 
xrandr --output DVI-D-0 --mode 1360x768 --pos 1920x0 --rotate normal --rate 60
