# gmod_addons / SplatoonSWEPs!
This is the huge rework of my existing addon, [SplatoonSWEPs][1].  
Commit messages are all Japanese.

The aim of this rework is the following:
* Working fine on multiplayer game (especially on dedicated servers)
* More flesh than before! (not just throwing props)
* Better UI

***  
## Done
* A new ink system  
    ... but it should be updated for upcoming features
* Inkling base system.  
    You can become inkling as well.
* Basic GUI to change playermodel, ink color, and other settings.  
    GUI menu is in the context menu.
* All Shooters in Splatoon (WiiU)
* Splat charger and its variations in Splatoon.
* E-liter 3K and its variations in Splatoon.

## Currently working on
* Chargers
    * [x] Create a base class
    * [x] Write a charging script
    * [x] Draw a crosshair
    * [x] Draw a laser sight
    * [x] Write a script to fire the actual ink
    * [x] Set an ink consumption and other parameters
          Squiffers and Bamboozlers are remaining.
    * [x] Write a script for scoped chargers
* More effects!
    * [x] Create muzzle effects (cone-shaped, ring, and mist, for shooters and chargers)
    * [x] Use Source particle system (.pcf file) to emit muzzle effect
    * [x] Create ink effects when it's going to paint the world.
* Weapon models  
    SWEP Construction Kit can't draw the shadow of the SWEPs.  
    So I decided to make viewmodels and worldmodels from [Splatoon Full Weapons Pack.][2]  
    You can view the created SMDs and QCs on [DropBox][3]

## Upcoming features
* Sub weapons
* Blasters
* Spinners
* Rollers
* Inkbrushes
* Sloshers

## I want to make the following, too
* Special weapons in Splatoon and Splatoon 2
* Dualies, Brellas and some Splatoon 2 features.
* Gears and gear abilities

[1]:https://steamcommunity.com/sharedfiles/filedetails/?id=746789974
[2]:https://steamcommunity.com/workshop/filedetails/?id=688236142
[3]:https://www.dropbox.com/sh/c5srxjs38guatmv/AAAsvB8Y-k4KfyNZ4Y_WFEo9a?dl=0
