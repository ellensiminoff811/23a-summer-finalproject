--[[
    GD50
    -- Super Mario Bros. Remake --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    EFS - Added a scalefactor because my images were too big
]]

GameObject = Class{}

function GameObject:init(def)
    self.x = def.x
    self.y = def.y
    self.texture = def.texture
    self.width = def.width
    self.height = def.height
    self.frame = def.frame
    self.solid = def.solid
    self.collidable = def.collidable
    self.consumable = def.consumable
    self.onCollide = def.onCollide
    self.onConsume = def.onConsume
    self.hit = def.hit

    -- EFS (project)
    self.scalefactor = def.scalefactor or 1

    -- EFS create a hiding flag
    self.visible = true
end

function GameObject:collides(target)
    return not (target.x > self.x + self.width or self.x > target.x + target.width or
            target.y > self.y + self.height or self.y > target.y + target.height)
end

function GameObject:update(dt)

end

function GameObject:render()

    if not self.visible then
        -- EFS: Allow locks to become hidden        
        return
    end      
 
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.frame], self.x, self.y, 0, self.scalefactor, self.scalefactor)
       
end

  
