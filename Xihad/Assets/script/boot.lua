g_scene:requireSystem(c"Render")	-- load Irrlicht render component system
local levelPath = 'Assets/level/level_01.battle'
local userSavePath = 'User/sav/Save1.hero'

require 'Assets.script.AllPackages'	-- change package.path
require 'math3d'					-- load math3d
require "CreateMesh"				-- create cube mesh

local Warrior = require 'Warrior'
local LevelFactory = require 'Level.XihadLevelFactory'
local WarriorFactory = require 'Warrior.WarriorFactory'

-- register game specific properties
Warrior.registerProperty('MHP')
Warrior.registerProperty('ATK')
Warrior.registerProperty('DFS')
Warrior.registerProperty('MTK')
Warrior.registerProperty('MDF')
Warrior.registerProperty('MAP')

local battle = dofile(levelPath)
local heros  = dofile(userSavePath)
local warriorFactory = WarriorFactory.new()
local loader = LevelFactory.new({ Enemy = warriorFactory, Hero = warriorFactory }, heros)
g_chessboard = loader:create(battle)

local CameraFactory= require 'Camera.SimpleCameraFactory'
local CameraFacade = require 'Camera.CameraFacade'
local cameraObject = CameraFactory.createDefault('camera')
local cameraFacade = CameraFacade.new(cameraObject)
g_scene:pushController {
	onKeyUp = function (self, e)
		local object = g_scene:findObject(c(string.upper(e.key)))
		if not object or not object:findComponent(c'Warrior') then 
			return 1 
		end
		
		local asyncFocys = coroutine.wrap(cameraFacade.focus)
		asyncFocys(cameraFacade, object)
		return 0
	end
}

-- ADD LIGHT
local sun = g_scene:createObject(c'sun')
local lightControl = sun:appendComponent(c'Light')
lightControl:castShadow(false)
lightControl:setType 'direction'
sun:concatTranslate(math3d.vector(0, 30, 0))

for heroObj in g_scene:objectsWithTag('Hero') do
	heroObj:findComponent(c'Warrior'):activate()
end

local CommandExecutor = require 'Command.CommandExecutor'
local cmdExecutor = CommandExecutor.new(cameraFacade)

-- INPUT
local ui = {
	showWarriorInfo = function (self, obj)
		print('ui info: ', obj:getID())
	end,
	
	showTileInfo = function (self, tile)
		print('ui info: ', tile:getTerrain().type)
	end,
	
	warning = function (self, msg)
		print(msg)
	end,
}

local painter = {
	colorTable = { 
		Reachable = Color.white, 
		Destination = Color.cyan,
		Attack = 0xffff00ff,
	},
	
	mark = function (self, tiles, type)
		if not tiles then return end
		
		local color = Color.new(self.colorTable[type])
		
		local handle = {}
		for _, tile in ipairs(tiles) do
			-- TODO why there is nil tile?
			if tile then
				if not tile.getTerrain then
					for k,v in pairs(tile) do
						print(k,v)
					end
				end
				local terrian = tile:getTerrain()
				local idx = terrian:pushColor(color)
				handle[terrian] = idx
			end
		end
		
		return handle
	end,
	
	clear = function (self, handle)
		if not handle then return end
		
		for terrian, idx in pairs(handle) do
			terrian:removeColor(idx)
		end
	end,
}

local Transformer = require 'Controller.PCInputTransformer'
local PlayerStateMachine = require 'Controller.PlayerStateMachine'
local sm = PlayerStateMachine.new(ui, cameraFacade, painter, cmdExecutor)
local tranformer = Transformer.new(sm)
g_scene:pushController(tranformer)
tranformer:drop()

local finishListener = {}
function finishListener:onStateEnter(state, prev)
	assert(state == 'Finish', state)
	for object in g_scene:objectsWithTag('Hero') do
		local warrior = object:findComponent(c'Warrior')
		if warrior:isActive() then
			sm:nextHero()
			return
		end
	end
	
	print('player round over')
	for object in g_scene:objectsWithTag('Enemy') do
		local warrior = object:findComponent(c'Warrior')
		warrior:activate()
	end
	
	for object in g_scene:objectsWithTag('Enemy') do
		local tactic = object:findComponent(c'Tactic')
		local cmdList = tactic:giveOrder()
		print(tostring(cmdList))
		cmdExecutor:execute(cmdList)
	end
	
	print('player round begin')
	for object in g_scene:objectsWithTag('Hero') do
		local warrior = object:findComponent(c'Warrior')
		warrior:activate()
	end
	sm:nextHero()
end

function finishListener:onStateExit(state, next) end

sm:addStateListener('Finish', finishListener)
sm:addStateListener('ChooseHero', {
		onStateEnter = function(self, state, prev) 
			if prev == 'Finish' then
				cameraFacade:focus(nil)
			end
		end,
		
		onStateExit = function() end
	})

-- g_world:setTimeScale(0.3)
