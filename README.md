# D2Stats

## Features
- Read character/mercenary stats
- Check difference in stats between 2 states (Click 'Read' to snapshot stats. After modifying stats, click 'Diff' to compare without changing the snapshot, or 'Diff and replace' to compare and then overwrite the snapshot)
- Set up rule list that check drops and notify the user when matching one drops
- Play sound notification when goblin appears

[Forum post](https://forum.median-xl.com/viewtopic.php?f=4&t=85654)

![D2Stats window screenshot](Assets/screenshot2.png "D2Stats window screenshot")
![D2Stats window screenshot](Assets/screenshot3.png "D2Stats window screenshot")
![D2Stats window screenshot](Assets/screenshot4.png "D2Stats window screenshot")
![D2Stats window screenshot](Assets/screenshot5.png "D2Stats notifier example")

## FAQ
### "Windows defender/Antivirus removes/quarantines the exe file. Is it a virus?"
`D2Stats.Core.exe` attaches to the `Game.exe` process and reads/writes memory so the overlay can work. Antivirus software often flags that behaviour. Add **`D2Stats.Core.exe`** to your exclusion list once — that file stays the same between updates.

Extract the full `D2Stats.zip` (both `D2Stats.exe` and `D2Stats.Core.exe`). Do not copy only `D2Stats.exe`. The zip itself may still be flagged because Core is inside it; after a one-time Core exclusion, updating `D2Stats.exe` should no longer get eaten.

Releases: https://github.com/azadix/D2Stats/releases

### "Why can't i hide items using D2Stats?"
Mod version 2.10 introduced in-game loot filtering system that disabled filtering using D2Stats. Current version only allows for notifying when certain item drops. All filters that still have `hide` and `show` keywords need to have them removed for notifier to function properly

### "Why does the notifier overlay look so ugly. Can i modify it eg change font style or background transparency/color?"
Not really. The current implementation is very unstable so i've decided on monospaced font (Courier New) that is guaranteed to be on every machine. The current version only allows for changing those properties:
  - Font size
  - X and Y offset (in pixels) from top-left edge of the window
  - Notification timeout duration (in milisecond)
If you really want to change some properties that were not exposed on the application UI you'll have to edit the main script code itself (`D2Stats.au3`) and recompile it using provided script (`Compile.bat`)
