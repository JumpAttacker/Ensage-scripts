--<<omni support pa>>
require("libs.Utils")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("Auto_heal", "G",config.TYPE_HOTKEY)
config:SetParameter("Auto_repel", "F",config.TYPE_HOTKEY)
config:SetParameter("HideText", "C",config.TYPE_HOTKEY)
config:SetParameter("Heal_on_blink", false)
config:Load()

local Hk1=config.Auto_heal
local Hk2=config.Auto_repel
local Hk3=config.HideText
local HealAfterBlink=config.Heal_on_blink
local activated = 0
local init = false
target=nil
local Key_for_heal=false
local Key_for_repel=false
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor)
local sleepTick=nil
local move=0
local can_heal=false
text=nil
function Key(msg,code)
	if client.console or client.chat or client.loading or not init then return end
	if msg == KEY_UP then
		if code == Hk1 --[[and IsKeyDown(32)]]  then
			Key_for_heal=true
		end
		if code == Hk2 --[[and IsKeyDown(32)]] then
			Key_for_repel=true
		end
		if code == Hk3 --[[and IsKeyDown(32)]] then
			text.visible=not text.visible
		end
	end
end
first=true
function Tick( tick )
	if not PlayingGame() then return end
	me = entityList:GetMyHero()	if not me then return end
	local ID = me.classId
	if ID ~= CDOTA_Unit_Hero_Omniknight then GameClose() returnend
	if first then 
		--print('classId'..me.classId) 
		init=true
		text = drawMgr:CreateText(-45,-55, 0xFFFFFF99, "",F14) text.visible = true text.entity = me text.entityPosition = Vector(0,0,me.healthbarOffset)
	end
	--if sleepTick and sleepTick > tick then return end	
	CatchPa()
	--print(target)
	first=false
	
	if target~=nil then
		if IsKeyDown(32) and HealAfterBlink then
			if tick > move then
				me:Move(client.mousePosition)
				move = tick + 100
			end
			if CatchEnemy() and me.alive and target.alive then 
				local omni = me:FindSpell("omniknight_purification")
				if omni and omni.level > 0 and omni:CanBeCasted() and me:CanCast() then
					if target and GetDistance2D(me,target) < 2500 then
						me:CastAbility(omni,target)
						Key_for_heal = false
					end
				end
			end
			text.text='Auto heal [on]'
		else
			text.text='Auto heal [off]'
		end
	else
		text.text='No target'
		if me.alive and target~=nil and target.alive then
			if Key_for_heal then
				local omni = me:FindSpell("omniknight_purification")
				if omni and omni.level > 0 and omni:CanBeCasted() and me:CanCast() then
					if target and GetDistance2D(me,target) < 2500 then
						me:CastAbility(omni,target)
						Key_for_heal = false
					end
				end
			end
			if Key_for_repel then
				local omni = me:GetAbility(2)
				if omni and omni.level > 0 and omni:CanBeCasted() and me:CanCast() then
					if target and GetDistance2D(me,target) < 2500 then
						me:CastAbility(omni,target)
						Key_for_repel = false
					end
				end
			end
		end
	end
	
	
end
function CatchPa()
	local ally = entityList:FindEntities({type=TYPE_HERO,team=TEAM_ALLY,alive=true,visible=true,classId=CDOTA_Unit_Hero_PhantomAssassin})
	target=nil
	for i,v in ipairs(ally) do
		distance = GetDistance2D(me,v)
		if distance <= 2500 and not v:IsIllusion() then 
			target = v
			--print(v.name..'in range: '..distance)
			return
		end
	end
end
function CatchEnemy()
	local eny = entityList:FindEntities({type=TYPE_HERO,team=TEAM_ENEMY,alive=true})
	for i,v in ipairs(ally) do
		distance = GetDistance2D(eny,v)
		if distance <= 260 and not v:IsIllusion() then 
			return true
		end
	end
	return false
end

function GameClose()
	script:Unload()
	collectgarbage("collect")
end

script:RegisterEvent(EVENT_CLOSE, GameClose)
script:RegisterEvent(EVENT_FRAME,Tick)
script:RegisterEvent(EVENT_KEY,Key)
