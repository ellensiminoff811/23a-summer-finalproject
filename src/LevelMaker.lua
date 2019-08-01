--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    EFS - Added flags for keys and locks (#2)
    EFS - Added flags for flag and pole (#3)
    EFS - Added color combinations for flag and pole (#2)
    EFS - Added logic for key being taken (#2)
    EFS - Generate key and lock .  Unlock lock (collision from below) causing it to disappear. (#2)
    EFS - Once the lock has disappeared, triggered a goal post to spawn at the end of the level. (#3)
    EFS - Flag and pole added near each other as separate objects. (#3)
    EFS - When the player touches this goal post (flag), regenerate the level. (#4)
    EFS - After goal, spawn the player at the beginning of it again, make it longer than it was before.  (#4)

    EFS = for project
        - Music at the wedding
        - Storage for flags related to the ring and princess 
        - Flag so know when door to chapel is open or closed
        - Door locations are at the end of the level 
        - Add princess and ring
        - Put princess in correct direction
        - Spawn the chapel doors
        - Add invincibility timer


]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    -- EFS (project). music at the wedding
    gSounds['music']:play()
    gSounds['wedding']:stop()
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- EFS: Storage for flags related to the lock
    local hasPlacedKey = false
    local theKey = nil
    local hasPlacedLock = false
    local theLock = nil

    -- EFS: Storage for flags related to the ring and princess (project)
    local hasGivenRing = false
    local theRing = nil
    local hasFoundPrincess = false
    local thePrincess = nil

    -- EFS: Flag so know when block is going to get in the way
    local hasBlock = false

    -- EFS: Flag so know when flag and pole exist
    local theFlag = nil
    local thePole = nil

    -- EFS: Flag so know when door to chapel is open or closed
    local theDoorClosed = nil
    local theDoorOpen = nil

    -- EFS: Randomly choose a color but make sure in combo
    local frameKey = math.random(1,4)
    local frameLock = nil

    -- EFS: Door locations are at the end of the level 
    local theDoorClosedPositionX = width-7
    local theDoorClosedPositionY = 3

    --EFS: FrameKey and lock color combos   
    if frameKey == 1 then
        frameLock = 5
    elseif frameKey == 2 then
        frameLock = 6       
    elseif frameKey == 3 then
        frameLock = 7
    elseif frameKey == 4 then
        frameLock = 8
    end  

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        hasBlock = false
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness

        if math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end
            -- EFS: Add block flag
            -- chance to spawn a block
            if math.random(10) == 1 and theDoorClosedPositionX > x then
                hasBlock = true
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj, ignoredParam)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100


                                        end
                                    }
                                        
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )


            end

            -- EFS: added key and lock objects (#2)
            -- Key unlocks lock (#2)
            -- Flag is made actionable (#3)
            -- Flag/pole are at the end of the level (#3)
            if math.random(3) == 1 and not hasPlacedLock and hasPlacedKey and not hasBlock then
                hasPlacedLock = true
                theLock = GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE - 4,
                        width = 16,
                        height = 16,    
                        frame = frameLock,
                        collidable = true,
                        consumable = false,
                        solid = true,
                        
                         -- EFS: Collision with lock/only works if we have key (#2)
                        onCollide = function(object, player)
                            if (player == nil) then
                                return
                            end

                            if (player:hasItemWithId("Key One")) then

                                gSounds['pickup']:play()
                                player.score = player.score + 100

                                -- EFS: Spawn the finishing flag (#4)

                                theFlag.visible = true
                                theFlag.consumable = true
                                thePole.visible = true
                                thePole.consumable = true

                                theLock.solid = false
                                theLock.visible = false
                                theLock.collidable = false

                            end

                        end
                    }

     --         theLock.visible = true
                table.insert(objects, theLock)

            end 

             -- EFS: Get key (#2)
            if math.random(6) == 1 and not hasPlacedKey and not hasBlock then
                hasPlacedKey = true
                theKey = GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE - 4,
                        width = 16,
                        height = 16,
                        frame = frameKey,
                        collidable = false,
                        consumable = true,
                        solid = false,

                       -- EFS: Add to the player's score/call function so we know we hae kye
                        onConsume = function(player)
                            gSounds['pickup']:play()
                            player.score = player.score + 100

                            player:addInventoryItem({id="Key One"})

                        end
                    }
                

                table.insert(objects, theKey)
                
            end

            -- EFS add princess and ring
            -- Spawn the chapel doors
            -- Add invincibility timer

            if math.random(4) == 1 and not hasFoundPrincess and hasGivenRing and not hasBlock and hasPlacedLock and hasPlacedKey then
                hasFoundPrincess = true
                thePrincess = GameObject {
                        texture = 'peach',
                        x = x * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE - 4,
                        width = 16,
                        height = 20,    
                        frame = 1,
                        collidable = true,
                        consumable = false,
                        solid = true,
                        scalefactor = .45,
                        
                         -- EFS: Collision with princess/only works if we have ring 
                        onCollide = function(object, player)
                            if (player == nil) then
                                return
                            end

                            if (player:hasItemWithId("Ring One")) then

                                gSounds['pickup']:play()
                                player.score = player.score + 100
                                player.invincibleTimer = player.invincibleTimer + 10

                                -- EFS: Spawn the chapel

                                theDoorClosed.visible = true
                                theDoorClosed.consumable = true
                                theDoorOpen.visible = false
                                theDoorOpen.consumable = false

                                thePrincess.solid = false
                                thePrincess.visible = false
                                thePrincess.collidable = false

                            end


                        end
                    }

                thePrincess.visible = true
                table.insert(objects, thePrincess)

            end

              -- EFS: Get ring (project)
            if math.random(6) == 1 and not hasGivenRing and not hasBlock then
                hasGivenRing = true
                theRing = GameObject {
                        texture = 'rings',
                        x = x * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE - 4,
                        width = 16,
                        height = 16,
                        frame = math.random(#RINGS),
                        collidable = false,
                        consumable = true,
                        solid = false,
                        scalefactor = .05,

                       -- EFS: Add to the player's score/call function so we know we hae kye
                        onConsume = function(player)
                            gSounds['pickup']:play()
                            player.score = player.score + 100
                            player.invincibleTimer = player.invincibleTimer + 10

                            player:addInventoryItem({id="Ring One"})

                        end
                    }
                
                table.insert(objects, theRing)
                
            end

        end

    end   

    -- EFS: Open and closed doors to chapel
    -- EFS: Play wedding music/show hearts with princess 

    theHeart = GameObject {
        texture = 'hearts',
        x = ((theDoorClosedPositionX + 1) * TILE_SIZE),
        y = ((theDoorClosedPositionY - 1) * TILE_SIZE) +5,
        width = 16,
        height = 32,
        frame = 5,
        collidable = false,
        consumable = false,
        solid = false,

        onConsume = function(player)
            gSounds['pickup']:play()
            player.score = player.score + 100
        end
    }

    theHeart.visible = false
    table.insert(objects, theHeart)
    
    theDoorOpen = GameObject {
        texture = 'chapel',
        x = ((theDoorClosedPositionX + 1) * TILE_SIZE),
        y = ((theDoorClosedPositionY - 1) * TILE_SIZE) + 5,
        width = 16,
        height = 32,
        frame = 4,
        collidable = false,
        consumable = false,
        solid = false,
 
        onConsume = function(player, object)    
             object.visible = false
             thePrincess.visible = true
             thePrincess.x = object.x
             thePrincess.y = object.y
             theHeart.visible = true
             theHeart.x = object.x
             theHeart.y = object.y - thePrincess.height
             gSounds['wedding']:play()
             gSounds['music']:stop()

        end
    }

    theDoorOpen.visible = false
    table.insert(objects, theDoorOpen)

    theDoorClosed = GameObject {
        texture = 'chapel',
        x = ((theDoorClosedPositionX - 1) * TILE_SIZE),
        y = ((theDoorClosedPositionY - 1) * TILE_SIZE) +10,
        width = 16,
        height = 32,
        frame = 2,
        collidable = false,
        consumable = true,
        solid = false,

           -- EFS: Function to add Door Open
        onConsume = function(player)
             theDoorOpen.visible = true
             theDoorOpen.consumable = true
        end
    }
    theDoorClosed.visible = false
    table.insert(objects, theDoorClosed)

   
    -- EFS: Flag/pole are at the end of the level (#3)
    local flagAndPolePositionX = width-1
    local flagAndPolePositionY = 3

    theFlag = GameObject {
        texture = 'flags',
        x = ((flagAndPolePositionX - 1) * TILE_SIZE) +10,
        y = ((flagAndPolePositionY - 1) * TILE_SIZE) +12,
        width = 16,
        height = 16,
        frame = 7,
        collidable = false,
        consumable = false,
        solid = false,

        -- EFS: Function to extend the game (#4)
        onConsume = function(player, object)
            gStateMachine:change('play', {width= width+20, score= player.score})
        end
    }
    theFlag.visible = false
    table.insert(objects, theFlag)

    thePole = GameObject {
        texture = 'flags',
        x = (flagAndPolePositionX - 1) * TILE_SIZE,
        y = (flagAndPolePositionY) * TILE_SIZE - 4,
        width = 16,
        height = 16,
        frame = 2,
        collidable = false,
        consumable = false,
        solid = false,

        -- EFS: Function to extend the game
        onConsume = function(player, object)
            gStateMachine:change('play', {width= width+20, score= player.score})
        end
    }
    thePole.visible = false
    table.insert(objects, thePole)

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end