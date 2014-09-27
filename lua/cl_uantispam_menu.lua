if SERVER then return end
local surface = surface
local draw = draw
local Color = Color
local math = math
local gui = gui
local ScrW, ScrH = ScrW, ScrH

UAS.frameopen = UAS.frameopen or false

UAS.gdef = {
		x = 1,
		y = 1,
		sx = 2000,
		sy = 1.5,
		gridx = 20,
		gridy = 15,
		drawborder = 1,
		drawmborder = 1,
		drawindicators = 1,
		fid = 16,
		
		size = 50,
		equal = 1,
		total = 1,
		rating = 1,
		time = 1,
		mult = 1,
				
		g1 = 1,
		g1m = 1,
		g2 = 0,
		g2m = 0.02,
		g3 = 0,
		g3m = 0.02,
}
UAS.gset = table.Copy(UAS.gdef)

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
	graphpanel:SetMaxXY(UAS.gset.sx,UAS.gset.sy)
	graphpanel:SetZoomXY(UAS.gset.x,UAS.gset.y)
	graphpanel:SetGridXY(UAS.gset.gridx,UAS.gset.gridy)
	graphpanel:SetNameX("x")
	graphpanel:SetNameY("rating")
	
	local function f1(x)
		x = x * UAS.gset.g1m
		return UAS.calcrating(x,UAS.gset.equal,UAS.gset.total,UAS.gset.rating,UAS.gset.time,UAS.gset.mult)
	end
	
	local function f2(x)
		x = x * UAS.gset.g2m
		local eq = UAS.gset.equal+x
		return UAS.calcrating(UAS.gset.size,eq,math.Max(UAS.gset.total,eq),UAS.gset.rating,UAS.gset.time,UAS.gset.mult)
	end
	
	local function f3(x)
		x = x * UAS.gset.g3m
		local eq = UAS.gset.equal
		return UAS.calcrating(UAS.gset.size,eq,math.Max(x,eq),UAS.gset.rating,UAS.gset.time,UAS.gset.mult)
	end
	
	function graphpanel:PreGridPaint(w,h)
		if UAS.gset.drawborder == 1 then
			self:DrawHorizontalField(0,1,true,Color(0,0,0,120))
		end
		if UAS.gset.drawmborder == 1 then
			self:DrawHorizontalField(1,1-UAS.settings.minrep,false,Color(255,0,0,120))
		end
	end
	function graphpanel:PostGridPaint(w,h)
		if UAS.gset.drawindicators == 0 then return end
		self:DrawHorizontalLine(UAS.settings.delrep,0,Color(255,0,0,220))
		self:DrawHorizontalLine(UAS.settings.frzrep,0,Color(0,160,255,220))
	end
	
	function graphpanel:getXY(i,mx,func)
		local x1,y1 = self:TranslateCoordinates((i-1)*mx,func((i-1)*mx))
		local x2,y2 = self:TranslateCoordinates(i*mx,func(i*mx))
		return x1,y1,x2,y2
	end
	
	function col(y,fr,dr,max,p)
		if y == 0 then y = 180
		elseif y <= fr and fr > dr and y < dr then y = max - (y/dr) * (max * p)
		elseif y <= fr and y < dr then y = max - (y/fr) * (max * p)
		elseif y < dr then y = max * (1-p) - ((y-fr)/(dr-fr)) * max * (1-p)
		else y = 0 end
		surface.SetDrawColor(HSVToColor(y,1,1))
	end
	
	function graphpanel:DrawGraph(n,mx,fr,dr,func,on,cf)
		if on == 0 then return end
		for i = 1, n do
			local x1,y1,x2,y2 = self:getXY(i,mx,func)
			surface.SetDrawColor(cf)
			surface.DrawLine(x1,y1,x2,y2)
		end
	end
	
	function graphpanel:PaintGraph(w,h)
		local fr, dr = UAS.settings.frzrep, UAS.settings.delrep
		local fid = UAS.gset.fid
		local wide = self:GetWide() - self.xin
		local n = wide * (fid / 100)+1
		local sca = self.mx/self.xzoom
		local mx = (sca / wide) / (fid / 100)
		
		self:DrawGraph(n,mx,fr,dr,f3,UAS.gset.g3,Color(255,240,0,200))
		self:DrawGraph(n,mx,fr,dr,f2,UAS.gset.g2,Color(255,0,0,200))
		if UAS.gset.g1 == 1 then
			for i = 1, n do
				local x1,y1,x2,y2 = self:getXY(i,mx,f1)
				col(f1(i*mx),fr,dr,140,0.5)
				surface.DrawLine(x1,y1,x2,y2)
			end
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
	
	local asg = UAS.skin.addhdr(pnl2,"Antispam Settings",true).IconLayout
	UAS.skin.addchck(asg,"", "enabled","settings","default",true)
	UAS.skin.addchck(asg,"", "frzen","settings","default",true)
	local gnrl = UAS.skin.addhdr(asg,"General").IconLayout
	UAS.skin.addsldr(gnrl,"", "frzrep","settings","default", 0, 2, 2,true)
	UAS.skin.addsldr(gnrl,"", "delrep","settings","default", 0, 4, 2,true)
	UAS.skin.addsldr(gnrl,"", "lagdt","settings","default", 0.05, 5, 3,true)
	UAS.skin.addhl(gnrl)
	UAS.skin.addsldr(gnrl,"", "minrep","settings","default", 0, 1, 2,true)
	UAS.skin.addchck(gnrl,"", "blockspawn","settings","default",true)
	local coef = UAS.skin.addhdr(asg,"Coefficients").IconLayout
	UAS.skin.addsldr(coef,"Size", "coef_size","settings","default", 0.00005, 0.01, 5,true)
	UAS.skin.addsldr(coef,"", "coef_base","settings","default", 0.1, 2, 5,true)
	--UAS.skin.addsldr(coef,"", "coef_exp","settings","default", -6, 6, 2,true)
	UAS.skin.addhl(coef)
	UAS.skin.addsldr(coef,"Equal Entities", "coef_equal","settings","default", 0, 2, 2,true)
	UAS.skin.addsldr(coef,"Total Entities", "coef_total","settings","default", 0, 2, 2,true)
	UAS.skin.addhl(coef)
	UAS.skin.addsldr(coef,"", "coef_lift","settings","default", 0, 1, 2,true)
	UAS.skin.addsldr(coef,"", "coef_push","settings","default", 0, 20, 3,true)
	UAS.skin.addsldr(coef,"", "coef_stretch","settings","default", 0.1, 100, 2,true)
	UAS.skin.addhl(coef)
	UAS.skin.addsldr(coef,"", "coef_ratinginf","settings","default", 0, 1, 2,true)
	UAS.skin.addsldr(coef,"", "coef_ratingexp","settings","default", 0.1, 6, 2,true)
	local mult = UAS.skin.addhdr(coef,"Multipliers").IconLayout
	UAS.skin.addsldr(mult,"Prop", "mul_prop","settings","default", 0, 10, 3,true)
	UAS.skin.addsldr(mult,"Ragd", "mul_ragd","settings","default", 0, 10, 3,true)
	UAS.skin.addsldr(mult,"Vehicle", "mul_veh","settings","default", 0, 10, 3,true)
	UAS.skin.addsldr(mult,"Effect", "mul_effect","settings","default", 0, 10, 3,true)
	UAS.skin.addhl(pnl2,6)
	local sett = UAS.skin.addhdr(pnl2,"Graph Settings").IconLayout
	
	local pnl
	local ggnr = UAS.skin.addhdr(sett,"General").IconLayout
	pnl = UAS.skin.addsldr(ggnr,"X", "sx","gset","gdef", 1, 5000, 0)
	function pnl:Think() if graphpanel:GetMaxX() ~= self:GetValue() then self:SetValue(graphpanel:GetMaxX()) end end
	function pnl:Edited(val) graphpanel:SetMaxX(val) end
	pnl = UAS.skin.addsldr(ggnr,"Y", "sy","gset","gdef", 1, 20, 1)
	function pnl:Think() if graphpanel:GetMaxY() ~= self:GetValue() then self:SetValue(graphpanel:GetMaxY()) end end
	function pnl:Edited(val) graphpanel:SetMaxY(val) end
	
	pnl = UAS.skin.addsldr(ggnr,"Zoom X", "x","gset","gdef", 0.05, 6, 2)
	function pnl:Think() if graphpanel:GetZoomX() ~= self:GetValue() then self:SetValue(graphpanel:GetZoomX()) end end
	function pnl:Edited(val) graphpanel:SetZoomX(val) end
	pnl = UAS.skin.addsldr(ggnr,"Zoom Y", "y","gset","gdef", 0.05, 6, 2)
	function pnl:Think() if graphpanel:GetZoomY() ~= self:GetValue() then self:SetValue(graphpanel:GetZoomY()) end end
	function pnl:Edited(val) graphpanel:SetZoomY(val) end
	
	pnl = UAS.skin.addsldr(ggnr,"Grid X", "gridx","gset","gdef", 1, 20, 0)
	function pnl:Think() if graphpanel.xsca ~= self:GetValue() then self:SetValue(graphpanel.xsca) end end
	function pnl:Edited(val) graphpanel.xsca = val end
	pnl = UAS.skin.addsldr(ggnr,"Grid Y", "gridy","gset","gdef", 1, 20, 0)
	function pnl:Think() if graphpanel.ysca ~= self:GetValue() then self:SetValue(graphpanel.ysca) end end
	function pnl:Edited(val) graphpanel.ysca = val end
	
	UAS.skin.addhl(ggnr,6)
	UAS.skin.addchck(ggnr,"Draw Border", "drawborder","gset","gdef")
	UAS.skin.addchck(ggnr,"Min. Rating Border", "drawmborder","gset","gdef")
	UAS.skin.addchck(ggnr,"Spawn Status Indicaors", "drawindicators","gset","gdef")
	UAS.skin.addhl(ggnr)
	UAS.skin.addsldr(ggnr,"Fidelity (%)", "fid","gset","gdef", 1, 100, 0)
	
	local gcoe = UAS.skin.addhdr(sett,"Coefficients").IconLayout
	UAS.skin.addsldr(gcoe,"Size", "size","gset","gdef", 1, 10000, 0)
	pnl = UAS.skin.addsldr(gcoe,"Equal Entities", "equal","gset","gdef", 1, 40, 0)
	function pnl:Think() if UAS.gset.equal > UAS.gset.total and not self:IsEditing() then self:SetValue(UAS.gset.total) end end
	pnl = UAS.skin.addsldr(gcoe,"Total Entities", "total","gset","gdef", 1, 40, 0)
	function pnl:Think() if UAS.gset.equal > UAS.gset.total and not self:IsEditing() then self:SetValue(UAS.gset.equal) end end
	UAS.skin.addsldr(gcoe,"Spawn Capability", "rating","gset","gdef", 0, 1, 2)
	UAS.skin.addsldr(gcoe,"Spawn Delay", "time","gset","gdef", 0, 3, 2)
	UAS.skin.addsldr(gcoe,"Multiplier", "mult","gset","gdef", 0, 10, 1)

	local gphs = UAS.skin.addhdr(sett,"Graphs").IconLayout
	UAS.skin.addchck(gphs,"x = size:", "g1","gset","gdef")
	UAS.skin.addsldr(gphs,"Multiplier", "g1m","gset","gdef", 0.01, 10, 2)
	UAS.skin.addchck(gphs,"x = equal ents:", "g2","gset","gdef")
	UAS.skin.addsldr(gphs,"Multiplier", "g2m","gset","gdef", 0.01, 10, 2)
	UAS.skin.addchck(gphs,"x = total ents:", "g3","gset","gdef")
	UAS.skin.addsldr(gphs,"Multiplier", "g3m","gset","gdef", 0.01, 10, 2)
	UAS.skin.addhl(gphs)
	UAS.skin.addhl(pnl2,200)
end

if UAS.frameopen then
	UAS.OpenFrame()
end

concommand.Add( "uantispam_settingsmenu", UAS.OpenFrame)