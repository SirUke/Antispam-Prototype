local frzrep = 0.5	--props with a rating higher than that will get frozen on lag
local delrep = 1.2	--props with a rating higher than that will get deleted on lag

local lagdt = 1.8 --if a servertick takes longer than that(sec) it is concidered as lag

local minrep = 0.1	--minimum rating a player has to have to be able to spawn
local blockspawn = false --block players from spawning when their rating is too low
						--when set to false it will freeze instead
if SERVER then
	
	AddCSLuaFile()
	
	util.AddNetworkString("uantispam_info")
	util.AddNetworkString("uantispam_pinf")
	
	print("[+] Uke's antispam loaded serverside.")
	
	local SysTime = SysTime
	local CurTime = CurTime
	local player = player
	local math = math
	
	local nr = 1
	local spawnh = spawnh or {}
	local entis = entis or {}
	
	local t = CurTime()
	
	local function cananyway(ply)
		if ply.EV_GetRank and ply:EV_GetRank() == "guest" then return false end
		return true	
	end
	------------------------------------------------------------------
	------------------------------------------------------------------
	for k,v in pairs(player.GetAll()) do
		v.rep = 1
		v.st = CurTime()
		v.ls = CurTime()
		v.spn = 0
		spawnh[v] = spawnh[v] or {}
		v:SetNWFloat( "spawn_rep", v.rep )
	end
	
	hook.Add("PlayerInitialSpawn","spwn1",function(ply)
		ply.rep = 1
		ply.st = CurTime()
		ply.ls = CurTime()
		ply.spn = 0
		spawnh[v] = {}
		ply:SetNWFloat( "spawn_rep", ply.rep )
	end)
	------------------------------------------------------------------
	------------------------------------------------------------------
	
	function unfreeze(ent)
		if ent.uantispam_frzn == true then
			ent.uantispam_frzn = nil
			
			ent:SetRenderMode(ent.uantispam_orm)
			ent.uantispam_orm = nil
			ent:SetMaterial(ent.uantispam_omat)
			ent.uantispam_omat = nil
			ent:DrawShadow(true)
			ent:SetCollisionGroup(ent.uantispam_ocg)
			ent.uantispam_ocg = nil

			ent:SetColor(Color(ent.uantispam_oc.r, ent.uantispam_oc.g, ent.uantispam_oc.b, ent.uantispam_oc.a))
			ent.uantispam_oc = nil
	
	
			ent:SetCollisionGroup(COLLISION_GROUP_NONE)
			ent.uantispam_cg = nil
	
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:EnableMotion(ent.uantispam_mtn)
			end
			ent.uantispam_mtn = nil
		end
	end
	
	local function propIsNotFree(e)
		local trace = { start = e:GetPos(), endpos = e:GetPos(), filter = e, ignoreworld = true }
		local tr = util.TraceEntity( trace, e ) 
		return tr.Hit
	end
	
	hook.Add("PhysgunDrop", "uantispam_pgpu",function(ply, e)
		if e.uantispam_frzn == true then
			
			if propIsNotFree(e) then
				local phys = e:GetPhysicsObject()
				if phys:IsValid() then
					phys:EnableMotion(false)
				end
			else
				e.uantispam_mtn = false
				unfreeze(e)
			end
		end
	end)
	
	_R.PhysObj.oldfrz = _R.PhysObj.oldfrz or _R.PhysObj.EnableMotion
	
	hook.Add("CanPlayerUnfreeze","dgsgahrthh",function( ply, ent, phys )
		if propIsNotFree(ent) then return false end
	end)
	
	hook.Add("EntUnfreeze","dgsgahrthh",function( ent, phys )
		if propIsNotFree(ent) then return false end
	end)
	
	function _R.PhysObj:EnableMotion(bool)
		local ent = self:GetEntity( )
		
		local canperformaction = true
		
		if bool then
			canperformaction = hook.Call("EntUnfreeze",GAMEMODE,ent,self)
		else
			canperformaction = hook.Call("EntFreeze",GAMEMODE,ent,self)
		end
		
		if canperformaction == nil or canperformaction == true then
			self:oldfrz(bool)
		end
	end
		
	local function freeze(ent,phys)		
		ent:DrawShadow(false)
		ent.uantispam_oc = ent.uantispam_oc or ent:GetColor()
		ent:SetColor(Color(100,160,255,60))
		
		ent.uantispam_omat = ent.uantispam_omat or ent:GetMaterial()
		ent:SetMaterial("models/shiny")
		
		ent.uantispam_orm = ent.uantispam_orm or ent:GetRenderMode()
		ent:SetRenderMode(1)
		
		ent.uantispam_ocg = ent:GetCollisionGroup()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
		ent.uantispam_cg = COLLISION_GROUP_WORLD

		ent.uantispam_mtn = phys:IsMoveable()
		phys:EnableMotion(false)

		ent.uantispam_frzn = true
	end
	
	local function spawned(v,m,mul,e)
		if v.st == 0 then v.st = CurTime() end
		local ls = v.ls
		local st = CurTime()
		v.ls = st
		v.spn = v.spn + 1
		if spawnh[v][m] ~= nil then
			spawnh[v][m] = spawnh[v][m] + 1
		else
			spawnh[v][m] = 1
		end
		local c = (e:OBBMaxs() - e:OBBMins()):Length() * 0.00033
		local n = spawnh[v][m]
		local dt = 1-math.Clamp(st-ls,0,1)
		local spm = (n*0.7)+(v.spn*0.4)
		local mr = math.Clamp(((1.022+c)^(1+spm))-1 - ((1-v.rep) * (1-dt)),0,1) * mul
		
		v.rep = math.Clamp(v.rep - mr,0,1)
		
		v:SetNWFloat( "spawn_rep", v.rep )
		
		return mr, c, spm
	end
	
	hook.Add("EntityRemoved","regain",function(e)
		local v = entis[e]
		if v ~= nil and v ~= {} and v.spwnr ~= nil and IsValid(v.spwnr) then
			local ply = v.spwnr
			local mr = v.mr
			ply.rep = math.Clamp(ply.rep + mr*0.6,0,1)
		end
	end)
	
	hook.Add("Think","repthink",function()
		local lt = t
		t = RealTime()
		local dt = t-lt
		
		for k,v in pairs(player.GetAll()) do
			v:SetNWFloat( "spawn_rep", v.rep )
			if v.ls ~= nil and v.ls + 0.6 < t then
				if v.rep < 1 then
					v.rep = math.Min(v.rep + (dt*(v.rep+0.05))/3,1)
				elseif spawnh[v] ~= {} then
					spawnh[v] = {}
					v.spn = 0
					v.st = 0
				end
			end
		end
		
		if dt > lagdt then
			local frz = {}
			local del = {}
			for k, v in pairs(entis) do
				local ent = v.ent
				if v.spm > frzrep then
					if ent == nil or not IsValid(ent) then
						entis[k] = nil
					else
						frz[v.spwnr] = frz[v.spwnr] or 0
						del[v.spwnr] = del[v.spwnr] or 0
						local phys = ent:GetPhysicsObject()
						if phys:IsValid() and v.spm < delrep then
							if ent.uantispam_frzn == nil or ent.uantispam_frzn ~= true then
								freeze(ent, phys)
								frz[v.spwnr] = frz[v.spwnr] + 1
							end
						else
							ent:Remove()
							del[v.spwnr] = del[v.spwnr] + 1
						end
					end
				end
			end
			for k,v in pairs(del) do
				if IsValid(k) and k ~= nil and v > 0 then
					net.Start("uantispam_info")
						net.WriteVector(Vector(1,v,0))
					net.Send(k)
				end
			end
			for k,v in pairs(frz) do
				if IsValid(k) and k ~= nil and v > 0 then
					net.Start("uantispam_info")
						net.WriteVector(Vector(0,v,0))
					net.Send(k)
				end
			end
		end
	end)
	
	hook.Add("PlayerSpawnObject","spwn1",function(ply, m, n)
		if ply.rep < minrep and not cananyway(ply) and blockspawn then
			return false
		end
	end)
	
	local function spawnHub(ply,e,m,mul)
		e:SetCollisionGroup(COLLISION_GROUP_WORLD)
		hook.Call("postspawned",GAMEMODE,ply,e,m,mul)
	end
	
	local function spawnHub2(ply,e,m,mul)
		local mr, spm, c = 0, 0, 0
		
		local phys = e:GetPhysicsObject()
		if phys:IsValid() and not phys:IsMoveable() then
			mul = mul * 0.1
		end
		if m == "" then
			if ply.rep < minrep then
				mr, spm, c = spawned(ply,type(e),0.4*mul,e)
			else
				mr, spm, c = spawned(ply,type(e),mul,e)
			end
		else
			if ply.rep < minrep then
				mr, spm, c = spawned(ply,m,0.4*mul,e)
			else
				mr, spm, c = spawned(ply,m,mul,e)
			end
		end
		
		e:SetCollisionGroup(COLLISION_GROUP_NONE)
		
		local spm = ((mr*0.5)+(spm*0.3)+(c*0.2))*0.6

		if propIsNotFree(e) or (not blockspawn and ply.rep < minrep and not cananyway(ply)) then
			if phys:IsValid() and phys:IsMoveable() then
				freeze(e,phys)
			end
		end
		
		if spm > delrep then
			net.Start("uantispam_pinf")
				net.WriteBit(true)
				net.WriteEntity( e )
			net.Send(ply)
		elseif spm > frzrep then
			net.Start("uantispam_pinf")
				net.WriteBit(false)
				net.WriteEntity( e )
			net.Send(ply)
		end
		
		entis[e] = {["ent"] = e, ["mr"] = mr,["spm"] = spm, ["spwnr"] = ply}
	end
	
	hook.Add("postspawned","afafgsgshr",function(ply,e,m,mul)
		timer.Simple(0.001,function() spawnHub2(ply,e,m,mul) end)
	end)
	
	hook.Add("PlayerSpawnedEffect","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,0.6)
	end)
	hook.Add("PlayerSpawnedProp","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,1)
	end)
	hook.Add("PlayerSpawnedRagdoll","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,8)
	end)
	hook.Add("PlayerSpawnedVehicle","spwnd",function(ply,ent)
		spawnHub(ply,ent,"",2.5)
	end)
end

if CLIENT then
	local chat = chat
	local math = math
	local surface = surface
	local ScrW, ScrH = ScrW, ScrH
	local CurTime = CurTime
	local FrameTime =  FrameTime
	local msgs = {}
	local prps = {}
	local pi = math.pi
	local LP = LocalPlayer()
	
	print("[+] Uke's antispam loaded clientside.")
	
	hook.Add("HUDPaint","sdaf",function()
		local rep = LocalPlayer():GetNWFloat( "spawn_rep" ) or 1
		
		local txt = "Spawn Capability: "..tostring(math.floor(rep*100)).."%"
		if rep < minrep then
			local flsh = (math.sin(SysTime()*30)+1)/2
			surface.SetTextColor(Color(205*flsh + 50,50,50,255))
		elseif rep < 1 then
			local flsh = (math.sin(SysTime()*8)+1)/2
			local m = 200*(1-rep)
			local n = 255-m
			surface.SetTextColor(Color(m*flsh + n,m*flsh + n,n,255-235*rep))
		else
			surface.SetTextColor(Color(255,255,255,20))
		end
		surface.SetFont("ChatFont")
		local tsx,tsy = surface.GetTextSize(txt)
		local tpx, tpy = ScrW() -tsx- 10, ScrH() - tsy - 10
		surface.SetTextPos(tpx, tpy)
		surface.DrawText(txt)
		
		local tr = LP:GetEyeTrace().Entity
		
		if IsValid(tr) and tr ~= nil and not tr:IsWorld() then
			if uantispam_b ~= nil then
				surface.SetDrawColor(255,255,255,255)
				if tr.uantispam_b == 1 then
					surface.SetMaterial(Material("icon16/bullet_orange.png"))
				else
					surface.SetMaterial(Material("icon16/bullet_blue.png"))
				end
				
				surface.DrawTexturedRect(tpx-12,tpy,16,16)
			end
		end
		
		local mc = #msgs
		local cx, cy = chat.GetChatBoxPos( )
		local csx,csy= 200, 200
		local ft = FrameTime()
		local ct = CurTime()
		for k,v in ipairs(msgs) do
			local t = v.t
			local mt = v.t+13-ct
			if mt <= 0 then table.remove(msgs, k) else
				local k = mc - k
				local dx, dy = cx+20, cy+csy+4+22*(k-1)
				local x, y = v.pos.x, v.pos.y
				x = Lerp(ft, x, dx)
				y = Lerp(ft, y, dy)
				v.pos.x, v.pos.y = x, y
				
				local cy = math.Clamp(mt,0,1)
				local a = 220 * cy
				local Col = Color(255,255,255,a)
				local STR = ""
				if v.type == 0 then
					Col = Color(100,160,255,a)
					STR = v.n.." entities frozen due to lag."
				elseif v.type == 1 then
					Col = Color(160,90,40,a)
					STR = v.n.." entities removed due to lag."
				end
				draw.RoundedBoxEx( 8, x, y, 224, 18, Col, (k == 0 and true or false), (k == 0 and true or false), (k == mc-1 and true or false), (k == mc-1 and true or false) )
				draw.DrawText(STR,"ChatFont",x+6,y+2,Color(255,255,255,a),TEXT_ALIGN_LEFT)
			end
		end
		
		for k,v in ipairs(prps) do
			local vel = math.Min(v.vel + ft,1)
			v.vel = vel
			local v2 = vel < 0 and vel/0.6 or vel
			local cos = math.cos(vel*(pi/2))
			local co2 = math.cos(v2*(pi/2))
			local x, y = tpx - 12 - cos*100, tpy
			
			local a = 55+200*co2
			
			surface.SetDrawColor(255,255,255,a)
			if v.del == true then
				surface.SetMaterial(Material("icon16/bullet_orange.png"))
			else
				surface.SetMaterial(Material("icon16/bullet_blue.png"))
			end
			
			surface.DrawTexturedRect(x,y,16,16)
			
			if vel == 1 then table.remove(prps, k) end
		end
		
	end)
	
	net.Receive("uantispam_info", function()
		local v = net.ReadVector()
		local x, y = chat.GetChatBoxPos( )
		local sx,sy= 200,200
		local k = #msgs
		table.insert(msgs, {["type"] = v.x, ["n"] = v.y, ["pos"] = {["x"] = x - 400, ["y"] = y + 4 + sy}, ["t"] = CurTime()} )		
	end)
	
	net.Receive("uantispam_pinf", function()
		local b = net.ReadBit()
		local e = net.ReadEntity()
		e.uantispam_b = 1
		table.insert(prps, {["del"] = (b == 1 and true or false), ["vel"] = -0.6} )		
	end)
	
end