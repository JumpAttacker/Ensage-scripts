--<<If the icon has become a color that mean that creep dies from your attack>>
require("libs.ScriptConfig")
require("libs.Utils")

config = ScriptConfig.new()
config:SetParameter("LastHitKey", "C", config.TYPE_HOTKEY)
config:SetParameter("DenayHitKey", "X", config.TYPE_HOTKEY)
config:SetParameter("LastHit", true)
config:SetParameter("AutoDisable", true)
config:Load()

local rect = {}
local sleep = 0
local play = false
local ex = client.screenSize.x/1600*0.8

local lasthit = config.LastHit
local lasthitKey = config.LastHitKey
local denyKey = config.DenayHitKey
local AD = config.AutoDisable
local bloodseeker=false

local x,y = 5, 50
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",12*monitor,750*monitor) 
local statusText = drawMgr:CreateText(x*monitor,y*monitor,-1,"Dmg: 0",F14) statusText.visible = false
local dbg=false
function Tick( tick )

	if client.console or sleep > tick then return end	
	
	sleep = tick + 100

	local me = entityList:GetMyHero()	
	if not me then return end

	if AD and (client.gameTime > 1800 or me.dmgMin > 100) then
		GameClose()
		script:Disable()
	end
	
	if bloodseeker then
		bloodseekerAmplificationArray = {1.25, 1.30, 1.35, 1.40}
		if me:GetAbility(1) ~= nil then
			bloodseekerPercentAmplified = bloodseekerAmplificationArray[me:GetAbility(1).level]
		else
			bloodseekerPercentAmplified = 1.0
		end
	end
	
	local dmg = Damage(me)
	if dbg then
		statusText.visible=true
		statusText.text="dmg: "..tostring(dmg)
	end
	local creeps = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Lane})
	
		
	for i,v in ipairs(creeps) do
		if v.spawned then
			local OnScreen = client:ScreenPosition(v.position)	
			if OnScreen then
				local offset = v.healthbarOffset
				if offset == -1 then return end			
				
				if not rect[v.handle] then 
					rect[v.handle] = drawMgr:CreateRect(-4*ex,-32*ex,0,0,0xFF8AB160) rect[v.handle].entity = v rect[v.handle].entityPosition = Vector(0,0,offset) rect[v.handle].visible = false 					
				end
				
				if v.visible and v.alive then
					local damage = (dmg*(1-v.dmgResist)+1)
					
					if v.health > 0 and v.health < damage then						
						if v.team == me.team then
							rect[v.handle].w = 20*ex
							rect[v.handle].h = 20*ex
							rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Active_Deny")
						else
							rect[v.handle].w = 15*ex
							rect[v.handle].h = 15*ex
							rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Active_Coin")
						end
						if LH(v,me.attackRange,me.position,denyKey) then
							break
						end
						rect[v.handle].visible = true
					elseif v.health > damage and v.health < damage+88 then					
						if v.team == me.team then
							rect[v.handle].w = 20*ex
							rect[v.handle].h = 20*ex
							rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Passive_Deny")
						else
							rect[v.handle].w = 15*ex
							rect[v.handle].h = 15*ex
							rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Passive_Coin")
						end
						rect[v.handle].visible = true
					else 
						rect[v.handle].visible = false
					end
				elseif rect[v.handle].visible then
					rect[v.handle].visible = false
				end
			end	
		end
	end

end

function Damage(me)
	local dmg =  me.dmgMin + me.dmgBonus
	local items = me.items
	for i,item in ipairs(items) do
		if item and item.name == "item_quelling_blade" then
			if me:IsRanged() then 
				dmg=dmg*1.15
			else
				dmg=dmg*1.40
			end
		end
	end
	if me:DoesHaveModifier("modifier_bloodseeker_bloodrage") then
		return dmg*bloodseekerPercentAmplified
	end
	return dmg
end

function LH(v,range,position,key)
	if lasthit then
		if IsKeyDown(key) then
			if v:GetDistance2D(position) < range + 200 then
				entityList:GetMyPlayer():Attack(v)
				return true
			end
		end
	end
end

function Load()
	if PlayingGame() then
		play = true
		local me = entityList:GetMyHero()
		if me.classId == CDOTA_Unit_Hero_Bloodseeker then
			bloodseeker=true
		end
		script:RegisterEvent(EVENT_TICK,Tick)
		script:UnregisterEvent(Load)
	end
end

function GameClose()
	rect = {}
	collectgarbage("collect")
	if play then
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK,Load)
		play = false
	end
end

script:RegisterEvent(EVENT_TICK,Load)
script:RegisterEvent(EVENT_CLOSE,GameClose)
