## import functions
put this in yoru fxmanifest.lua to use those functions, also recommended dependencies it
```
shared_scripts{
    '@nb-stats/import.lua'
}

dependencies {
    'nb-stats',
    ...
}

```

## server functions
```
RemovePlayerStat(player,type,amount,cb,reason)
AddPlayerStat(player,type,amount,cb,reason)
SetPlayerStat(player,type,amount,cb,reason)
GetStatsLog(player,cb)
GetPlayerStats(player,cb)

```

## client functions
```
UpdatePlayerStats()
GetPlayerStat(stat, type)
SetPlayerStat(stat, amount)
```

## configs 
```
config.LoadGamebaseStats -- will load the game base stats into sql and game-system. Will show only these if you turn UI="gamebase"
config.UI -- "gamebase" / "custom" / "mix" / other = not show UI 
config.customUISlots -- force slots only show these stats 
config.slotsColor -- slots color (hud-colors https://docs.fivem.net/docs/game-references/hud-colors/)
config.maxpages 
config.pagefliptimer
```


## Stats settings 
In folder data/gamebase.csv we can add more gamebase stats 
In folder data/stats.csv we can add more gamebase stats 
with example:
```
stat,type,min,max
luck1,int,0,100
luck2,int,0,100
luck3,int,0,1000
luck4,int,0,100
luck5,int,0,100
luck6,int,0,100
luck7,int,0,100
luck8,int,0,100
luck9,int,0,100
luck10,int,0,100
luck11,int,0,100
```
