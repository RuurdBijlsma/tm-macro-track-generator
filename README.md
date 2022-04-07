Generate random tracks by connecting macroblocks together. Use some of the many filters to customize your generated track, and make track parts yourself that the generator can use.

# Track generation

Tracks are generated using parts, which are effectively macroblocks with some extra information embedded in them, such as the entrance/exit speed, location and direction. 

## Generation options

* Use seed for preset randomness
* Track start block height
* Wood supports or air blocks
* Desired map duration in seconds
* Apply colors to blocks

## Filter options

* Tags that must be included in each part (ex. fullspeed, dirt, ice, nascar, plastic, bobsleigh)
* Tags that aren't allowed in any part
* Difficulty
* Must be respawnable yes/no
* Prevent parts from connecting to themselves
* Consider speed when connecting parts
* Maximum allowed speed difference when considering speed
* Maximum and minimum speed of a part
* Allow the generator to reuse parts for a track? yes / no / reduce reuse of parts
* Individual parts and sets of parts can also be disabled

# Part creation

With this plugin you can create parts the the generator can use for random track generator. Almost any macroblock will work as long as you indicate the correct entrance and exit information. There are some limitations about what can be used that is listed in the "Create parts" tab in the plugin.

This creation processed is also explained in game.

1. Create a part of a track, for example a road with 2 turns and a checkpoint
2. Click "Create a part" in the copy/paste UI
3. Select the blocks you want included
4. Click save macroblock
5. The plugin will clear the map temporarily and allow you to place the part in the map
6. Choose where the car will enter and exit your part
7. Give further information in the plugin window, such as entry/exit speed, part duration, part name, connector type (is also determined automatically, but this can be wrong), part type (start/finish/part, also determined automatically), tags, and part difficulty.
8. Click "Save part" and the generator will be able to use your part.

# Source code and reporting issues

https://github.com/RuurdBijlsma/tm-macro-track-generator 
