# PicoStatusLight
A status light that doesn't suck or cost $60

# IN PROGRESS
This repo is not finished yet. If ya wanna use any of this right now you'll have to figure it out yourself.

# Hardware Needed
Raspberry Pi Pico W (with headers)

Pimoroni Pico DisplayPack 2.0 

A micro-USB cable that does data (some just do power and will not work)

# Setup
Project uses Pimoroni's custom firmware for the Pico W: https://github.com/pimoroni/pimoroni-pico/releases

Control Scripts must be edited to contain your Pico's IP 

# Configuring the Pico
WIP

# Pico Code:
Main.py (How to edit: WIP)

secrets.py (change these values to your network SSID and Password) 

# Control Code
Powershell app: (how to edit: WIP)

python scripts for http GET over specific network interface (useful if you use a VPN but still want to control this over your local network cause Windows is TRASH and doesn't let you do this with powershell) 


# Control from anywhere on your local network!
Any device that can send an HTTP GET request can use this setup - however some devices make this super annoying (cough Windows cough) so here is how I set it up on my devices:

Windows computer (with VPN): powershell app that detects if zoom is running automatically, allows manual control, calls python scripts for actual http GET requests to specify network interface to send on local network instead of over VPN (hey Palo can you make your VPN not suck please?)

iPhone: shortcuts set to HTTP GET request that calls the specific control URL for the mode needed

android: any automation program should allow you to do the same as above for ios

MacOS: no idea - I dont use Mac

Linux: you already know how to do this (i use Fedora btw) 
