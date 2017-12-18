# iDestyKK's AMX Mod X Plugins

## About
There isn't much here.
But I've decided to put up the source code of plugins that I wrote myself on GitHub.
These are for AMX Mod X, a versatile Half-Life metamod plugin which is targetted toward server administration (stole that directly off of [this page](http://www.amxmodx.org/about.php)).

The main reason why I decided to upload these is because I upload clips on YouTube of Half-Life gameplay where I use these plugins.
So if anyone is interested in the exact same plugins, I can just link them here.

## Plugins
### Instant Respawn
This one is pretty self-explanatory... you will respawn the instant you die.
This was mainly made to increase competition in servers by making the gameplay much more fast-paced.

It surprises me that there was no Instant Respawn mod on AMX Mod X's website for Half-Life. Oh well.

### Killstreak Mechanism
New to the plugin list is the Killstreak mod.
This one is heavily inspired by Call of Duty: Modern Warfare 2, but is a bit more strict.
* It doesn't store streaks in a queue.
  * This means that you will lose your previous streak if you don't use it before earning another!
* You lose your streak (and any current ones running) the moment you die.
* These streaks clearly are not as destructive as the ones in Modern Warfare 2 (for obvious reasons).

It adds a custom command `ks_use`, which you need to bind to a key of your choice via `bind "KEY" "ks_use"`.
That command will handle all of the processing of killstreak information.
So if you have a killstreak, it will use it. If you don't, it will whine at you about it.

The current killstreaks in this mod are:
* **3 Kills** - Full Health
* **5 Kills** - Health Regeneration (Slow)
* **7 Kills** - Airstrike (Whatever you are looking at will instantly explode)
* **9 Kills** - Double Damage (for 30 seconds)
* **11 Kills** - Health Regeneration (Fast)
* **15 Kills** - Quad Damage (for 30 seconds)
* **25 Kills** - Nuke (Game Ender)

As I said, not too exciting, but it's to show that it can be done in a 1998 game. ;)

## So can I use them?
It's on GitHub, of course I'm not going to stop you from downloading it...
The instant respawn mod is way too simple for me to take credit. I'm not that much of a bitch.
However, if you want to use mods like the Killstreak mod, I would like to be credited for it.
It's unique (I think), and I actually took time out of my day to make it. Thank you for understanding. :)
