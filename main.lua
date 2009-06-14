-- LÖVE. MAIN.LUA
-- LUKE.PERKIN@GMAIL.COM

--Requires...
love.filesystem.require( "page.lua" )
love.filesystem.require( "anim.lua" )
love.filesystem.require( "game.lua" )
--love.filesystem.require( "scrlog.lua" )
love.filesystem.require( "highscore.lua" )

--Requires...


main = {}
function load()
	loadpage( game )
	
end

function update( dt )
	main.page:update(dt)
	anim.updateAll()
end

function draw()
	main.page:draw()
	--scrlog.draw()
	highscore.draw(20,20)
end

function mousepressed( x, y, key )
	--scrlog.mousePressed( x,y,key )
end

function mousreleased( x, y, key )
	
end

function keypressed( key )
	highscore.keypressed( key )
end

function keyreleased( key )
	
end

function loadpage( page )
	main.page = page
	page:load()
end

function clickCallback( func, ... )
	if love.mouse.isDown(love.mouse_left) then
		if not clickCallbackIsDown then
			func( ... )
			clickCallbackIsDown = true
		end
	else
		clickCallbackIsDown = false
	end
end

function mouseInBox( x1, y1, x2, y2 )
	if love.mouse.getX() > x1 and love.mouse.getX() < x2 and love.mouse.getY() > y1 and love.mouse.getY() < y2 then
		return true
	end
	return false
end