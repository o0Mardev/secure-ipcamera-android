#!/bin/sh
#Start IP camera application
su -c am start -n com.pas.webcam/.Rolling

#To turn off display and consume less battery
sleep 3
su -c /system/bin/input keyevent 26
