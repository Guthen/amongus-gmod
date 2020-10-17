
function AmongUs.DrawText( text, x, y, text_color, font, align_x, align_y )
    draw.SimpleTextOutlined( text, font or "AmongUs:Default", x, y, text_color or color_white, align_x or TEXT_ALIGN_CENTER, align_y or TEXT_ALIGN_CENTER, 2, color_black )
end

--  > https://github.com/Nogitsu/GNLib/blob/master/lua/gnlib/client/cl_draw.lua#L273
function AmongUs.DrawCircle( x, y, radius, angle_start, angle_end, color )
	local poly = {}
	angle_start = angle_start or 0
	angle_end   = angle_end   or 360
	
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

function AmongUs.DrawMaterial( material, x, y, w, h, color )
	surface.SetDrawColor( color or color_white )
    surface.SetMaterial( material )
    surface.DrawTexturedRect( x, y, w, h )
end

AmongUs.DisableIconColor = Color( 75, 75, 75, 150 )
function AmongUs.DrawIcon( icon, x, y, active )
	AmongUs.DrawMaterial( icon, x, y, AmongUs.IconSize, AmongUs.IconSize, active and color_white or AmongUs.DisableIconColor )
end