require("libs.DrawManager3D")

local play = false
local key = string.byte("M")
local activated = true 
local rec1 = nil
local rec2 = nil

function Tick(tick)
	if client.console then return end	
	if activated then	
		if not rec1.visible then
			rec1.visible = true
			rec2.visible = true
		end
		local me = entityList:GetMyHero()
		if not me then return end		
		local runes = entityList:GetEntities(function (ent) return ent.classId==CDOTA_Item_Rune and GetDistance2D(ent,me) < 200 end)[1]		
		local ally = entityList:FindEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v ~= me and v.controllable end)
		if runes then 
			entityList:GetMyPlayer():Select(me)
			entityList:GetMyPlayer():TakeRune(runes)
		end
		if ally then
			for i,v in ipairs(ally) do
				local r = entityList:GetEntities(function (ent) return ent.classId==CDOTA_Item_Rune and GetDistance2D(ent,v) < 200 end)[1]
				if r then
					entityList:GetMyPlayer():Select(v)
					entityList:GetMyPlayer():TakeRune(r)
				end
			end
		end
	elseif rec1.visible then
		rec1.visible = false
		rec2.visible = false			
	end
end

function Key(msg,code)
	if msg ~= KEY_UP and code == key and not client.chat then
		activated = not activated
	end
end

function Load()
	if PlayingGame() then
		rec1 = drawMgr3D:CreateRect(Vector(-2272,1792,0), Vector(0,0,0), Vector2D(0,0), Vector2D(30,30), 0x000000ff, drawMgr:GetTextureId("NyanUI/other/fav_heart"))
		rec2 = drawMgr3D:CreateRect(Vector(3000,-2450,0), Vector(0,0,0), Vector2D(0,0), Vector2D(30,30), 0x000000ff, drawMgr:GetTextureId("NyanUI/other/fav_heart"))
		play = true
		script:RegisterEvent(EVENT_KEY,Key)
		script:RegisterEvent(EVENT_FRAME,Tick)
		script:UnregisterEvent(Load)
	end
end

function GameClose()
	if play then
		rec1 = nil
		rec2 = nil
		script:UnregisterEvent(Tick)
		script:UnregisterEvent(Key)
		script:RegisterEvent(EVENT_TICK,Load)
		play = false
	end
end

script:RegisterEvent(EVENT_TICK,Load)
script:RegisterEvent(EVENT_CLOSE,GameClose)