# OpenComputers-LiteOS

NOTE: This OS is in heavy development and shouldn't be used in production

# Install
- Clone this repositiory using `git clone --recursive https://github.com/oc-liteos/Opencomputers-LiteOS.git`
- Run `python3 scripts/build.py`. You need Linux for that!
- Copy contents of build directory to an opencomputers hard hard drive
- Put an Lua EEPROM into the computer and run it. it should flash the needed bios image and reboot after a short period of time 
- Login using root and 1234 (you won't see the password but there should appear asterisks)

# Requirements (Currently not tested by os)
 - Screen Tier 2 or higher
 - Memory Tier 2 or higher (tested on 1024M and higher)
 - Datacard Tier 1 or higher
 - GPU Tier 2 or Higher
 - CPU Tier 2 or Higher
 - Hard Disk Tier 2 or Higher

# Implemented Componentes
* [x] filesystem
* [ ] data
* [ ] drive (unmanaged hdd)
* [x] gpu
* [ ] eeprom
* [ ] internet
* [ ] modem
* [ ] (net splitter)
* [ ] (robot)
* [ ] (debug)
* [ ] screen

