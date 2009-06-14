pages = {}
pages.__index = pages
objects = {}
objects.__index = objects

function pages:add()
	local page = {}
	setmetatable(page,pages)
	return page
end

function pages:update( dt )
	for k,v in ipairs( self ) do
		v:update( dt )
	end
end

function pages:draw()
	for k,v in ipairs( self ) do
		v:draw()
	end
end

function pages:sortdepth()
	table.sort( self,
	function(a,b) return a._depth > b._depth end )
end


function objects:add( page )
	local object = {}
	setmetatable(object,objects)
	object._page = page
	object:load()
	table.insert( page, object )
	page:sortdepth()
	return object
end

function objects:load()
	self._depth = 0
end

function objects:update( dt )
end

function objects:draw()
end

function objects:depth( depth )
	self._depth = depth
	self._page:sortdepth()
end

function objects:page( page )
	local lastpage = self._page
	self._page = page
	table.insert(page,self)
	for k,v in ipairs(lastpage) do
		if v == self then table.remove(lastpage,k) end
	end
end
