--<<Techies combo by Jumbo v0.4>>

require("libs.Utils")
require("libs.EasyHUD")

local myHUD = nil
local HeroInfoHUD = nil
local play = false
local AutoForceStaff = false
local eff 
local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",12*monitor,750*monitor) 
local statusText={}
local statusTextSuic={}
local bombRange=700
local bombInfo={}
local bombInfoDamage={}
local bombInfoRange={200,450,440}
local bombRangeEffect={}
local me=nil
local icon = {}
local spell_icon = {}
local suic_damage={500,650,850,1150}
local remote_damage={300,450,600,750}
local killable={}
local textDrawObj={}
local xx,yy = 10,110
local chLand,chStatic,chRemote=true,false,true
local Performance

function SavePerformanceConf(b1,b2,t)
	local file = io.open(SCRIPT_PATH.."/config/Techies.txt", "w")
	b1.color = math.random(0,0xFFFFFF)
	if Performance<5 then
		Performance=Performance+1
	else
		Performance=1
	end
	t.text="P: "..tostring(Performance)
	if file then
		file:write(Performance)
		--print("Performance save: "..tostring(Performance))
		file:close()
	end
end
function LoadPerformanceConf()
	local file = io.open(SCRIPT_PATH.."/config/Techies.txt", "r")
	if file then
		Performance = file:read("*number")
		--print("Performance load: "..tostring(Performance))
		file:close()                           
	 end
	if not Performance then
	   Performance=1
	end
end
function CheckLand(b1,b2,t)	
	chLand=not chLand
	Fresh()
end
function CheckStatic(b1,b2,t)	
	chStatic=not chStatic
	Fresh()
end
AutoDetonate=true
function AutoDetonateToggler(b1,b2,t)
	AutoDetonate=not AutoDetonate
end
function killableToggle1(b1,b2,t)
	killable[1]=not killable[1]
end
function killableToggle2(b1,b2,t)
	killable[2]=not killable[2]
end
function killableToggle3(b1,b2,t)
	killable[3]=not killable[3]
end
function killableToggle4(b1,b2,t)
	killable[4]=not killable[4]
end
function killableToggle5(b1,b2,t)
	killable[5]=not killable[5]
end

function CheckRemote(b1,b2,t)	
	chRemote=not chRemote
	Fresh()
end
function HeroPanelFunc(b1,b2,t)	
	if HeroInfoHUD:IsClosed() then
		HeroInfoHUD:Open()
	else
		HeroInfoHUD:Close()
	end
end
local AutoForceStaff=false
function ForceStaffToggle(b1,b2,t)	
	AutoForceStaff=not AutoForceStaff
end
ShowSuicDamage,ShowBomdDamage=false, false
function ShowBD(b1,b2,t)	
	ShowBomdDamage=not ShowBomdDamage
end
function ShowSD(b1,b2,t)	
	ShowSuicDamage=not ShowSuicDamage
end
function Key(msg,code)
	if client.chat or client.console or client.loading then return end
	if code == Hotkey then
		AutoForceStaff = (msg == KEY_DOWN)
	end
end
function ForceStaffTick(tick)
	if not SleepCheck() then return end
	
	me = entityList:GetMyHero()
	if not me then return end
	local mp = entityList:GetMyPlayer()
	mines = entityList:GetEntities({classId = CDOTA_NPC_TechiesMines,team=me.team})
	enemies = entityList:GetEntities({type = LuaEntity.TYPE_HERO,team=me:GetEnemyTeam()})
	UpdateHeroInfo()
end
function Tick(tick)
	if not SleepCheck() then return end
	
	me = entityList:GetMyHero()
	if not me then return end
	local mp = entityList:GetMyPlayer()
	mines = entityList:GetEntities({classId = CDOTA_NPC_TechiesMines,team=me.team})
	enemies = entityList:GetEntities({type = LuaEntity.TYPE_HERO,team=me:GetEnemyTeam()})
	
	UpdateMineInfo()
	UpdateHeroInfo()
	--print("Update: UpdateHeroInfo")
	if SleepCheck("HudUpdate") then
		Sleep(750+250*Performance,"HudUpdate")
		--print("Update: HudUpdate")
		HudUpdate()
	end
	Sleep(10)
	if Performance>1 then
		Sleep(50*Performance)
	end
end
function FindCount(enemy,spell,damage,dmg_type)
	if not spell and spell.level>0 then 
		return "0"
	end
	local dmg=0
	local n=0
	--[[
	print("EnemyName: "..tostring(enemy.name))
	print("Me: "..tostring(me.name))
	print("SpellId: "..tostring(spell.name))
	print("Damage: "..tostring(damage))
	print("Dmg Type: "..tostring(dmg_type))
	print("Magic: "..tostring(DAMAGE_MAGC).." Phys: "..tostring (DAMAGE_PHYS))
	print("==============================")
	--]]
	local block=0
	--if enemy:DoesHaveModifier("modifier_templar_assassin_refraction_absorb") then
	if enemy.classId == CDOTA_Unit_Hero_TemplarAssassin and enemy:GetAbility(1).cd > 0 then
		block=2+enemy:GetAbility(1).level
		--print("Block count: "..tostring(block))
	end
	if damage then
		if not enemy:CanDie() or enemy:IsInvul() or (enemy:IsPhysDmgImmune() and dmg_type==DAMAGE_PHYS) or (enemy:IsMagicImmune() and dmg_type==DAMAGE_MAGC) then
			return "[Immune]"
		else
			local hlth=enemy.health
			if not enemy.alive then
				hlth=enemy.maxHealth
			end
			repeat
				n=n+1
				if block==0 then
					dmg=dmg+damage 
				else
					block=block-1
				end
				--if math.floor(enemy:DamageTaken(damage,dmg_type,me,false)) = 0 then
				--	return "[Immune]"
					--break
				--end
				--print(tostring( dmg))
			until hlth-math.floor(enemy:DamageTaken(dmg,dmg_type,me))<0 or n>=30-- or dmg==0
		end
	end
	return tostring(n)
end
local Text={}
local dummy
function HudUpdate()
	local count=0
	for i,v in ipairs(enemies) do
		local hand = v.handle
		local spells={me:GetAbility(1),me:GetAbility(2),me:GetAbility(3),me:GetAbility(6)}
		--UpdateOverlayInfo
		local ID = v.classId
		if not v:IsIllusion() and not v.meepoIllusion then
			if not icon[hand] then
				
				icon[hand]=drawMgr:CreateRect(xx+5,yy+190+26*(count+1),20,20,0x000000D0) 
				icon[hand].textureId=drawMgr:GetTextureId("NyanUI/miniheroes/"..v.name:gsub("npc_dota_hero_",""))
			end
			icon[hand].visible = not HeroInfoHUD:IsClosed()
			if not spell_icon[v.handle] then
				--print("(id) Init new enemy: "..tostring(v.handle))
				spell_icon[v.handle]={}
				textDrawObj[v.handle]={}
				spell_icon[v.handle].first=drawMgr:CreateRect(xx+40,yy+190,20,20,0x000000D0) 
				spell_icon[v.handle].first.textureId=drawMgr:GetTextureId("NyanUI/other/npc_dota_techies_land_mine")
				killable[i]=true
				--print("killable: "..tostring(i))
				if me:GetAbility(1).level>0 then
					dummy, textDrawObj[v.handle].first = HeroInfoHUD:AddText(35,32+26*count,(FindCount(v,spells[1],300+150*me:GetAbility(1).level,DAMAGE_PHYS)))
				else
					dummy, textDrawObj[v.handle].first = HeroInfoHUD:AddText(35,32+26*count,"-")
				end
				spell_icon[v.handle].second=drawMgr:CreateRect(xx+85,yy+190,20,20,0x000000D0) 
				spell_icon[v.handle].second.textureId=drawMgr:GetTextureId("NyanUI/spellicons/techies_suicide")
				if me:GetAbility(3).level>0 and suic_damage[me:GetAbility(3).level] then
					if (v.health - math.floor(v:DamageTaken(suic_damage[me:GetAbility(3).level],DAMAGE_PHYS,me)))>0 then
						dummy, textDrawObj[v.handle].second = HeroInfoHUD:AddText(80,32+26*count,"Nope")
					else
						dummy, textDrawObj[v.handle].second = HeroInfoHUD:AddText(80,32+26*count,"Yes")
						--textDrawObj[v.handle].second.text=("gg")
					end
				else
					dummy, textDrawObj[v.handle].second = HeroInfoHUD:AddText(80,32+26*count,"-")
				end
				spell_icon[v.handle].third=drawMgr:CreateRect(xx+130,yy+190,20,20,0x000000D0) 
				spell_icon[v.handle].third.textureId=drawMgr:GetTextureId("NyanUI/other/npc_dota_techies_remote_mine")
				if me:GetAbility(6).level>0 then
					local remoteDmg=remote_damage[me:GetAbility(6).level]
					if me:FindItem("item_ultimate_scepter") then 
						remoteDmg=remote_damage[me:GetAbility(6).level+1] 
					end
					dummy, textDrawObj[v.handle].third = HeroInfoHUD:AddText(125,32+26*count,FindCount(v,spells[4],remoteDmg,DAMAGE_MAGC))
				else
					dummy, textDrawObj[v.handle].third = HeroInfoHUD:AddText(125,32+26*count,"-")
				end
				
			elseif not HeroInfoHUD:IsClosed() then
				--update info
				--print("UpdateInfo: "..i)
				-----------------------------------------------------------------------------------------
				---------------------------------COUNTER-------------------------------------------------
				-----------------------------------------------------------------------------------------
				if me:GetAbility(1).level>0 then
					--local test=FindCount2(v,spells[1],300+150*me:GetAbility(1).level,DAMAGE_PHYS)
					textDrawObj[v.handle].first.text = FindCount(v,spells[1],300+150*me:GetAbility(1).level,DAMAGE_PHYS)
				end
				if me:GetAbility(3).level>0 and suic_damage[me:GetAbility(3).level] then
					if (v.health - math.floor(v:DamageTaken(suic_damage[me:GetAbility(3).level],DAMAGE_PHYS,me)))>0 then
						textDrawObj[v.handle].second.text = "Nope"
					else
						textDrawObj[v.handle].second.text = "Yes"
					end
				end
				if me:GetAbility(6).level>0 then
					local remoteDmg=remote_damage[me:GetAbility(6).level]
					if me:FindItem("item_ultimate_scepter") then 
						remoteDmg=remote_damage[me:GetAbility(6).level+1] 
					end
					textDrawObj[v.handle].third.text = FindCount(v,spells[4],remoteDmg,DAMAGE_MAGC)
				end
			end
			count=count+1
			spell_icon[v.handle].first.visible = not HeroInfoHUD:IsClosed()
			spell_icon[v.handle].second.visible = not HeroInfoHUD:IsClosed()
			spell_icon[v.handle].third.visible = not HeroInfoHUD:IsClosed()
		end
	end
end
local ForceStaffRange
function UpdateHeroInfo()
	local count=0
	me = entityList:GetMyHero()
	for i,v in ipairs(enemies) do
		local hand = v.handle
		--Remote Mine calc
		if not v:IsIllusion() and v.visible then
			local dmg=0
			local dmgEnd=0
			local explos={}
			if (AutoForceStaff or IsKeyDown(17)) and me.alive then 
				if AutoForceStaff and IsKeyDown(17) then
				else
					if not ForceStaffRange and me:FindItem("item_force_staff") then
						ForceStaffRange=Effect(me,"range_display")
						ForceStaffRange:SetVector(1, Vector(800,0,0) )
					end
					ForceStaffAct(v) 
				end
			elseif ForceStaffRange then
				ForceStaffRange = nil
			end
			if me.classId == CDOTA_Unit_Hero_Techies then
				if me:GetAbility(6).level>0 then
					local block=0
					--if v:DoesHaveModifier("modifier_templar_assassin_refraction_absorb") then
					if v.classId == CDOTA_Unit_Hero_TemplarAssassin and v:GetAbility(1).cd > 0 then
						block=2+v:GetAbility(1).level
						--print("Block count: "..tostring(block))
					end
					for i2,v2 in ipairs(mines) do
						if GetDistance2D(v,v2)<=bombInfoRange[2] and v2.healthbarOffset ~= -1 and v.health>0 and v2.health>0 and bombInfoDamage[v2.handle] and v:CanDie() then
							--[[
							print("Bomg damage: "..tostring(bombInfoDamage[v2.handle]))
							print("Bomb handle: "..tostring(v2.handle))
							print("Calc taken damage: "..tostring(math.floor(v:DamageTaken(bombInfoDamage[v2.handle],DAMAGE_MAGC,me))))
							print("==============================")
							--]]
							if block==0 then
								dmg=dmg+bombInfoDamage[v2.handle]
								--print(tostring(dmgEnd))
							else
								--print("block #"..tostring(block).." | "..tostring(dmgEnd))
								block=block-1
							end
							explos[#explos+1]=v2
							dmgEnd=v.health-math.floor(v:DamageTaken(dmg,DAMAGE_MAGC,me,false))

							if dmgEnd<0 and AutoDetonate and killable[i] then
								--print("Total bombs: "..tostring(#explos).." | Health:"..tostring(v.health).." | Dmg: "..tostring(dmg).." | Ememy: "..tostring(v.handle))
								for a,s in ipairs(explos) do
									s:SafeCastAbility(s:GetAbility(1))	
								end
								break
							end
						end
					end
					--Print Status text
					if ShowBomdDamage then
						if not statusText[hand] then 
							if bombInfoDamage[hand] then
								statusText[hand] = drawMgr:CreateText(-45,-55, 0xFFFFFF99, tostring(v.health-dmg),F14) 
							else
								statusText[hand] = drawMgr:CreateText(-45,-55, 0xFFFFFF99, "0",F14) 
							end
							statusText[hand].entity = v 
							statusText[hand].entityPosition = Vector(0,0,v.healthbarOffset+30)
						else
							statusText[hand].text=tostring(dmgEnd)
						end
						statusText[hand].visible = v.visible and v.alive 
					elseif statusText[hand] then
						statusText[hand].visible = false
					end
				end
				if me:GetAbility(3).level>0 and suic_damage[me:GetAbility(3).level] then
					if ShowSuicDamage then
						if not statusTextSuic[hand] then
							statusTextSuic[hand] = drawMgr:CreateText(-45,-55, 0xFFFFFF99, "",F14) 
							statusTextSuic[hand].entity = v 
							statusTextSuic[hand].entityPosition = Vector(0,0,v.healthbarOffset)
						end
						calc=v.health - math.floor(v:DamageTaken(suic_damage[me:GetAbility(3).level],DAMAGE_PHYS,me))
						--if v:DoesHaveModifier("modifier_templar_assassin_refraction_absorb") then
						if v:GetAbility(1).cd > 0 then
							calc="invul"
						end
						statusTextSuic[hand].text = tostring(calc)
						statusTextSuic[hand].visible = v.visible and v.alive 
					elseif statusTextSuic[hand] then
						statusTextSuic[hand].visible = false
					end
				end
			end
		end
	end
end

function ForceStaffAct(t)
	local toXY=t.position
	toXY.x = t.position.x + (math.cos(t.rotR) * 600)
    toXY.y = t.position.y + (math.sin(t.rotR) * 600)
	local CanBeForced=GetDistance2D(me, t) <= 800
	local LinkProtected=t:IsLinkensProtected()
	local forcestaff = me:FindItem("item_force_staff")
	--[[
	print(tostring(me.name))
	print(tostring(t.name))
	print(tostring(CanBeForced))
	print(tostring(GetDistance2D(me, t)))
	--]]
	if CanBeForced and not LinkProtected and forcestaff and forcestaff:CanBeCasted() and forcestaff.cd == 0 then
		local counter=0
		local dmg=0
		for i,v in ipairs(mines) do
			if GetDistance2D(toXY,v)<=bombInfoRange[2] and v.health>0 and t.health>0 and v.name == "npc_dota_techies_remote_mine" then
				if v.handle and bombInfoDamage[v.handle] then
					dmg=dmg+math.floor(t:DamageTaken(bombInfoDamage[v.handle],DAMAGE_MAGC,me,false))
					if t.health-dmg<=0 then
						me:SafeCastAbility(forcestaff, t)
						--print("force_staff_accepted")
						break
					end
				else	
					counter=counter+1
					if counter>=3 then
						me:SafeCastAbility(forcestaff, t)
						break
					end
				end
			end
		end
	end
end
function Fresh()
	for i,v in ipairs(mines) do
		if v.alive then   
			if bombRangeEffect[v.handle] then
				bombRangeEffect[v.handle] = nil
				collectgarbage("collect")
			end
		end
	end
end
function UpdateMineInfo()
    for i,v in ipairs(mines) do
        local onScreen = client:ScreenPosition(v.position)
        if v.team == me.team then
            if v.name == "npc_dota_techies_remote_mine" and not bombInfoDamage[v.handle] then
				if me:FindItem("item_ultimate_scepter") then
					bombInfoDamage[v.handle] = 150 * (me:GetAbility(6).level + 1) + 150
				else
					bombInfoDamage[v.handle] = 150 * (me:GetAbility(6).level + 1)
				end
            end
			---[[
            if onScreen then
                if v.alive then    
                    if not bombRangeEffect[v.handle] then
                        bombRangeEffect[v.handle] = Effect(v,"range_display")
						if v.name == "npc_dota_techies_land_mine" and chLand then
                            bombRangeEffect[v.handle]:SetVector(1, Vector(200,0,0) )
                        elseif v.name == "npc_dota_techies_stasis_trap" and chStatic then
                            bombRangeEffect[v.handle]:SetVector(1, Vector(450,0,0) )
                        elseif v.name == "npc_dota_techies_remote_mine" and chRemote then
                            bombRangeEffect[v.handle]:SetVector(1, Vector(bombInfoRange[2],0,0) )
                        end
                    end
				else
					if bombRangeEffect[v.handle] then
                        bombRangeEffect[v.handle] = nil
                        collectgarbage("collect")
                    end
				end
            end
			-- ]]
        end
    end
end

function Load()
	if PlayingGame() then
		me = entityList:GetMyHero()
		if not me then
			script:Disable()
		elseif me.classId == CDOTA_Unit_Hero_Techies then
			LoadPerformanceConf()
			myHUD = EasyHUD.new(xx,yy,140*monitor,135*monitor,"Techies script",0x111111C0,-1,true,false)
			myHUD:AddCheckbox(0,2,20,20,"Auto Detonate",AutoDetonateToggler,true)
			myHUD:AddCheckbox(0,22,20,20,"Show Range [ Land Mines ]",CheckLand,true)
			myHUD:AddCheckbox(0,42,20,20,"Show Range [ Stasis Trap ]",CheckStatic,false)
			myHUD:AddCheckbox(0,62,20,20,"Show Range [ Remote Mines ]",CheckRemote,true)
			myHUD:AddCheckbox(0,82,20,20,"Hero Panel ",HeroPanelFunc,true)
			myHUD:AddCheckbox(70,82,20,20,"Auto ForceStaff",ForceStaffToggle,false)
			myHUD:AddButton(120,110,40,40, 0x60615FFF,"P: "..tostring(Performance),SavePerformanceConf)
			myHUD:AddCheckbox(0,102,20,20,"Show Bomb Damage",ShowBD,false)
			myHUD:AddCheckbox(0,122,20,20,"Show Suic Damage",ShowSD,false)
			HeroInfoHUD = EasyHUD.new(xx,yy+145*monitor,140*monitor,135*monitor,"Hero Panel",0x111111C0,-1,false,false)
			HeroInfoHUD:AddCheckbox(1,1+26*1,22,22,"",killableToggle1,true)
			HeroInfoHUD:AddCheckbox(1,1+26*2,22,22,"",killableToggle2,true)
			HeroInfoHUD:AddCheckbox(1,1+26*3,22,22,"",killableToggle3,true)
			HeroInfoHUD:AddCheckbox(1,1+26*4,22,22,"",killableToggle4,true)
			HeroInfoHUD:AddCheckbox(1,1+26*5,22,22,"",killableToggle5,true)
			
			--HeroInfoHUD:AddCheckbox(0,2,20,20,"Auto Detonate",nil,true)
			--myHUD:Minimize(false)
			play = true
			script:RegisterEvent(EVENT_TICK,Tick)
			--script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(Load)
			--print("techies detected")
			client:ExecuteCmd("dota_player_units_auto_attack_after_spell 0")
			
		else
			--print("Only forcestaff")
			play = true
			script:RegisterEvent(EVENT_TICK,ForceStaffTick)
			--script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(Load)
		end
	end
end

function GameClose()
	collectgarbage("collect")
	if play then
		script:UnregisterEvent(Tick)
		--script:UnregisterEvent(Key)
		play = false
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)