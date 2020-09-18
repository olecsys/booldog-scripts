#!/usr/bin/env bash
#pkill -x omxplayer.bin
if ! pgrep -x omxplayer.bin >/dev/null; then
  omxplayer -o hdmi --loop /home/pi/BigBuckBunny.mp4 &
fi
