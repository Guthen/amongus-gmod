paint = {}
local context

local floor = math.floor
function paint.Start( mat, x, y, w, h )
    x = floor( x )
    y = floor( y )
    w = floor( w )
    h = floor( h )

    if context then
        local info = debug.getinfo( 2, "lS" )

        error( "Trying to start a paint without closing it " .. info.source .. ": line " .. info.currentline )
        return
    end

    context = {
        mat = mat,
        x = x, y = y,
        w = w, h = h
    }

    surface.SetMaterial( mat )
    surface.SetDrawColor( color_white )
    surface.DrawTexturedRect( x, y, w, h )
end

function paint.End()
    context = nil
end

function paint.Size( mat, x, y, w, h )
    if not context then
        local info = debug.getinfo( 2, "lS" )

        error( "Trying to paint while out of context " .. info.source .. ": line " .. info.currentline )
        return
    end

    local scale_x = context.w / context.mat:Width()
    local scale_y = context.h / context.mat:Height()

    x, y = x and floor( context.x + scale_x * x ), y and floor( context.y + scale_y * y )
    w = w and floor( scale_x * w )
    h = h and floor( scale_y * h )

    return x, y, w, h
end

function paint.Rect( x, y, w, h, col )
    if not context then
        local info = debug.getinfo( 2, "lS" )

        error( "Trying to paint while out of context " .. info.source .. ": line " .. info.currentline )
        return
    end

    local scale_x = context.w / context.mat:Width()
    local scale_y = context.h / context.mat:Height()

    x, y = floor( context.x + scale_x * x ), floor( context.y + scale_y * y )
    w = floor( scale_x * w )
    h = floor( scale_y * h )

    surface.SetDrawColor( col or color_white )
    surface.DrawRect( x, y, w, h )
end

function paint.Draw( mat, x, y, w, h, col, ang )
    if not context then
        local info = debug.getinfo( 2, "lS" )

        error( "Trying to paint while out of context " .. info.source .. ": line " .. info.currentline )
        return
    end

    local scale_x = context.w / context.mat:Width()
    local scale_y = context.h / context.mat:Height()

    w = floor( scale_x * w )
    h = floor( scale_y * h )

    if ang then
        x, y = floor( context.x + scale_x * x + w / 2 ), floor( context.y + scale_y * y + h / 2 )
    else
        x, y = floor( context.x + scale_x * x ), floor( context.y + scale_y * y )
    end

    surface.SetMaterial( mat )
    surface.SetDrawColor( col or color_white )

    if ang then
        surface.DrawTexturedRectRotated( x, y, w, h, ang )
    else
        surface.DrawTexturedRect( x, y, w, h )
    end
end