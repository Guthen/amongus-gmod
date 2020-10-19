
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

--  > https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L273
function AmongUs.DrawCircle( x, y, radius, angle_start, angle_end, color, stretch_x, stretch_y )
	local poly = {}
	angle_start = angle_start or 0
	angle_end   = angle_end   or 360

	stretch_x = stretch_x or 1
	stretch_y = stretch_y or 1
	
	poly[1] = { x = x, y = y }
	for i = math.min( angle_start, angle_end ), math.max( angle_start, angle_end ) do
		local a = math.rad( i )
		if angle_start < 0 then
			poly[#poly + 1] = { x = x + math.cos( a ) * radius * stretch_x, y = y + math.sin( a ) * radius * stretch_y }
		else
			poly[#poly + 1] = { x = x - math.cos( a ) * radius * stretch_x, y = y - math.sin( a ) * radius * stretch_y }
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