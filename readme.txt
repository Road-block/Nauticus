Nauticus v2.0

http://ui.worldofwar.net/ui.php?id=2790
 or
http://wow.curse-gaming.com/en/files/details/5089/zeppelinmaster/
 or
http://www.wowinterface.com/downloads/fileinfo.php?id=5123

---
Nauticus (the addon formally known as ZeppelinMaster) is able to track 
the precise location of Ships and Zeppelins at any moment in time. 
Currently, it shows arrival and departure times. In future revisions, 
the aim is to show each vessel on the world/mini map in real-time.

IMPORTANT! If you're upgrading from ZeppelinMaster, please remember to 
DELETE your old folders (specifically ZepShipMaster, FuBar_ZepMasterFu 
and TitanZeppelinMaster) before you extract this package. Also, you may 
/leave ZeppelinMaster once in game for each of your characters.

To track a transport requires that you (or someone else running this 
addon on the same server as you) have taken the route sometime earlier 
that day. Nauticus uses a sync channel to share transit information 
between players.

/nauticus or /naut - Shows GUI (GUI can also be opened any time you 
enter a zone with a transport in it)
/naut reset - Resets all known transport data
/naut channel <channelname> - Set custom sync channel if you don't want 
to use the default 'NauticSync'

---
The original author of ZeppelinMaster is Sammysnake - he runs a DKP 
hosting service online, please support his work @ www.dkphosting.net:
Dedicated to DKP Hosting for guilds from such games as World of 
Warcraft, Everquest, Everquest II and Dark Age of Camelot. 'We offer 
this service to alleviate the headache associated with setting up and 
configuring these scripts & databases. Absolutely no PHP/MySQL knowledge 
is required to host your DKP with us, full support is provided.'

---
Changelog

v2.0.0
- IMPORTANT: in the name of biaslessness (is that a word?), the addon's 
name has been changed to *Nauticus*! you should DELETE your old 
ZeppelinMaster folders (ZepShipMaster, FuBar_ZepMasterFu and 
TitanZeppelinMaster) before you extract this package!
- fixed some bizarrely wrong round-trip-times made in the last update
- re-calibrated each route to provide vastly more accurate 
platform-to-platform and docking times (may need a few more tweaks but 
it's very very close now)
- main ui visibility settings (shown/minimised) now saved per character
- cycle time algorithm improvement yet again - is about as efficient as 
it can possibly ever be now (i.e. very)
- NEW: route added - Feathermoon Stronghold (Sardor Isle) to The 
Forgotten Coast (Feralas)
- NEW: route added - Azuremyst Isle (The Exodar) to Auberdine


v1.94
- major code cleanup. note: settings will be reset to defaults (except 
Titan and Fu). removed all globals. removed all remaining non-language 
code from localisation files - if anyone can help with translations for 
fr, es and any other locales, please contact me (german and korea 
locales also incomplete)
- MapLibrary's IsInInstance check was broken, now using Blizz's new(ish) 
api call. this also fixes performance issues in instances if using 
AlphaMap (thanks to Telic the author for working with me on this). also 
an extra check is made if AlphaMap's frame is visible, to stop forcing 
map zoom when getting coords. please note: transit coords may not 
trigger if you're browsing the world map (or AlphaMap or MetaMap etc.) 
at the moment of trigger - especially when you're looking at another 
continent
- now detects if player is (not) swimming, so as not to trigger transit 
coords (rare but was possible)
- improvement to main ui window:
 - options dialog now anchored to centre of screen by default instead 
of main window
 - uses proper widgets, bigger, better
 - minimises into much smaller bar with new icon
 - NEW: if window is moved to bottom half of screen, the main body is 
'flipped' above the title bar, making better space for when minimised
- fix word wrap in Titan tooltip hint text (was too long)
- cycle times have been re-calibrated (only the full round-trip lengths 
for now). over a long period without sync from other players, times 
should drift apart significantly less so. next revision (for TBC) will 
see a) precise platform-to-platform and accurate docking times, b) 
better positioned trigger coords and c) internally, ZM will know the 
precise transport coords at any moment in time (for later use, see below)
- yet more optimisations to the cycle time algorithm. in future, the 
algorithm will be efficient enough to potentially show times for all 
routes at the same time (though, the plan is to show an icon for each 
vessel on the world map, plus on the minimap for the current zone a la 
Gatherer with tooltips).


v1.93
- fixes some routes not triggering properly when using MapLibrary and 
player position not visible on map i.e. far out to sea
- fix error after login when using detached FuBar tooltips
- corrected english non-alias name for wetlands (was menethil) <==> to 
dustwallow route
- checks player position less frequently now
- sync protocol slightly different - most sync data is the same, but 
triggered routes won't be sent between versions prior to 1.93. get your 
friends to update! this was to remove hardcoded values, making it easier 
to re-calibrate the times in a (very near) future update. data is also 
much less spammy when players login (you won't notice it, but always 
good on resources)
- NEW Titan/FuBar feature: Alt-click on button to set up a one-time-only 
audio (trumpet) alarm 20 seconds (will make it configurable in next 
version) from departure and a 'ding ding' at zero



v1.92a
- fixed stack overflow bug in MapLibrary when exiting bg if battlefield 
map shown
- when not using the MapLibrary optional dependency, logging into WoW 
directly inside an instance would give an error (however i highly 
recommend you keep using MapLibrary with ZM!)


v1.92
- major performance improvement: finally fixed the long-standing memory 
consumption issue, using new data structures. increasing rate reduced 
from ~60Kb/s when active transport selected to less than 0.1Kb (normal 
background radiation levels basically)


v1.91
- NEW FuBar plugin!
- compacted main ui options dialog
- merged duplicated transport coord data from several localisation 
files, improving memory usage and startup times a bit
- stopped main ui text needlessly being updated every few frames and 
some unnecessary calcs when no transport selected / no times avail.. 
(should now use practically zilch resources when no transport selected, 
except for when sync'ing)
- many many optimisations to the cycle time calculation, removing some 
unnecessary code
- Titan code revamp
 - moved artwork from Titan to main core folder for sharing with FuBar 
plugin (please delete old folders before upgrading)
 - muchos performance increase: removed expensive (and duplicated) 
cycle time calculations for both tooltip and button text, takes 
pre-calc'd info from main core instead
 - fixed rare bug when sometimes showing tooltip for first time?
 - fixed city alias option not working for platform names in tooltip
 - added hint, much better formatted and coloured tooltip


v1.90 (new maintainer Drool)
- fixes for lua 5.1 code changes (patch 2.0)
- optional dependency MapLibrary (slightly modified with patch 2.0 
fixes) included
- suppress chat spam when logging on / retrieving sync data
- fixes issue where player could only update own times for each 
transport once per session(!)
- significant performance improvements:
 - only polls transport exit coords when player is moving and not in an 
instance
 - faster and more accurate proximity check algorithm
 - player location polling: uses MapLibrary to get coords, without 
needing to zoom the map and subsequently generating tonnes of 
WORLD_MAP_UPDATE events, several every frame(!)
- Titan support: fixed UIDropDownMenu error, added version number, 
rearranged menu


v1.86
- fix for some popup errors (maybe)
- fix for data being reset because bugged timestamp
- stopped gui from showing on zone by default (amazing how many people 
couldn't find the options)


v1.83
- possible fix for Too many buttons in UIDropDownMenu
(not sure if fixed 100%)


v1.82
- bugfix: Loading error that occured if you didn't have titan panel 
installed
- Titan: Icons replaced words Arrival(green arrow) +Departure (red arrow)
- Popup Error Fix


v1.8
- Better data sharing
- Support for titanbars (You need ZeppelinMaster base addon for titanbar 
portion to work)


v1.74
- Popup error fix
- Fix for data being reset between sessions
- Timestamps fix


v1.7
- Timestamps fix


v1.5-v1.61
- GUI improvements
- Options Panel
- Coordinates fix for Titan
- fix for v1.6, dropdown list wasn't working properly


v1.4
- New improved syncronization and proper aging of data
- Metamap fix


v1.3 - Popup Error Fix
v1.2 - Better syncing functions
v1.1 - Channel fix + Ship tracking
v1.0 - Initial Release


---
The End
