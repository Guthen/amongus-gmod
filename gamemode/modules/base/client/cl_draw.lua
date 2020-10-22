function AmongUs.LerpColor( t, a, b )
	return Color( Lerp( t, a.r, b.r ), Lerp( t, a.g, b.g ), Lerp( t, a.b, b.b ) )
end

function AmongUs.DrawText( text, x, y, text_color, font, align_x, align_y )
    draw.SimpleTextOutlined( text, font or "AmongUs:Default", x, y, text_color or color_white, align_x or TEXT_ALIGN_CENTER, align_y or TEXT_ALIGN_CENTER, 2, color_black )
end

function AmongUs.DrawColoredText( x, y, font, ... )
	local args = { ... }

	--	> Compute text width
	local total_w = 0
	surface.SetFont( font or "AmongUs:Default" )
	for k, v in ipairs( args ) do
		if not IsColor( v ) then
			total_w = total_w + surface.GetTextSize( tostring( v ) )
		end
	end

	--	> Draw texts
	local last_x = x - total_w / 2
	local color = color_white
	for k, v in ipairs( args ) do
		if IsColor( v ) then
			color = v
		else
			AmongUs.DrawText( tostring( v ), last_x, y, color, font, TEXT_ALIGN_LEFT )
			last_x = last_x + surface.GetTextSize( tostring( v ) )
		end
	end
end

--	> https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L419
function AmongUs.DrawOutlinedCircle( x, y, radius, thick, angle_start, angle_end, color )    
    local start = math.rad( angle_start )
    local last_ox, last_oy = x - math.cos( start ) * radius, y - math.sin( start ) * radius
    local last_ix, last_iy = x - math.cos( start ) * ( radius - thick ), y - math.sin( start ) * ( radius - thick )

    for i = math.min( angle_start or 0, angle_end or 360 ), math.max( angle_start or 0, angle_end or 360 ) do
        local a = math.rad( i )

        local ox, oy = x - math.cos( a ) * radius, y - math.sin( a ) * radius
        local ix, iy = x - math.cos( a ) * ( radius - thick ), y - math.sin( a ) * ( radius - thick )
        
        draw.NoTexture()
        surface.SetDrawColor( color or color_white )
        surface.DrawPoly( {
            { x = last_ox, y = last_oy },
            { x = ox, y = oy },
            { x = ix, y = iy },
            { x = last_ix, y = last_iy },
        } )

        last_ox, last_oy = ox, oy
        last_ix, last_iy = ix, iy
    end
end

--	> https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L486
function AmongUs.DrawOutlinedRoundedRect( corner_radius, x, y, w, h, thick, color )
	surface.SetDrawColor( color or color_white )

	local pos_thick = math.floor( thick / 2 )

	surface.DrawRect( x + corner_radius, y + pos_thick / 2, w - corner_radius * 2 + 1, thick )
	surface.DrawRect( x + corner_radius, y + h - thick, w - corner_radius * 2, thick )
	surface.DrawRect( x + pos_thick / 2, y + corner_radius, thick, h - corner_radius * 2 )
	surface.DrawRect( x + w - pos_thick * 2, y + corner_radius, thick, h - corner_radius * 2 )

	AmongUs.DrawOutlinedCircle( x + corner_radius + pos_thick / 2, y + corner_radius + pos_thick / 2, corner_radius, thick, 0, 90, color )
	AmongUs.DrawOutlinedCircle( x + w - corner_radius, y + corner_radius + pos_thick / 2, corner_radius, thick, -270, -180, color )
	AmongUs.DrawOutlinedCircle( x + corner_radius + pos_thick / 2, y + h - corner_radius, corner_radius, thick, -90, 0, color )
	AmongUs.DrawOutlinedCircle( x + w - corner_radius, y + h - corner_radius, corner_radius, thick, 270, 180, color )
end

--  > https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L273
function AmongUs.DrawCircle( x, y, radius, angle_start, angle_end, color )
	local poly = {}
	angle_start = angle_start or 0
	angle_end   = angle_end   or 360

	stretch_x = stretch_x or 1
	stretch_y = stretch_y or 1
	
	poly[1] = { x = x, y = y }
	for i = math.min( angle_start, angle_end ), math.max( angle_start, angle_end ) do
		local a = math.rad( i )
		if angle_start < 0 then
			poly[#poly + 1] = { x = x + math.cos( a ) * radius, y = y + math.sin( a ) * radius }
		else
			poly[#poly + 1] = { x = x - math.cos( a ) * radius, y = y - math.sin( a ) * radius }
		end
	end
	poly[#poly + 1] = { x = x, y = y }

	draw.NoTexture()
	surface.SetDrawColor( color or color_white )
	surface.DrawPoly( poly )

	return poly
end

--  > https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L160
function AmongUs.DrawStencil( shape_draw_func, draw_func )
	render.ClearStencil()
	render.SetStencilEnable( true )

	render.SetStencilWriteMask( 1 )
	render.SetStencilTestMask( 1 )

	render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	render.SetStencilPassOperation( STENCILOPERATION_ZERO )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
	render.SetStencilReferenceValue( 1 )

	shape_draw_func()

	render.SetStencilFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilReferenceValue( 1 )

	draw_func()

	render.SetStencilEnable( false )
	render.ClearStencil()
end

function AmongUs.DrawMaterial( material, x, y, w, h, color, ang )
	surface.SetDrawColor( color or color_white )
    surface.SetMaterial( material )
    if ang then
		surface.DrawTexturedRectRotated( x, y, w, h, ang )
	else
		surface.DrawTexturedRect( x, y, w, h )
	end
end

AmongUs.DisableIconColor = Color( 75, 75, 75, 150 )
function AmongUs.DrawIcon( icon, x, y, active )
	AmongUs.DrawMaterial( icon, x, y, AmongUs.IconSize, AmongUs.IconSize, active and color_white or AmongUs.DisableIconColor )
end