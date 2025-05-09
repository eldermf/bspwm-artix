#!/usr/bin/env bash

# Add this script to your wm startup file.

DIR="$HOME/.config/polybar/grayblocks"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Obtém as saídas ativas do xrandr
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

# Inicia o Polybar para cada monitor
for m in $MONITORS; do
    MONITOR=$m polybar -q main -c "$DIR"/config.ini &
done
