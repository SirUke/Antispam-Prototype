if SERVER then return end
local surface = surface
local draw = draw
local Color = Color
local math = math
local gui = gui
local ScrW, ScrH = ScrW, ScrH
local LP = LocalPlayer

SKIN = SKIN or {}
SKIN.GwenTexture = Material( "gwenskin/defaultskin.png" )

surface.CreateFont( "UASGraphTiny", {
	font = "Lucida Console",
	size = 9,
	antialias = false,
	outline = true,
} )

local function validopt(tab,opt)
	if UAS[tab] ~= nil and UAS[tab][opt] ~= nil then return true end
	return false
end

local function subpanel(parent,sx,sy,paint)
	local pnl = parent:Add("DPanel")
	pnl:SetSize( sx,sy )
	if paint then pnl.Paint = paint end
	return pnl
end

local function booltonumber(xy)
	if xy == true then return 1 else return 0 end
end

local function defbut(dad,parent,opt,tab,def,x,y)
	if not validopt(def,opt) then return end
	dad.DefBut = vgui.Create("DLabel",parent)
	dad.DefBut:SetPos(x,y)
	dad.DefBut:SetText("Reset")
	dad.DefBut:SizeToContents()
	dad.DefBut:SetMouseInputEnabled( true )
	dad.DefBut.cm = -1
	function dad.DefBut:Think()
		if UAS[tab][opt] == UAS[def][opt] then
			if self.cm ~= 1 then
				self:SetTextColor(Color(0,0,0,0))
				dad.DefBut:SetMouseInputEnabled( false )
				self.cm = 1
			end
		elseif self.Hovered then
			if self.cm ~= 2 then
				self:SetTextColor(Color(80,80,80,40))
				self.cm = 2
			end
		else
			if self.cm ~= 0 then
				self:SetTextColor(Color(80,80,80,120))
				dad.DefBut:SetMouseInputEnabled( true )
				self.cm = 0
			end
		end
	end
	dad.DefBut.DoClick = function() UAS[tab][opt] = UAS[def][opt] end
	return dad.DefBut
end
UAS.skin = {
	PFrame2 = GWEN.CreateTextureBorder( 0,		0,	127,	127,	16,	25,		16,	16 ),
	PPanel = GWEN.CreateTextureBorder( 256,		0,	63,	63,	16,	16,		16,	16 ),
	PModifier = GWEN.CreateTextureBorder( 256,		128,	127,	127,	16,	16,		16,	16 ),
	PPlus = GWEN.CreateTextureNormal( 448, 96, 15, 15 ),
	PMinus = GWEN.CreateTextureNormal( 464, 96, 15, 15 ),
	PGraBG =  GWEN.CreateTextureBorder( 384, 32, 31, 31, 4, 4, 4, 4 ),
	
	cmat = Material("gui/center_gradient"),
	rmat = Material("vgui/gradient-r"),
	dmat = Material("gui/gradient_down"),
	
	addhdr = function(parent,name,desc)
		local wide = parent:GetWide()
		local pnl = subpanel(parent,wide, 30)
		pnl.exp = false
		
		pnl.IconLayout = vgui.Create("DIconLayout", pnl)
		local x = pnl.IconLayout
		x.uasppnl = pnl
		x:SetSize( wide-6, 30 )
		x:SetPos( 6, 30 )
		x:SetSpaceY( 2 )
		x.uasischild = true
		
		pnl.Label = vgui.Create("DLabel", pnl)
		local Label = pnl.Label
		Label:SetText(name)
		Label:SetFont("Trebuchet18")
		Label.desc = desc

		Label:SetTextColor(Color(0,0,0,255))
		Label:SizeToContents()
		local sx, sy = Label:GetSize()
		Label:SetPos((wide-sx)/2,4)
		Label:SetMouseInputEnabled( true )
		function Label:Think()
			if Label.Depressed then
				Label:SetTextColor(Color(180,180,180,100))
			elseif Label.Hovered then
				Label:SetTextColor(Color(180,180,180,255))
			else
				Label:SetTextColor(Color(0,0,0,255))
			end
		end
		
		pnl.xt = x:GetTall()
		
		function pnl:UpdateTall()
			if self.exp then
				self:SetTall( self.xt + 30 )
			else
				self:SetTall( sy+4 )
			end
			parent:Layout()
		end
		
		Label.DoClick = function()
			pnl.exp = not pnl.exp
			pnl:UpdateTall()
			if parent.uasppnl then
				parent.uasppnl:UpdateTall()
			end
		end
		
		function pnl:Think()
			if x:GetTall() ~= pnl.xt then
				pnl.xt = x:GetTall()
				self:UpdateTall()
			end
		end
		
		pnl.Paint = function(w,h)
			surface.SetMaterial(UAS.skin.cmat)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.DrawTexturedRect(wide/2-sx,3, sx*2, sy+2)
			local right = (wide-sx)/2-15
			if pnl.exp then
				UAS.skin.PMinus(right,2,16,16)
			else
				UAS.skin.PPlus(right,2,16,16)
			end
			
			if not pnl.exp then return end
			local h = x:GetTall()
			surface.SetDrawColor(Color(0,0,0,80))
			local up = 9
			surface.DrawLine(3,up,right+4,up)
			surface.DrawLine(2,up,2,29+h)
			
		end
		pnl:UpdateTall()
		return pnl
	end,

	addhl = function(parent, add)
		local add = add or 0
		local wide = parent:GetWide()
		local pnl = subpanel(parent,wide, 6+add, function()
			surface.SetMaterial(UAS.skin.cmat)
			surface.SetDrawColor(Color(0,0,0,60))
			surface.DrawTexturedRect(0,2, wide,2)
		end)
		return pnl
	end,

	addsldr = function(parent,name, opt, tab, def, min, max, dcmls, issetting, desc)
		if not validopt(tab,opt) then return end
		local restrict = (issetting and not LP():IsSuperAdmin()) and true or false
		local wide = parent:GetWide()
		local pnl = subpanel(parent,wide-4, 40, function() UAS.skin.PModifier( 0,0, wide-4, 40 ) end)
		pnl.desc = desc
		
		if name == "" or name == nil then name = UAS.names[opt] or "" end
		
		local sldr = vgui.Create( "DNumSlider", pnl )
		sldr:SetPos( 10, -1 )
		sldr:SetSize( wide - 20, 36 )
		sldr:SetText( name )
		sldr:SetMinMax( min, max )
		sldr:SetDecimals( dcmls )
		sldr:SetValue( UAS[tab][opt] )
		sldr.Think = function() if UAS[tab][opt] ~= sldr:GetValue() then sldr:SetValue( UAS.settings[opt] ) end end
		sldr.mightyE = false
		
		sldr.Label:Dock( TOP )
		sldr.Label:SetMouseInputEnabled( false )
		sldr.Label:SetTextColor(Color(0,0,0,255))
		
		sldr.TextArea:SetWide( 45+40 )
		sldr.TextArea:SetPos(wide-78,4)
		sldr.TextArea:Dock( NODOCK )
		
		local dmc = (max-min)*(dcmls*4)
		dmc = math.floor(dmc / math.Max(dmc/10,1))
		sldr.Slider:Dock( BOTTOM )
		sldr.Slider:SetNotches( dmc )
		sldr.Slider.TranslateValues = function( slider, x, y ) return sldr:TranslateSliderValues( x, y ) end
		sldr.Slider.Knob:NoClipping( false )
		
		if not restrict then 
			local defbut = defbut(sldr,pnl,opt,tab,def,wide-95,7)
			if not defbut then return end
			function defbut:DoClick() UAS[tab][opt] = UAS[def][opt]; sldr:SetValue( UAS[tab][opt] ); sldr.mightyE = true end
		end
		
		function sldr:Think()
			if sldr:IsEditing() then
				sldr.mightyE = true
			elseif sldr.mightyE then
				sldr.mightyE = false
				if restrict then return end
				local dc = math.Max(10^sldr:GetDecimals(),1)
				local val = math.floor(math.Round(sldr:GetValue()*dc))/dc
				UAS.SendToServer(opt,val)
			else
				if sldr:GetValue() ~= UAS[tab][opt] then sldr:SetValue( UAS[tab][opt] ) end
			end
		end
		
		function pnl:IsEditing() return sldr:IsEditing() end
		function pnl:Edited(val) end
		function pnl:SetValue(val) sldr:SetValue( val ) end
		function pnl:GetValue() return sldr:GetValue() end
		sldr.OnValueChanged = function()
			if restrict then return end
			local dc = math.Max(10^sldr:GetDecimals(),1)
			local val = math.floor(math.Round(sldr:GetValue()*dc))/dc
			
			UAS[tab][opt] = val
			pnl:Edited(val)
		end
		
		return pnl
	end,
	
	addchck = function(parent,name, opt, tab, def, issetting, desc)
		if not validopt(tab,opt) then return end
		local restrict = (issetting and not LP():IsSuperAdmin()) and true or false
		local wide = parent:GetWide()
		local pnl = subpanel(parent,wide-4, 19, function() UAS.skin.PModifier( 0,0, wide-4, 19 ) end)
		pnl.desc = desc
		
		if name == "" or name == nil then name = UAS.names[opt] or "" end
		
		local chck = vgui.Create( "DCheckBoxLabel", pnl )
		chck:SetPos(2,2)
		chck:SetText(name)
		chck:SetWide(wide-10)
		chck:SetValue(UAS[tab][opt])
		
		chck.Think = function() if UAS[tab][opt] ~= booltonumber(chck:GetChecked()) then chck:SetValue( UAS[tab][opt] ) end end
		
		chck:SetTextColor(Color(0,0,0,255))

		if not restrict then defbut(chck,pnl,opt,tab,def,wide-44,2) end
		
		function pnl:Edited(val) end
		function pnl:SetValue(val) chck:SetValue( val ) end
		function pnl:GetValue() return booltonumber(chck:GetChecked()) end
		chck.OnChange = function()
			local val = booltonumber(chck:GetChecked())
			if restrict then return
			else UAS.SendToServer(opt,val) end
			UAS[tab][opt] = val
			pnl:Edited(val)
		end
		
		return pnl
	end,
	
	graphpanel = function(parent, sx, sy, px, py)
		local pnl = subpanel(parent,sx, sy)
		
		pnl:SetPos( 260,10 )
		
		pnl.xin = 30
		pnl.yin = 30
		
		pnl.mx = 3
		pnl.my = 3
		
		pnl.xzoom = 1
		pnl.yzoom = 1
		
		pnl.xsca = 6
		pnl.ysca = 6
		
		pnl.grid = 1
		
		pnl.fid = 30
		
		pnl.xname = "x"
		pnl.yname = "y"
		
		pnl.lxz = 1
		pnl.lyz = 1
		function pnl:SetZoomX(n) self.xzoom = n end
		function pnl:SetZoomY(n) self.yzoom = n end
		function pnl:SetZoomXY(n,m) self.xzoom = n; self.yzoom = m end
		function pnl:GetZoomX() return self.xzoom end
		function pnl:GetZoomY() return self.yzoom end
		function pnl:GetZoomXY() return self.xzoom, self.yzoom end

		function pnl:SetMaxX(n) self.mx = n end
		function pnl:SetMaxY(n) self.my = n end
		function pnl:SetMaxXY(n,m) self.mx = n; self.my = m end
		function pnl:GetMaxX() return self.mx end
		function pnl:GetMaxY() return self.my end
		function pnl:GetMaxXY() return self.mx, self.my end
		
		function pnl:SetGridX(n) self.xsca = n end
		function pnl:SetGridY(n) self.ysca = n end
		function pnl:SetGridXY(n,m) self.xsca = n; self.ysca = m end
		function pnl:GetGridX() return self.xsca end
		function pnl:GetGridY() return self.ysca end
		function pnl:GetGridXY() return self.xsca, self.ysca end
		
		function pnl:SetNameX(n) self.xname = n or "x" end
		function pnl:SetNameY(n) self.yname = n or "y" end
		function pnl:GetNameX() return self.xname end
		function pnl:GetNameY() return self.yname end
		
		function pnl:SetFidelity(n) self.fid = n end
		function pnl:GetFidelity() return self.fid end
		
		function pnl:SetIndentX(x) self.xin = x end
		function pnl:SetIndentY(y) self.yin = y end
		function pnl:SetIndentXY(x, y) self.xin = x; self.yin = y end
		function pnl:GetIndentX() return self.xin end
		function pnl:GetIndentY() return self.yin end
		function pnl:GetIndentXY() return self.xin, self.yin end
		
		function pnl:SetGrid(n) self.grid = n end
		function pnl:GetGrid() return self.grid end
		
		function pnl:TranslateCoordinates(x,y)
			local w,h = self:GetSize()
			local w2, h2 = w - self.xin, h - self.yin
			return self.xin + x * (w2/self.mx) * self.xzoom, h2 - (y * (h2/self.my) * self.yzoom), w ,h
		end
		
		function pnl:DrawHorizontalLine(y,off,col)
			if type(col) == "number" then col = Color(140,140,140,col) end
			local col = col or Color(140,140,140,255)
			local x,y,w,h = self:TranslateCoordinates(0,y)
			surface.SetDrawColor(col)
			surface.DrawLine(x-off,y,w,y)
			return x-off, y
		end
		
		function pnl:DrawHorizontalField(y1,y2,starttop,col)
			if type(col) == "number" then col = Color(140,140,140,col) end
			local col = col or Color(140,140,140,255)
			if not starttop then _,y1 = self:TranslateCoordinates(0,y1) else y1 = 0 end
			local x,y2,w,h = self:TranslateCoordinates(0,y2)
			
			if starttop and y1== y2 then return end
			if (y1 < 0 or not starttop) and y2 < 0 then return end
			if y1 > y2 and not starttop then y = y1; y1 = y2; y2 = y end
			
			surface.SetDrawColor(col)
			surface.DrawRect(x,y1,w-x,y2+1-y1)
		end
		
		function pnl:DrawVerticalField(x1,x2,startright,col)
			if type(col) == "number" then col = Color(140,140,140,col) end
			local col = col or Color(140,140,140,255)
			if not startright then x1,_ = self:TranslateCoordinates(x1,0) end
			local x2,y,w,h = self:TranslateCoordinates(x2,0)
			
			if startright and x1== x2 then return end
			if (x1 > w or not startright) and x2 > w then return end
			if x1 > x2 and not startright then x = x1; x1 = x2; x2 = x end
			
			surface.SetDrawColor(col)
			if not startright then surface.DrawRect(x1,0,x2-x1+1,y)
			else surface.DrawRect(x2,0,w-x2+1,y) end
		end
		
		function pnl:DrawVerticalLine(x,off,col)
			if type(col) == "number" then col = Color(140,140,140,col) end
			local col = col or Color(140,140,140,255)
			local x,y,w,h = self:TranslateCoordinates(x,0)
			surface.SetDrawColor(col)
			surface.DrawLine(x,0,x,y+off)
			
			return x, y+off
		end
		
		function pnl:OnMouseWheeled(d)
			--pnl.xzoom = math.Clamp(pnl.xzoom + d*0.04*pnl.xzoom,0.05,10)
			--pnl.yzoom = math.Clamp(pnl.yzoom + d*0.04*pnl.yzoom,0.05,10)
		end
		
		function pnl:PreGridPaint(w,h) end
		function pnl:GridPaint(w,h) end
		function pnl:PostGridPaint(w,h) end
		function pnl:PrePaintGraph(w,h) end
		function pnl:PaintGraph(w,h) end
		function pnl:GridPaintGraph(w,h) end
		
		function pnl:Paint(w,h)
			UAS.skin.PGraBG(0,0,w,h)
			
			local x,_ = self:DrawHorizontalLine(0,5,Color(0,0,0,255))
			local _,y = self:DrawVerticalLine(0,5,Color(0,0,0,255))
			
			surface.SetTextColor(Color(255,255,255,255))
			surface.SetFont("UASGraphTiny")
			surface.SetTextPos(x-2,y-2)
			surface.DrawText("0")
			
			surface.DisableClipping(true)
			local txt = self.xname .. " = " .. math.floor(self.mx/self.xzoom*100)/100
			local sx, _ = surface.GetTextSize(txt)
			surface.SetTextPos(w+2,y-6)
			surface.DrawText(txt)
			
			local txt = self.yname .. " = " .. math.floor(self.my/self.yzoom*100)/100
			local sx,sy = surface.GetTextSize(txt)
			surface.SetTextPos(x+6,2-sy)
			surface.DrawText(txt)
			surface.DisableClipping(false)
			
			self:PreGridPaint(w,h)
			self:GridPaint(w,h)
			self:PostGridPaint(w,h)
			
			self:PrePaintGraph(w,h)
			self:PaintGraph(w,h)
			self:GridPaintGraph(w,h)
		end
		
		function pnl:GridPaint(w,h)
			local w2,h2 = w - self.xin,h - self.yin
			local xs = math.ceil((self.xsca/self.xzoom) / self.grid)
			local mx = self.mx/self.xsca*pnl.grid
			local stx = math.Max(math.Round(1/ pnl.xzoom),1)
			for i = 1, xs, stx do
				local n = tostring(math.floor(i * mx * 100) / 100)
				self:DrawVerticalLine((i-stx*0.5)*mx,0,30)
				local x, y = self:DrawVerticalLine(i*mx,5,200)
				local sx,sy = surface.GetTextSize(n)
				surface.SetTextPos(x-sx/2,y+2)
				surface.DrawText(n)
			end
			
			local ys = math.ceil((self.ysca/self.yzoom) / self.grid)
			local my = self.my/self.ysca*pnl.grid
			local sty = math.Max(math.Round(1/ pnl.yzoom),1)
			for i = 1, ys, sty do
				local n = tostring(math.floor(i * my * 100) / 100)
				self:DrawHorizontalLine((i-sty*0.5)*my,0,30)
				local x,y = self:DrawHorizontalLine(i*my,5,200)
				local sx,sy = surface.GetTextSize(n)
				surface.SetTextPos(x-sx-2,y-sy/4)
				surface.DrawText(n)
			end
		end
		
		/*pnl.But = vgui.Create("DImageButton",pnl)
		pnl.But:SetImage("icon16/wand.png")
		pnl.But:SetSize(16,16)
		pnl.But:SetPos(2,sy-18)
		pnl.But.xy = -1
		function pnl.But:Think()
			if self.Depressed then
				if pnl.But.xy ~= 2 then pnl.But.xy = 2; self:SetColor(Color(0,255,255,100)) end
			elseif self.Hovered then
				if pnl.But.xy ~= 1 then pnl.But.xy = 1; self:SetColor(Color(255,255,255,150)) end
			else
				if pnl.But.xy ~= 0 then pnl.But.xy = 0; self:SetColor(Color(255,255,255,255)) end
			end
		end
		pnl.But.DoClick = function()
			local scx, scy = (sx-pnl.xin)* pnl.mx/pnl.xzoom, (sy-pnl.yin)* pnl.my/pnl.yzoom
			
			if scx > scy then
				pnl.lastset = 1
				pnl.oxz = pnl.xzoom
				pnl.oyz = pnl.yzoom
				pnl.xzoom = pnl.xzoom * (scy / scx)
			elseif scx < scy then
				pnl.lastset = 1
				pnl.oxz = pnl.xzoom
				pnl.oyz = pnl.yzoom
				pnl.yzoom = pnl.yzoom * (scx / scy)
			elseif pnl.lastset == 1 then
				pnl.lastset = 0
				pnl.xzoom = pnl.oxz or pnl.xzoom
				pnl.yzoom = pnl.oyz or pnl.yzoom
			end
		end
		--pnl.But:DoClick()
		*/
		return pnl
	end
}

include("cl_uantispam_menu.lua")