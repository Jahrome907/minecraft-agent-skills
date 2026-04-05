# Execute Cheat Sheet (1.21.x)

## Fast Patterns

```mcfunction
# each player at their own position
execute as @a at @s run <command>

# dimension hop
execute in minecraft:the_nether run <command>

# conditional block check
execute if block ~ ~-1 ~ minecraft:gold_block run <command>

# conditional score check
execute if score @s points matches 10.. run <command>

# store command result into a score
execute store result score @s result run data get entity @s Health

# use local coordinates from eyes
execute anchored eyes positioned ^ ^ ^1 run <command>
```

## Reliable Ordering

1. Pick executor with `as`
2. Pick position with `at` or `positioned`
3. Add conditions with `if` / `unless`
4. Add `store` only when you need a side effect
5. End with one `run`

## Common Fixes

- If particles or sounds appear in the wrong place, you probably forgot `at @s`
- If selectors seem right but commands affect only one player, check for `limit=1`
- If stored scores are always `0`, check whether you needed `store success` instead of `store result`
