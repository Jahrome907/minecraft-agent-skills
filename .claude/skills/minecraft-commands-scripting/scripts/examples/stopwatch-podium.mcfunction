scoreboard objectives add lap_time dummy

execute as @a[tag=race_finished] unless score @s lap_time matches ..0 run tellraw @s {"text":"Submit your time before running podium logic.","color":"red"}
execute if entity @a[tag=race_finished,scores={lap_time=1..}] run function mypack:race/sort_results

tellraw @a [
  "",
  {"text":"[Race] ","color":"gold"},
  {"text":"Current podium: ","color":"yellow"},
  {"selector":"@a[tag=podium_first,limit=1]","color":"green"},
  {"text":" / ","color":"gray"},
  {"selector":"@a[tag=podium_second,limit=1]","color":"white"},
  {"text":" / ","color":"gray"},
  {"selector":"@a[tag=podium_third,limit=1]","color":"red"}
]