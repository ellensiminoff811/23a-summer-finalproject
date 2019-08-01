--[[
    GD50
    Super Mario Bros. Remake

    -- Player Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    EFS - Added way to avoid chasm on entry (#1)
    EFS - Added logic to show when a key is present (#2)
]]

Player = Class{__includes = Entity}

-- EFS - Added logic to show when a key is present (#2)
function Player:init(def)
    Entity.init(self, def)
    self.score = 0
    self.invincibleTimer = 0
    self.isInvincible = false

    self.inventory = {}
end

-- EFS: Added logic to show when a key or ring is present (#2 and project)
function Player:hasItemWithId(itemId)

    for k, item in pairs(self.inventory) do 
        if (item.id == itemId) then
            return true
        end
    end

    return false

end

-- EFS: Added logic to show when a key is present (#2 and project)
function Player:addInventoryItem(item)

    if not (item.id) then
        return
    end

    table.insert(self.inventory, item)

end

function Player:update(dt)
    if self.isInvincible then
        self.invincibleTimer = self.invincibleTimer - dt 
        if self.invincibleTimer < 0 then
            self.invincibleTimer = 0
            self.isInvincible = false
        end    
    elseif self.invincibleTimer > 0 then
        self.isInvincible = true
    end
        
    Entity.update(self, dt)
end
    
function Player:render()
    Entity.render(self) 
      -- EFS in invincible gets stars
    if (self.isInvincible) then
        love.graphics.print("**", self.x, self.y+10)
    end       
       
end

-- EFS: Added logic to show when a key is present (#2)
function Player:renderInventory()
    local currentLine = 35
    local lineHeight = 20
    local lineNumber = 0

    if (self:hasItemWithId("Key One")) then
        local toWrite = "Has Key"

        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.print(toWrite, 5, currentLine+lineHeight*lineNumber)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(toWrite, 4, currentLine+lineHeight*lineNumber-1)
        lineNumber = lineNumber + 1
    end

    if (self:hasItemWithId("Ring One")) then
        local toWrite = "Has Ring"

        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.print(toWrite, 5, currentLine+lineHeight*lineNumber)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(toWrite, 4, currentLine+lineHeight*lineNumber-1)
    end

end

--  EFS - Check Ground (#1)
function Player:checkGround()

    for x = 0, self.map.width-1 do
        for y = 1, self.map.height-1 do
            
            -- EFS - Guarantee player doesn't drop into chasm (#1)
            local tileID = self.map:pointToTile(x*TILE_SIZE,y*TILE_SIZE).id

            if tileID == TILE_ID_GROUND then
                self.x = x * TILE_SIZE
                return
            end

        end
    end 

end

function Player:checkLeftCollisions(dt)
    -- check for left two tiles collision
    local tileTopLeft = self.map:pointToTile(self.x + 1, self.y + 1)
    local tileBottomLeft = self.map:pointToTile(self.x + 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopLeft and tileBottomLeft) and (tileTopLeft:collidable() or tileBottomLeft:collidable()) then
        self.x = (tileTopLeft.x - 1) * TILE_SIZE + tileTopLeft.width - 1
    else
        
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object
        if #collidedObjects > 0 then
            self.x = self.x + self:getWalkSpeed() * dt
        end
    end
end
 
-- EFS: Increase walk speed once invincible
function Player:getWalkSpeed()
    if self.isInvincible then
        return PLAYER_WALK_SPEED * 2
    end  
     
    return PLAYER_WALK_SPEED
end    


function Player:checkRightCollisions(dt)
    -- check for right two tiles collision
    local tileTopRight = self.map:pointToTile(self.x + self.width - 1, self.y + 1)
    local tileBottomRight = self.map:pointToTile(self.x + self.width - 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopRight and tileBottomRight) and (tileTopRight:collidable() or tileBottomRight:collidable()) then
        self.x = (tileTopRight.x - 1) * TILE_SIZE - self.width
    else
        
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object
        if #collidedObjects > 0 then
            self.x = self.x - self:getWalkSpeed() * dt
        end
    end
end

function Player:checkObjectCollisions()
    local collidedObjects = {}

    for k, object in pairs(self.level.objects) do
        if object:collides(self) then
            if object.solid then
                table.insert(collidedObjects, object)
            elseif object.consumable then
                object.onConsume(self, object)
                table.remove(self.level.objects, k)
            end
        end
    end

    return collidedObjects
end