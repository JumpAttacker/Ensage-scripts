--<<omni support pa v1.4>>
require("libs.Utils")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("Auto_heal", "G",config.TYPE_HOTKEY)
config:SetParameter("Auto_repel", "F",config.TYPE_HOTKEY)
config:SetParameter("HideText", "C",config.TYPE_HOTKEY)
config:SetParameter("Heal_on_blink_hotkey", "H",config.TYPE_HOTKEY)
config:SetParameter("Heal_on_blink", true)
config:Load()

local Hk1=config.Auto_heal
local Hk2=config.Auto_repel
local Hk3=config.HideText
local Hk4=config.Heal_on_blink_hotkey
local HealAfterBlink=config.Heal_on_blink
local init = false
target=nil
local Key_for_heal=false
local Key_for_repel=false
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor)
local move=0 local heal=0
local can_heal=false
local name=''
text=nil
function Key(msg,code)
	if not PlayingGame() or client.console or client.chat or client.loading or not init then return end
	if msg == KEY_UP then
		if code == Hk1 then
			Key_for_heal=true
		end
		if code == Hk2 then
			Key_for_repel=true
		end
		if code == Hk then
			text.visible=not text.visible
		end
		if code == Hk4 then
			HealAfterBlink=not HealAfterBlink
		end
	end
end
function Tick( tick )
	if not PlayingGame() or client.chat then return end
	me = entityList:GetMyHero()	
	--print(me)
	if not me then return end
	local ID = me.classId
	if ID ~= CDOTA_Unit_Hero_Omniknight then GameClose() return end
	if not init then
		init=true
		text = drawMgr:CreateText(-45,-55, 0xFFFFFF99, "",F14) text.visible = true text.entity = me text.entityPosition = Vector(0,0,me.healthbarOffset)
	end
	CatchPa()
	local s1=''
	
	if HealAfterBlink then 
		s1='[+]' 
	else 
		s1='[-]' 
	end
	if target~=nil then
		local CE=CatchEnemy()
		if IsKeyDown(32) and HealAfterBlink and SleepCheck('test') then
			if tick > move then
				me:Move(client.mousePosition)
				move = tick + 100
			end
			if me.alive and target.alive then 
				local omni = me:FindSpell("omniknight_purification")
				if omni and omni.level > 0 and omni:CanBeCasted() and me:CanCast() then
					if CE or target.activity==432 and target and GetDistance2D(me,target) < 700 then
						me:CastAbility(omni,target)
						Key_for_heal = false
						Sleep(200,'test')
					end
				end
			end
			text.text='Auto heal [on]. InAction: '..s1..' | '..name
		else
			text.text='Auto heal [off]. InAction: '..s1..' | '..name
		end
	else
		text.text='No target'
	end
		if me.alive and target~=nil and target.alive then
			if Key_for_heal then
				local omni = me:GetAbility(1)
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

function CatchPa()
	local me = entityList:GetMyHero()
	local ally = entityList:FindEntities({type=LuaEntity.TYPE_HERO,team=me.team,alive=true,visible=true,classId=CDOTA_Unit_Hero_PhantomAssassin})
	target=nil
	for i,v in ipairs(ally) do
		if v.healthbarOffset ~= -1 and not v:IsIllusion() then
			distance = GetDistance2D(me,v)
			if distance <= 2500 and v.visible and v.alive and v.health > 0 then 
				target = v
				return
			end
		end
	end
end
function CatchEnemy()
	local me = entityList:GetMyHero()
	local enemyTeam = me:GetEnemyTeam() 
	local eny = entityList:FindEntities({type=LuaEntity.TYPE_HERO,team=enemyTeam,alive=true,visible=true})
	for i,v in ipairs(eny) do
		if target.healthbarOffset ~= -1 and v.healthbarOffset ~= -1 and not v:IsIllusion() then
			distance = GetDistance2D(target,v)
			if distance <= 260 and v.visible and v.alive and v.health > 0 then 
				name=v.name
				return true
			end
		end
	end
	name='not enemy'
	return false
end

function GameClose()
	if text then text.visible=false end
	collectgarbage("collect")
end

script:RegisterEvent(EVENT_CLOSE, GameClose)
script:RegisterEvent(EVENT_FRAME,Tick)
script:RegisterEvent(EVENT_KEY,Key)

