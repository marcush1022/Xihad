local SkillCaster = {
	skills = nil,
}
SkillCaster.__index = SkillCaster

function SkillCaster.new()
	return setmetatable({
			skills = {},	-- skill -> time
		}, SkillCaster)
end

function SkillCaster:castableSkills()
	return function(t, lastKey) 
		local skill, time
		
		repeat
			skill, time = next(t, lastKey)
		until not skill or time > 0
			
		return skill
	end, self.skills
end

function SkillCaster:canCastSkill(skill)
	return self.skills[skill] and self[skills] > 0
end

--- 
-- @return BattleResult
function SkillCaster:castSkill(skill, targetLocation, chessboard)
	local restCount = self.skills[skill]
	assert(restCount and restCount > 0, 
		string.format("Can't cast the specified skill: %s", skill:getName()))
	
	self.skills[skill] = restCount - 1
	
	return skill:resolve(self:findPeer(c'Warrior'), targetLocation, chessboard)
end

function SkillCaster:learnSkill(skill, initialCount)
	assert(type(initialCount) == 'number' and initialCount > 0)
	self.skills[skill] = initialCount
end

function SkillCaster:forgetSkill(skill)
	self.skills[skill] = nil
end

function SkillCaster:_getLocation(startLoc)
	return startLoc or self:findPeer(c'Warrior'):getLocation()
end

function SkillCaster:getCastableTiles(startLoc)
	-- TODO 
	startLoc = self:_getLocation(startLoc)
	local locs = {
		startLoc:left(), startLoc:right(), 
		startLoc:top(), startLoc:down(), 
	}
	
	local tiles = {}
	for _, loc in ipairs(locs) do
		local tile = g_chessboard:getTile(loc)
		if tile then
			table.insert(tiles, tile)
		end
	end
	
	return tiles
end

return SkillCaster
