local PLAYER = {}

PLAYER.Name = "au_crew"
PLAYER.WalkSpeed = 175
PLAYER.Model = "models/kaesar/amongus/amongus.mdl"
PLAYER.CanUseFlashlight = false

function PLAYER:Loadout()
    self.Player:StripWeapons()
    self.Player:SetModel( self.Model )

    --  > Color
    --[[ local color = table.Random( AmongUs.Settings.Colors )
    self.Player:SetPlayerColor( Vector( color.r / 255, color.g / 255, color.b / 255 ) )
 ]]
    --  > Move
    self.Player:SetWalkSpeed( self.WalkSpeed )
    self.Player:SetRunSpeed( self.WalkSpeed )

    --  > Role
    local role = AmongUs.GetRoleOf( self.Player )
    if not role then return end

    for i, v in ipairs( role.weapons or {} ) do
        self.Player:Give( v )
    end
end

local PLAYER_META = FindMetaTable( "Player" )
function PLAYER_META:GetName()
    return self:GetNWString( "AmongUs:FakeName", self:Name() )
end

player_manager.RegisterClass( PLAYER.Name, PLAYER, "player_default" )
AmongUs.BasePlayerClass = PLAYER