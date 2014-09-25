if SERVER then return end
local surface = surface
local draw = draw
local Color = Color
local math = math
local gui = gui
local ScrW, ScrH = ScrW, ScrH

UAS.frameopen = UAS.frameopen or false

UAS.gset = {
		x = 1,
		y = 1,
		sx = 3,
		sy = 3,
		drawborder = 1,
		drawindicators = 1,
		fid = 30
	}
UAS.gdef = {
		x = 1,
		y = 1,
		sx = 3,
		sy = 3,
		drawborder = 1,
		drawindicators = 1,
		fid = 30
	}
UAS.graphs = {
	
}

--include("cl_uantispam_skin.lua")

function registergraph()

end

function UAS.OpenFrame()
	if (IsValid(UAS.frame) or UAS.frame ~= nil) then if UAS.frame.Remove then UAS.frame:Remove() end end
	UAS.frame = vgui.Create("DFrame")
	local frm = UAS.frame
	frm:SetTitle("Settings")
	local psx, psy = math.Clamp(ScrW() - 200,0,1000),math.Clamp(ScrH() - 100,0,600)
	frm:SetSize(psx, psy)
	frm:Center()
	
	frm.btnClose.DoClick = function () UAS.frameopen = false; frm:Remove() end
	frm:MakePopup()
	UAS.frameopen = true
	
	function frm:Paint(w,h)
		UAS.skin.PFrame2(0,0,w,h,Color(255,255,255,255))
	end
	
	function frm:PaintOver(w,h)
		surface.SetMaterial(UAS.skin.dmat)
		surface.SetDrawColor(Color(0,0,0,60))
		surface.DrawTexturedRect(0,24, psx, 8)
		surface.DrawTexturedRect(0,24, 252, 8)
	end
	
	local sx,sy = psx-4, psy-26
	
	local scrpnl = vgui.Create("DScrollPanel", frm)
	scrpnl:SetSize( sx,sy )
	scrpnl:SetPos( 2, 24 )

	local pnl = vgui.Create("DPanel", scrpnl)
	pnl:SetSize( sx,sy )
	pnl:SetPos( 0, 0 )
	
	function pnl:Paint(w, h)
		UAS.skin.PPanel(0,0,w,h)
		UAS.skin.PPanel(0,0,250,h,Color(242,242,242,255))
		surface.SetMaterial(UAS.skin.rmat)
		surface.SetDrawColor(Color(0,0,0,60))
		surface.DrawTexturedRect(242,0, 8, sy)
	end
	
	local graphpanel = UAS.skin.graphpanel(pnl, sx - 260,sy-10, 260,10)
	
	graphpanel:SetNameX("size")
	graphpanel:SetNameY("rating")
	
	local function f(x)
		return UAS.calcrating(x,1,1,1,1,1)
	end
	
	local function g(x)
		return (x*0.001)^3
	end
	
	function graphpanel:PreGridPaint(w,h)
		self:DrawHorizontalField(0,1,true,Color(0,0,0,120))
	end
	function graphpanel:PostGridPaint(w,h)
		self:DrawHorizontalLine(UAS.settings.delrep,0,Color(255,0,0,220))
		self:DrawHorizontalLine(UAS.settings.frzrep,0,Color(0,160,255,220))
	end
	
	function graphpanel:PaintGraph(w,h)
		local fid = 200
		local xs = 1 --math.ceil((self.xsca/self.xzoom) / self.grid) 
		local mx = 10 --self.mx/self.xsca*self.grid
		for i = 1, fid * xs do
			local x1,y1 = self:TranslateCoordinates((i-1)*10,f((i-1)*mx/xs))
			local y = f(i*mx/xs)
			local x2,y2 = self:TranslateCoordinates(i*mx/xs,y)
			surface.SetDrawColor(HSVToColor(math.Clamp(1-y,0,1)*180,1,1))
			surface.DrawLine(x1,y1,x2,y2)
			
			surface.SetDrawColor(Color(255,255,255,255))
			local x1,y1 = self:TranslateCoordinates((i-1)*10,g((i-1)*mx/xs))
			local x2,y2 = self:TranslateCoordinates(i*mx/xs,g(i*mx/xs))
			surface.DrawLine(x1,y1,x2,y2)
		end
	end
	
	local scp2 = vgui.Create("DScrollPanel", pnl)
	scp2:SetSize( 250, psy-26 )
	scp2:SetPos( 0, 0 )

	function scp2:PerformLayout()
		local Wide = self:GetWide()
		local YPos = 0
		
		self:Rebuild()
		
		self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
		YPos = self.VBar:GetOffset()

		self.pnlCanvas:SetPos( 0, YPos )
		self.pnlCanvas:SetWide( Wide )
		
		self:Rebuild()
	end
	
	scp2.VBar.Paint = function() end
	local function retcol(dep,hov)
		if dep then
			surface.SetDrawColor(Color(120,120,120,180))
		elseif hov then
			surface.SetDrawColor(Color(180,180,180,180))
		else
			surface.SetDrawColor(Color(50,50,50,180))
		end
	end
	
	function scp2.VBar.btnUp:Paint(w,h)
		retcol(self.Depressed,self.Hovered)
		surface.DrawLine(w-1,0,w-1,h)
		surface.DrawLine(w-2,0,w-5,0)
	end
	function scp2.VBar.btnDown:Paint(w,h)
		retcol(self.Depressed,self.Hovered)
		surface.DrawLine(w-1,0,w-1,h)
		surface.DrawLine(w-2,h-1,w-5,h-1)
	end
	function scp2.VBar.btnGrip:Paint(w,h)
		retcol(self.Depressed,self.Hovered)
		surface.DrawLine(w-1,0,w-1,h)
	end
	
	--Sidebar
	
	local pnl2 = vgui.Create("DIconLayout", scp2)
	pnl2:SetSize( 250, psy-34 )
	pnl2:SetPos( 0, 0 )
	pnl2:SetSpaceY( 4 )
	
	local asg = UAS.skin.addhdr(pnl2,"Antispam Settings").IconLayout
	UAS.skin.addchck(asg,"Antispam enabled", "enabled","settings","default")
	local gnrl = UAS.skin.addhdr(asg,"General").IconLayout
	UAS.skin.addsldr(gnrl,"Freeze Rating", "frzrep","settings","default", 0, 2, 2)
	UAS.skin.addsldr(gnrl,"Delete Rating", "delrep","settings","default", 0, 4, 2)
	UAS.skin.addsldr(gnrl,"Min. Lagdelay (sec)", "lagdt","settings","default", 0.05, 5, 3)
	UAS.skin.addhl(gnrl)
	UAS.skin.addsldr(gnrl,"Min. Rating to Spawn", "minrep","settings","default", 0, 2, 2)
	UAS.skin.addchck(gnrl,"Block spawning", "blockspawn","settings","default")
	local coef = UAS.skin.addhdr(asg,"Prop Coefficients").IconLayout
	UAS.skin.addsldr(coef,"Size", "coef_size","settings","default", 0, 0.2, 5)
	UAS.skin.addsldr(coef,"Amount Equal Spaned", "coef_equal","settings","default", 0, 2, 2)
	UAS.skin.addsldr(coef,"Amount Total Spawned", "coef_total","settings","default", 0, 2, 2)
	UAS.skin.addhl(coef)
	UAS.skin.addsldr(coef,"Exponent Base", "coef_base","settings","default", 0, 0.5, 5)
	UAS.skin.addsldr(coef,"Exponent", "coef_exp","settings","default", 0, 0.5, 5)
	local mult = UAS.skin.addhdr(coef,"Multipliers").IconLayout
	UAS.skin.addsldr(mult,"Props", "mul_prop","settings","default", 0, 10, 3)
	UAS.skin.addsldr(mult,"Ragdolls", "mul_ragd","settings","default", 0, 10, 3)
	UAS.skin.addsldr(mult,"Vehicles", "mul_veh","settings","default", 0, 10, 3)
	UAS.skin.addsldr(mult,"Effects", "mul_effect","settings","default", 0, 10, 3)
	UAS.skin.addhl(pnl2,6)
	local sett = UAS.skin.addhdr(pnl2,"Graph Settings").IconLayout
	
	local pnl
	local ggnr = UAS.skin.addhdr(sett,"General").IconLayout
	pnl = UAS.skin.addsldr(ggnr,"X", "sx","gset","gdef", 1, 2000, 1)
	function pnl:Edited(val) graphpanel:SetMaxX(val) end
	function pnl:Think() if graphpanel:GetMaxX() ~= self:GetValue() then self:SetValue(graphpanel:GetMaxX()) end end
	pnl = UAS.skin.addsldr(ggnr,"Y", "sy","gset","gdef", 1, 2000, 1)
	function pnl:Edited(val) graphpanel:SetMaxY(val) end
	function pnl:Think() if graphpanel:GetMaxY() ~= self:GetValue() then self:SetValue(graphpanel:GetMaxY()) end end
	
	pnl = UAS.skin.addsldr(ggnr,"Zoom X", "x","gset","gdef", 0.05, 2, 2)
	function pnl:Edited(val) graphpanel:SetXzoom(val) end
	function pnl:Think() if graphpanel:GetXzoom() ~= self:GetValue() then self:SetValue(graphpanel:GetXzoom()) end end
	pnl = UAS.skin.addsldr(ggnr,"Zoom Y", "y","gset","gdef", 0.05, 2, 2)
	function pnl:Edited(val) graphpanel:SetYzoom(val) end
	function pnl:Think() if graphpanel:GetYzoom() ~= self:GetValue() then self:SetValue(graphpanel:GetYzoom()) end end
	
	pnl = UAS.skin.addhl(ggnr,6)
	pnl = UAS.skin.addchck(ggnr,"Min. Rating Border", "drawborder","gset","gdef")
	pnl = UAS.skin.addchck(ggnr,"Spawn Status Indicaors", "drawindicators","gset","gdef")
	pnl = UAS.skin.addhl(ggnr)
	pnl = UAS.skin.addsldr(ggnr,"Fidelity", "fid","gset","gdef", 10, 100, 0)
	local gphs = UAS.skin.addhdr(sett,"Graphs").IconLayout
	
	UAS.skin.addhl(pnl2,200)
end

if UAS.frameopen then
	UAS.OpenFrame()
end

concommand.Add( "uantispam_settingsmenu", UAS.OpenFrame)