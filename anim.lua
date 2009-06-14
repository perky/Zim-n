-- JakeMadeThis
-- Last Update: 21:25 10 June 2009

--[[
Copyright (c) 2008 Jake Coxon

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.

http://www.opensource.org/licenses/zlib-license.php
]]

--[[
Function Reference

-- Sets the tween value of name to val only if it doesn't already exist. Use
-- together with anim.simple
anim.start( string name, number val )

-- Starts the animation between the current value of name and dest in time
-- seconds, using the equation function.
-- equation can be your own function or an ANIM_* function (check the top of anim.lua)
anim.simple( string name, number dest, number time, function equation, ... )

-- Similar to anim.simple but queues the animation after delay amount of seconds. 
-- Optional start value.
anim.queue( string name, number start, number dest, number time, number delay, function equation, ... )

-- Queues a function to run after delay amount of seconds. Passes ... to the function.
anim.callback( string name, number delay, function callback, ... )

-- Alias of anim.callback( name, delay, anim.remove, name )
anim.queueremove( string name, number delay )

-- Returns the current tween value of the animation or default if it doesn't exist.
anim.get( string name, number default )

-- Removes everything from the queue. Keeps current value.
anim.reset( string name )

anim.remove( string name )

anim.removeAll()

anim.exists( string name )
]]

--Edited to be more 'class' based by luke p.

anim = {}
anim.__index = anim

-- todo: rename to tween?

-- Equations modified for Lua. Originally by Robert Penner.
-- http://www.robertpenner.com/easing/

function ANIM_LINEAR( t, b, c, d )
	return b + c*t/d
end

function ANIM_QUAD_IN( t, b, c, d )
	local p = t/d
	return c*p*p + b
end
function ANIM_QUAD_OUT( t, b, c, d )
	local p = t/d
	return -c*p*(p-2) + b
end
function ANIM_QUAD_INOUT( t, b, c, d )
	local p = t/(d/2)
	if p < 1 then return c/2*p*p + b end
	return -c/2 * ((p-1)*(p-3)-1) + b
end

function ANIM_QUART_IN( t, b, c, d )
	local p = t/d
	return c*p*p*p*p + b
end
function ANIM_QUART_OUT( t, b, c, d )
	local p = t/d-1
	return -c*(p*p*p*p-1) + b
end
function ANIM_QUART_INOUT( t, b, c, d )
	local p = t/(d/2)
	if p < 1 then return c/2*p*p*p*p + b end
	return -c/2 * ((p-2)*(p-2)*(p-2)*(p-2)-2) + b
end

function ANIM_EXPO_IN( t, b, c, d )
	return t==0 and b or c * math.pow(2, 10*(t/d-1)) + b
end
function ANIM_EXPO_OUT( t, b, c, d )
	return t==d and b+c or c * (-math.pow(2, -10*t/d)+1) + b
end
function ANIM_EXPO_INOUT( t, b, c, d )
	if t==0 then return b end
	if t==d then return b+c end
	local p = t/(d/2)
	if p < 1 then return c/2 * math.pow(2, 10*(p-1)) + b end
	return c/2 * (-math.pow(2, -10*(p-1))+2) + b
end

function ANIM_ELASTIC( t, b, c, d, a, p )
	local a, p = a, p
	
	if t==0 then return b end
	local t2 = t/d
	
	if t2==1 then return b+c end
	if not p then p = d * 0.3 end
	if not a or a < math.abs(c) then
		a = c
		s = p/4
	else
		s = p/(2*math.pi) * math.asin( c/a )
	end
	return a*math.pow(2, -10*t2) * math.sin((t2*d-s)*(2*math.pi)/p) + c + b
end

-- Local constants
ANIM_ANIM = 1
ANIM_CALLBACK = 2

local anim_tab = {}

function anim:insertQueue( startdelay, from, to, time, eq, ... )

	table.insert( self.queue, {
		type = ANIM_ANIM,
		startdelay = startdelay,
		
		from = from,
		to = to,
		time = time,
		eq = eq or ANIM_LINEAR,
		args = {...}
	} )
	return self.queue[ #self.queue]

end

function anim:insertCallback( startdelay, func, ... )

	table.insert( self.queue, {
		type = ANIM_CALLBACK,
		startdelay = startdelay,
		hasrun = false,
		func = func,
		args = {...},
	} )

end

function anim.create( from, to, time, delay, eq, ... )

	local anim_ob = {
		val = nil,
		starttime = love.timer.getTime(),
		repeatdelay = false,
		totallength = 0,
		lastupdate = 0,
		queue = {},
		_start = false
	}
	anim_ob.val = from
	setmetatable(anim_ob,anim)
	table.insert( anim_tab, anim_ob )

	local eq = (eq or ANIM_LINEAR)
	local TIME_NOW = love.timer.getTime()
	
	anim_ob.queue = {}
	anim_ob.starttime = TIME_NOW
	anim_ob.totallength = time
	anim_ob:insertQueue( delay, from, to, time, eq, ... )
	
	return anim_ob

end

function anim:start()
	self._start = true
	--self.starttime = self.starttime + (love.timer.getTime() - self.lastupdate)
	self.starttime = love.timer.getTime()
end

function anim:restart()
	self.starttime = love.timer.getTime( )
end

function anim:pause()
	self._start = false
	self.lastupdate = love.timer.getTime()
end

function anim:toggle()
	self._start = not self._start
	self.starttime = self.starttime + (love.timer.getTime() - self.lastupdate)
end

function anim:delay( delay )
	local TIME_NOW = love.timer.getTime()
	local total = #self.queue
	local startdelay = self.totallength + delay
	if total > 0 and TIME_NOW > self.starttime + self.totallength then
		startdelay = (TIME_NOW + delay) - self.starttime
		delay = startdelay - self.totallength
	end
	self.totallength = self.totallength + delay
end

function anim:add( from, to, time, delay, eq, ... )

	local delay = (delay or 0)
	local eq = (eq or ANIM_LINEAR)
	local TIME_NOW = love.timer.getTime()
	
	local total = #self.queue
	if total == 0 then
		self.starttime = TIME_NOW
	end
	
	local startdelay = self.totallength + delay
	if total > 0 and TIME_NOW > self.starttime + self.totallength then
		startdelay = (TIME_NOW + delay) - self.starttime
		delay = startdelay - self.totallength
	end
	
	self:insertQueue( startdelay, from, to, time, eq, ... )
	self.totallength = self.totallength + delay + time
	
end

function anim:callback( delay, func, ... )

	local delay = (delay or 0)
	local TIME_NOW = love.timer.getTime()
	
	local total = #self.queue
	if total == 0 then
		self.starttime = TIME_NOW
	end
	
	local startdelay = self.totallength + delay
	if total > 0 and TIME_NOW > self.starttime + self.totallength then
		startdelay = (TIME_NOW + delay) - self.starttime
	end
	
	self:insertCallback( startdelay, func, ... )
	self.totallength = self.totallength + delay

end

function anim:queueremove( delay )
	self:callback( delay, anim.remove, name )
end

function anim:update()

	if self._start == false then return; end
	
	local TIME_NOW = love.timer.getTime()
	if TIME_NOW <= self.lastupdate + 0.01 then
		return
	end
	self.lastupdate = TIME_NOW

	local total = #self.queue
	for i=total, 1, -1 do -- backwards

		local queue = self.queue[ i ]
		local absolute_starttime = self.starttime + queue.startdelay
		if TIME_NOW >= absolute_starttime then
			local time_elapsed = TIME_NOW - absolute_starttime
			if queue.type == ANIM_CALLBACK and not queue.hasrun then
				queue.func( unpack( queue.args ) )
				queue.hasrun = true
			end
			if queue.type == ANIM_ANIM and time_elapsed < queue.time then
				queue.from = (queue.from or self.val or 0)
				if time_elapsed >= queue.time then
					self.val = queue.to
				else
					self.val = queue.eq( time_elapsed, queue.from, queue.to - queue.from, queue.time, unpack( queue.args ) )
				end
				--break
			end
		end
	end
	
end

-- todo: this function needed?
function anim:destination()

	local TIME_NOW = love.timer.getTime()
	local total = #self.queue
	for i=total, 1, -1 do -- backwards
		local queue = self.queue[ i ]
		local absolute_starttime = self.starttime + queue.startdelay
		if TIME_NOW >= absolute_starttime and queue.type == ANIM_ANIM then
			return queue.to
		end
	end

end

function anim.updateAll()

	for k, v in pairs( anim_tab ) do
		v:update()
	end

end

function anim:reset()

	if self then
		self.queue = {}
		self.starttime = nil
		self.totallength = 0
	end

end

function anim.getTable()
	return anim_tab
end

function anim:remove()
	self = nil
end
function anim.removeAll()
	anim_tab = {}
end

function anim:exists( name )
	return self ~= nil
end

function anim:get( default )
	return self and self.val or default
end
