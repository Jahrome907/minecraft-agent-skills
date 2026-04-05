scoreboard objectives add arena_timer dummy
scoreboard players add #arena arena_timer 1

execute if score #arena arena_timer matches 20 run title @a[tag=arena_player] actionbar {"text":"3","color":"gold"}
execute if score #arena arena_timer matches 40 run title @a[tag=arena_player] actionbar {"text":"2","color":"gold"}
execute if score #arena arena_timer matches 60 run title @a[tag=arena_player] actionbar {"text":"1","color":"gold"}
execute if score #arena arena_timer matches 80 run function mypack:arena/start_round