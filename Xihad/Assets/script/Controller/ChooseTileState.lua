local base = require 'Controller.PlayerState'
local ChooseTileState = setmetatable({
	selectedHandle	= nil,
	reachableHandle = nil,
	attackableHandle= nil,
	
	selectedTile 	= nil,
	prevSourceTile 	= nil,
	
	lastHoverTile = nil,
}, base)
ChooseTileState.__index = ChooseTileState

function ChooseTileState.new(...)
	return setmetatable(base.new(...), ChooseTileState)
end

function ChooseTileState:onStateEnter(state, prev)
	local warrior = self.commandList:getSource()
	if prev == 'ChooseCommand' then
		assert(self.prevSourceTile)
		local warriorBarrier = warrior:findPeer(c'Barrier')
		warriorBarrier:setTile(self.prevSourceTile)
	end
	
	self.prevSourceTile = nil
	
	local reachable = g_chessboard:getReachableTiles(warrior)
	self.reachableHandle = self.painter:mark(reachable, 'Reachable')
	self.camera:focus(warrior:getHostObject())
end

function ChooseTileState:onStateExit()
	self:_safeClear('reachableHandle')
	self:_safeClear('attackableHandle')
	self:_safeClear('selectedHandle')
end

function ChooseTileState:onBack()
	self.camera:focus(nil)
	return 'back'
end

function ChooseTileState:needCDWhenTouch()
	return false
end

function ChooseTileState:needCDWhenHover()
	return false
end

function ChooseTileState:onTileSelected(tile, times)
	-- show tile info
	local warrior = self.commandList:getSource()
	if tile:canStay(warrior) then
		local destLocation= tile:getLocation()
		if not g_chessboard:canReach(warrior, destLocation) then
			print('can not reach')
		elseif self.selectedTile ~= tile and times == 1 then
			self.painter:clear(self.selectedHandle)
			
			-- TODO
			-- local XihadMapTile = require 'Chessboard.XihadMapTile'
			-- local x, y = g_cursor:getPosition()
			-- local ray = g_collision:getRayFromScreenCoord(x, y)
			-- local point = XihadMapTile.intersectsGround(ray)
			-- local fixCursor = { onUpdate = function ()
			-- 	local x,y = g_collision:getScreenCoordFromPosition(point)
			-- 	g_cursor:setPosition(x, y)
			-- end}
			-- self.camera.cameraObject:appendUpdateHandler(fixCursor)
			self.camera:focus(tile:getTerrain():getHostObject())
			-- fixCursor:stop()
			self.selectedHandle = self.painter:mark({ tile }, 'Selected')
			self.selectedTile = tile
		else
			self.painter:clear(self.selectedHandle)
			self.selectedHandle = nil
			
			local warriorTile = warrior:findPeer(c'Barrier'):getTile()
			local destinationHandle = self.painter:mark({ tile }, 'Destination')
			do 
				-- move back to warrior location
				self.camera:translateToTarget(warriorTile:getCenterVector())
				
				-- continue to focus host object
				self.camera:focus(warrior:getHostObject())
				self.executor:move(warrior:getHostObject(), destLocation)
			end
			self.painter:clear(destinationHandle)
			
			self.prevSourceTile = warriorTile
			self.commandList:setLocation(destLocation)
			return 'next'
		end
	else
		self.ui:warning('not stayable')
	end
end

function ChooseTileState:onTileHovered(tile)
	if self.lastHoverTile ~= tile then
		local warrior = self.commandList:getSource()
		
		if g_chessboard:canReach(warrior, tile:getLocation()) then
			self.ui:showTileInfo(tile)
			
			self:_safeClear('attackableHandle')
			
			local skillCaster = warrior:findPeer(c'SkillCaster')
			local range = skillCaster:getCastableTiles(tile:getLocation())
			self.attackableHandle = self.painter:mark(range, 'Attack')
		else
			self:_safeClear('attackableHandle')
		end
		
		self.lastHoverTile = tile
	end
end

return ChooseTileState
