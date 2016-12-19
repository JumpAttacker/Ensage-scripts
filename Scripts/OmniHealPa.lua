--<<omni support pa v1.5 test>>

require("libs.ScriptConfig")
require("libs.Utils")
require("libs.AbilityDamage")
require("libs.Animations")

config = ScriptConfig.new()
config:SetParameter("Hotkey", "F", config.TYPE_HOTKEY)
config:Load()

local Hotkey = config.Hotkey

local play = false
local active = false
local target
local eff,eff2=nil,nil
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",12*monitor,750*monitor) 
local statusText


local screenResolution = client.screenSize
local screenRatio = client.screenRatio

function Key(msg,code)
	if client.chat or client.console or client.loading then return end
	if code == Hotkey then
		active = (msg == KEY_DOWN)
	end
end

function Tick(tick)
	if not PlayingGame() then return end
	if sleepTick and sleepTick > tick then return end	
	
	me = entityList:GetMyHero() if not me then return end
	if active then
		if not eff then
            eff = Effect(me,"range_display")
			eff:SetVector( 1, Vector(700,0,0) )
		end
		if not eff2 then
            eff2 = Effect(me,"range_display")
			eff2:SetVector( 1, Vector(1000,0,0) )
		end
		CatchPa()
		if not target then statusText.text="[No target]" return end
		heal=me:GetAbility(1)
		if  me.alive and target.alive and heal~=nil then 
			dist=GetDistance2D(me,target)
			if CE or target.activity==432 then
				if dist<=700 then
					me:SafeCastAbility(heal,target)
					statusText.text="[Casting]"
				else
					statusText.text="[Out of range]"
				end
			else
				statusText.text="[In action]"
			end
		end
	else
		if eff then
			eff = nil
			collectgarbage("collect")
		end
		if eff2 then
			eff2 = nil
			collectgarbage("collect")
		end
	end
	statusText.visible=active
end

function CatchPa()
	local me = entityList:GetMyHero()
	local ally = entityList:FindEntities({type=LuaEntity.TYPE_HERO,team=me.team,alive=true,visible=true,classId=CDOTA_Unit_Hero_PhantomAssassin})
	target=nil
	for i,v in ipairs(ally) do
		if v.healthbarOffset ~= -1 and not v:IsIllusion() then
			distance = GetDistance2D(me,v)
			if distance <= 1000 and v.visible and v.alive and v.health > 0 then 
				target = v
				return
			end
		end
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me or me.classId ~= CDOTA_Unit_Hero_Omniknight then 
			script:Disable()
		else
			play = true
			script:RegisterEvent(EVENT_TICK,Tick)
			script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(Load)
			statusText = drawMgr:CreateText(-45,-55, 0xFFFFFF99, "[In actions]",F14) 
			statusText.visible = false 
			statusText.entity = me 
			statusText.entityPosition = Vector(0,0,me.healthbarOffset+25)
		end
	end
end

function GameClose()
	collectgarbage("collect")
	if play then
	    statusText.visible = false
		script:UnregisterEvent(Main)
		script:UnregisterEvent(Key)
		play = false
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
