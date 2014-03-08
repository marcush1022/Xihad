--- 
-- 对AI进行控制和切换的Manager
-- @module AIManager
-- @author wangxuanyi
-- @license MIT
-- @copyright NextRPG

local CharacterManager = require "CharacterManager"
local StrategyDatabase = require "StrategyDatabase"


local AIManager = CharacterManager.new{team = "AI"}

function AIManager:init( AIs )
	-- init heroes on map
	for i,AI in ipairs(AIs) do
		local character = 
			{
				career = "WARRIOR",

				level = 1,
				currentExp = 0,
				getExp = 0,
				
				name = "Tom" .. i,
				skills = { 2 },

				properties = {
					physicalAttack = 5,
					physicalDefense = 5,
					magicAttack = 5,
					magicDefense = 10,  
					maxAP = 5,			
					maxHP = 200,
					maxMP = 100
				}

			}
		character.name = AI.name
		character.strategy = StrategyDatabase:createStrategy(2)
		self.currentCharacter = self:createCharacter(character, AI.y, AI.x)
		self.currentCharacter:appendComponent(c"Actor", 
			{manager = self, strategy = character.strategy})
	end
end

function AIManager:runActors(  )
	for characterObject in scene:objectsWithTag(self.team) do
		if not scene:hasObjectWithTag("Hero") then break end
		local actor = characterObject:findComponent(c"Actor")
		local character = characterObject:findComponent(c"Character")
		if not character.states.TURNOVER then
			actor:run(coroutine.running())
			coroutine.yield()
			character.states.TURNOVER = true
		end
	end
end

function AIManager:getFarthestAI( center )
	local list = makeList(self:getCharacters(), "name", "tile")
	for name,tile in pairs(list) do
		list[name] = math.p_distance(center, tile)
	end
	local name = findMax(list)
	return scene:findObject(c(name)):findComponent(c"Character").tile
end

return AIManager