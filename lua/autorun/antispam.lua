if game.SinglePlayer() then return end

UAS = UAS or {}

UAS.default = {
	enabled = 1,
	frzen = 1,
	frzrep = 0.5,
	delrep = 1.2,

	lagdt = 1.2,

	minrep = 0.15,
	blockspawn = 0,

	coef_size = 0.008,
	coef_equal = 0.2,
	coef_total = 0.1,
	coef_base = 1.2,
	coef_exp = 0.8,
	coef_lift = 0.04,
	coef_push = 0,
	coef_stretch = 150,
	
	coef_ratinginf = 0.3,
	coef_ratingexp = 0.9,

	mul_effect = 0.6,
	mul_prop = 1,
	mul_ragd = 8,
	mul_sent = 2,
	mul_veh = 2.5,
	
	recharge_delay = 0.6,
	recharge_amount = 0.03,
	recharge_length = 3.5,
	recharge_grade = 0.3
}
UAS.settings = table.Copy(UAS.default)

UAS.names = {
	enabled = "Antispam Enabled",
	frzen = "Ghosting Enabled",
	frzrep = "Freeze Ratng",
	delrep = "Delete Rating",

	lagdt = "Lagdelay (sec)",
	minrep = "Min. Spawn Capability",
	blockspawn = "Block Spawn",

	coef_size = "Size Coefficient",
	coef_equal = "Same-Entity Coefficient",
	coef_total = "Total-Entity Coefficient",
	coef_base = "Exponent Base",
	coef_exp = "Exponent",
	coef_lift = "Lift",
	coef_push = "Push",
	coef_stretch = "Stretch",
	coef_ratinginf = "Spawn Capability Influence",
	coef_ratingexp = "Spawn Capability Exponent",

	mul_effect = "Effect Multiplier",
	mul_prop = "Prop Multiplier",
	mul_ragd = "Ragdoll Multiplier",
	mul_sent = "SENT Multiplier",
	mul_veh = "Vehicle Multiplier",
	
	recharge_delay = "Recharge Delay",
	recharge_amount = "Recharge Amount",
	recharge_length = "Recharge Length",
	recharge_grade = "Recharge Grade"
}

function UAS.calcrating(size,equal_ents,total_ents,ply_rating,dtime,multiplier)
	size = (1+size) * UAS.settings.coef_size
	dtime = 1-math.Clamp(dtime,0,1)
	local spm = (equal_ents*UAS.settings.coef_equal)+(total_ents*UAS.settings.coef_total)
	local mr = UAS.settings.coef_lift + math.Max(((((UAS.settings.coef_base+(size-UAS.settings.coef_push))^(1+spm+UAS.settings.coef_exp))) - ((1-UAS.settings.coef_ratinginf)+((ply_rating)^UAS.settings.coef_ratingexp * ((1-dtime) + UAS.settings.coef_ratinginf)))) * multiplier,0) / UAS.settings.coef_stretch
	return mr, spm, size
end

function UAS.calcrating_def(size,equal_ents,total_ents,ply_rating,dtime,multiplier)
	size = (1+size) * UAS.default.coef_size
	dtime = 1-math.Clamp(dtime,0,1)
	local spm = (equal_ents*UAS.default.coef_equal)+(total_ents*UAS.default.coef_total)
	local mr = UAS.default.coef_lift + math.Max(((((UAS.default.coef_base+(size-UAS.default.coef_push))^(1+spm+UAS.default.coef_exp))) - ((1-UAS.default.coef_ratinginf)+((ply_rating)^UAS.default.coef_ratingexp * ((1-dtime) + UAS.default.coef_ratinginf)))) * multiplier,0) / UAS.default.coef_stretch
	return mr, spm, size
end

if SERVER then
	
	AddCSLuaFile()
	AddCSLuaFile("cl_uantispam_skin.lua")
	AddCSLuaFile("cl_uantispam_menu.lua")
	
	util.AddNetworkString("uantispam_info")
	util.AddNetworkString("uantispam_pinf")
	util.AddNetworkString("uantispam_valueexchange")
	
	print("[+] Uke's antispam loaded serverside.")
	
	local SysTime = SysTime
	local CurTime = CurTime
	local player = player
	local math = math
	
	UAS.filename = "ukes_antispam_config_2014.txt"
	UAS.delaysave = false
	UAS.savetime = 0
	
	function UAS.saveConfig()
		local configFile = util.TableToKeyValues(UAS.settings)
		file.Write(UAS.filename, configFile)
		print("[UAS]Configfile saved.")
	end
	
	function UAS.loadConfig()
		if file.Exists(UAS.filename,"DATA") then
			local configFile = file.Read(UAS.filename,"DATA")
			if (configFile and #configFile > 0) then
				local tab = util.KeyValuesToTable(configFile)
				table.Merge( UAS.settings, tab )
				print("[UAS]Configfile loaded.")
			else
				UAS.settings = table.Copy(UAS.default)
				print("[UAS]Default config loaded.")
			end
		end
	end
	
	net.Receive("uantispam_valueexchange", function( _, ply)
		if not ply:IsSuperAdmin() then return end
		local opt = net.ReadString()
		local val = net.ReadFloat()
		if not UAS.settings[opt] or not val then return end
		UAS.settings[opt] = val
		local name = UAS.names[opt] or opt
		print("[UAS]"..ply:Name()..": "..name.." = "..tostring(val))
		net.Start("uantispam_valueexchange")
			net.WriteString(opt)
			net.WriteFloat(val)
		net.Broadcast()
		UAS.delaysave = true
		UAS.savetime = SysTime() + 4
	end)
	
	UAS.loadConfig()
	
	hook.Add("Think","uas_sync",function()
		if not UAS.delaysave then return end
		if UAS.savetime > SysTime() then return end
		UAS.delaysave = false
		UAS.savetime = 0
		UAS.saveConfig()
	end)
	
	local spawnh = spawnh or {}
	local entis = entis or {}
	
	local function cananyway(ply)
		if ply.EV_GetRank and ply:EV_GetRank() == "guest" then return false end
		return false --#	
	end
	------------------------------------------------------------------
	------------------------------------------------------------------
	for k,v in pairs(player.GetAll()) do
		v.rep = 1
		v.st = 0
		v.ls = 0
		v.spn = 0
		spawnh[v] = spawnh[v] or {}
		v:SetNWFloat( "spawn_rep", v.rep )
		timer.Simple(0.2+v:Ping()/1000,function()
		for l,j in pairs(UAS.settings) do
			net.Start("uantispam_valueexchange")
				net.WriteString(l)
				net.WriteFloat(j)
			net.Send(v)
			end
		end)
	end
	
	hook.Add("PlayerInitialSpawn","spwn1",function(ply)
		ply.rep = 1
		ply.st = 0
		ply.ls = 0
		ply.spn = 0
		spawnh[ply] = {}
		ply:SetNWFloat( "spawn_rep", ply.rep )
		timer.Simple(0.2+ply:Ping()/1000,function()
		for l,j in pairs(UAS.settings) do
			net.Start("uantispam_valueexchange")
				net.WriteString(l)
				net.WriteFloat(j)
			net.Send(ply)
		end
		end)
	end)
	------------------------------------------------------------------
	------------------------------------------------------------------

	local PhysObj = FindMetaTable( "PhysObj" )
	
	PhysObj.oldfrz = PhysObj.oldfrz or PhysObj.EnableMotion

	local function propIsNotFree(e)
		local trace = { start = e:GetPos(), endpos = e:GetPos(), filter = e, ignoreworld = true }
		local tr = util.TraceEntity( trace, e ) 
		return tr.Hit
	end
	
	hook.Add("CanPlayerUnfreeze","dgsgahrthh",function( ply, ent, phys )
		/*if UAS.settings.frzen ~= 0 then
			--if propIsNotFree(ent) then return false end
		end*/
		if ent.uantispam_frzn == true then return false end
	end)
	
	hook.Add("EntUnfreeze","dgsgahrthh",function( ent, phys )
		/*if UAS.settings.frzen ~= 0 then
			--if propIsNotFree(ent) then return false end
		end*/
		if ent.uantispam_frzn == true then return false end
	end)
	
	function PhysObj:EnableMotion(bool)
		if not self:IsValid() then return end
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
			if phys:IsValid() and ent.uantispam_mtn ~= nil then
				phys:EnableMotion(ent.uantispam_mtn)
			end
			ent.uantispam_mtn = nil
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
	
	local function updaterep(ply,mr)
		local nr = math.Clamp(ply.rep - mr,0,1)
		if nr == ply.rep then return end
		ply.rep = nr
		ply:SetNWFloat( "spawn_rep", nr )
	end
	
	local function sendinfo(ply,type,num)
		net.Start("uantispam_info")
			net.WriteVector(Vector(type,num,0))
		net.Send(ply)
	end
	
	hook.Add("PhysgunDrop", "uantispam_pgpu",function(ply, e)
		if e.uantispam_frzn == true then
			if propIsNotFree(e) then
				local phys = e:GetPhysicsObject()
				if phys:IsValid() then
					phys:EnableMotion(false)
				end
			else
				e.uantispam_mtn = nil
				unfreeze(e)
			end
		end
	end)
	
	local function spawned(v,m,mul,e)
		if v.st == 0 then v.st = RealTime() end
		local ls = v.ls
		local st = RealTime()
		v.ls = st
		v.spn = v.spn + 1
		if spawnh[v][m] ~= nil then
			spawnh[v][m] = spawnh[v][m] + 1
		else
			spawnh[v][m] = 1
		end
		local c = (e:OBBMaxs() - e:OBBMins()):Length()
		local n = spawnh[v][m]
		local mr, spm, c = UAS.calcrating(c,n,v.spn,v.rep,st-ls,mul)
		
		updaterep(v,mr)
		
		return mr, spm, c
	end
	
	hook.Add("EntityRemoved","regain",function(e)
		local v = entis[e]
		if v ~= nil and v ~= {} and v.spwnr ~= nil and IsValid(v.spwnr) then
			local ply = v.spwnr
			local mr = v.mr
			updaterep(ply,-mr*0.6)
		end
	end)
	
	local t = RealTime()
	hook.Add("Think","repthink",function()
		local lt = t
		t = RealTime()
		local dt = t-lt
		
		for k,v in pairs(player.GetAll()) do
			if v.ls ~= nil and (v.ls + UAS.settings.recharge_delay) < t then
				if v.rep < 1 then
					updaterep(v,-((dt*v.rep*UAS.settings.recharge_grade+UAS.settings.recharge_amount)/UAS.settings.recharge_length))
				elseif spawnh[v] ~= {} then
					updaterep(v,0)
					spawnh[v] = {}
					v.spn = 0
					v.st = 0
				end
			end
		end
		
		if UAS.settings.enabled == 0 then return end
		if dt > UAS.settings.lagdt then
			local frz = {}
			local del = {}
			for k, v in pairs(entis) do
				local ent = v.ent
				if v.spm > UAS.settings.frzrep then
					if ent == nil or not IsValid(ent) then
						entis[k] = nil
					else
						frz[v.spwnr] = frz[v.spwnr] or 0
						del[v.spwnr] = del[v.spwnr] or 0
						local phys = ent:GetPhysicsObject()
						if phys:IsValid() and v.spm < UAS.settings.delrep then
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
					sendinfo(k,1,v)
				end
			end
			for k,v in pairs(frz) do
				if IsValid(k) and k ~= nil and v > 0 then
					sendinfo(k,0,v)
				end
			end
		end
	end)
	
	hook.Add("PlayerSpawnObject","spwn1",function(ply, m, n)
		if UAS.settings.enabled == 0 then return end
		if ply.rep < UAS.settings.minrep and not cananyway(ply) and UAS.settings.blockspawn == 1 then
			return false
		end
	end)
	
	local function spawnHub(ply,e,m,mul,isdupe)
		e:SetCollisionGroup(COLLISION_GROUP_WORLD)
		hook.Call("postspawned",GAMEMODE,ply,e,m,mul,isdupe)
	end
	
	function sendent(ply,ent,bit)
		timer.Simple((ply:Ping( )/1000) + 0.1, function()
			net.Start("uantispam_pinf")
				net.WriteBit(bit)
				net.WriteEntity( ent )
			net.Send(ply)
		end)
	end
	
	local function spawnHub2(ply,e,m,mul,isdupe)
		if not IsValid(e) then return end
		local mr, spm, c = 0, 0, 0
		local phys = e:GetPhysicsObject()
		if phys:IsValid() and not phys:IsMoveable() then
			mul = mul * 0.1
		end
		if m == "" then
			if ply.rep < UAS.settings.minrep then
				mr, spm, c = spawned(ply,type(e),0.4*mul,e)
			else
				mr, spm, c = spawned(ply,type(e),mul,e)
			end
		else
			if ply.rep < UAS.settings.minrep then
				mr, spm, c = spawned(ply,m,0.4*mul,e)
			else
				mr, spm, c = spawned(ply,m,mul,e)
			end
		end
		e:SetCollisionGroup(COLLISION_GROUP_NONE)
		local spm = ((mr*0.5)+(spm*0.3)+(c*0.2))*0.6
		
		if (propIsNotFree(e) and UAS.settings.frzen == 1) or (UAS.settings.blockspawn == 0 and ply.rep < UAS.settings.minrep and not cananyway(ply) and UAS.settings.enabled == 1 ) then
			if isdupe then
				phys:EnableMotion(false)
			elseif phys:IsValid() and phys:IsMoveable() then
				freeze(e,phys)
			end
		end
		if spm > UAS.settings.delrep then
			sendent(ply,e,true)
		elseif spm > UAS.settings.frzrep then

			sendent(ply,e,false)
		end
		entis[e] = {["ent"] = e, ["mr"] = mr,["spm"] = spm, ["spwnr"] = ply}
	end
	
	hook.Add("postspawned","afafgsgshr",function(ply,e,m,mul,isdupe)
		timer.Simple(0.001,function() spawnHub2(ply,e,m,mul,isdupe) end)
	end)
	
	if cleanup then
		UAS.oldcleanup = UAS.oldcleanup or cleanup.Add
		function cleanup.Add(ply, Type, ent)
			if not IsValid(ply) or not IsValid(ent) then return UAS.oldcleanup(ply, Type, ent) end
			
			if Type ~= "constraints" then
				local mult = 1
				if Type == "props" or Type == "duplicates" or Type == "stacks" or Type == "AdvDupe2" then mult = UAS.settings.mul_prop
				elseif Type == "ragdolls" then mult = UAS.settings.mul_ragd
				elseif Type == "sents" then mult = UAS.settings.mul_sent
				elseif Type == "vehicles" then mult = UAS.settings.mul_veh
				elseif Type == "effects" then mult = UAS.settings.mul_effect end
				
				spawnHub(ply,ent,ent:GetModel(),mult, (Type == "duplicates" or Type == "AdvDupe2"))
			end
			
			return UAS.oldcleanup(ply, Type, ent)
		end
	end
	
	/*hook.Add("PlayerSpawnedEffect","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,UAS.settings.mul_effect)
	end)
	hook.Add("PlayerSpawnedProp","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,UAS.settings.mul_prop)
	end)
	hook.Add("PlayerSpawnedRagdoll","spwnd",function(ply,mdl,ent)
		spawnHub(ply,ent,mdl,UAS.settings.mul_ragd)
	end)
	hook.Add("PlayerSpawnedSENT","spwnd",function(ply,ent)
		spawnHub(ply,ent,"",UAS.settings.mul_sent)
	end)
	hook.Add("PlayerSpawnedVehicle","spwnd",function(ply,ent)
		spawnHub(ply,ent,"",UAS.settings.mul_veh)
	end)*/
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
	local stts = {}
	local pi = math.pi
	local LP = LocalPlayer
	
	local te
	
	hook.Add("Think", "tet", function()
		if LP().GetEyeTrace then
			local tr = LP():GetEyeTrace()
			if tr then
				te = tr.Entity
			else
				te = nil
			end
		else
			te = nil
		end
	end)
	
	print("[+] Uke's antispam loaded clientside.")

	function UAS.SendToServer(opt,val)
		if not LP():IsSuperAdmin() then return end
		net.Start("uantispam_valueexchange")
			net.WriteString(opt)
			net.WriteFloat(val)
		net.SendToServer()
	end
	
	net.Receive("uantispam_valueexchange", function()
		local opt = net.ReadString()
		local val = net.ReadFloat()
		UAS.settings[opt] = val
	end)
	
	hook.Add("HUDPaint","sdaf",function()
		if UAS.settings.enabled == 0 then return end
		local rep = LP():GetNWFloat( "spawn_rep" ) or 1
		
		local txt = "Spawn Capability: "..tostring(math.floor(rep*100)).."%"
		if rep < UAS.settings.minrep then
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

		if IsValid(te) and te ~= nil and not te:IsWorld() then
			if te.uans_b ~= nil then
				surface.SetDrawColor(255,255,255,255)
				if te.uans_b == 1 then
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
		local ent = net.ReadEntity()
		ent.uans_b = b
		if UAS.settings.enabled == 0 then return end
		table.insert(prps, {["del"] = (b == 1 and true or false), ["vel"] = -0.6} )		
	end)
	
	include("cl_uantispam_menu.lua")
	include("cl_uantispam_skin.lua")
	
end