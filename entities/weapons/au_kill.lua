SWEP.PrintName = "Kill"
SWEP.Author = GAMEMODE.Author
SWEP.Instructions = "LMB to kill"

SWEP.ViewModel = ""
SWEP.WorldModel = ""

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize	= -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= "none"

SWEP.Weight	= 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Cooldown = 0
SWEP.MaxCooldown = 0

function AmongUs.GetFacingTarget( ply )
    local target = AmongUs.GetEntityAtTrace( ply, function( ent ) return ent:IsPlayer() and not ( ent == ply ) end )
    if not IsValid( target ) or not target:IsPlayer() or not target:Alive() then return end
    if target:GetPos():Distance( ply:GetPos() ) > AmongUs.Settings.KillDistance then return end

    return target
end

function SWEP:ApplyCooldown( time )
    self.Cooldown = 0
    self:SetNWInt( "AmongUs:MaxCooldown", time )
    self:SetNextPrimaryFire( CurTime() + time )
end

function SWEP:Equip()
    self:ApplyCooldown( AmongUs.Settings.StartKillCooldown )
end

function SWEP:CanKill()
    local cooldown, max_cooldown = self.Cooldown, self:GetNWInt( "AmongUs:MaxCooldown" )
    return cooldown > max_cooldown, max_cooldown - cooldown
end

function SWEP:Think()
    if IsValid( self.Owner:GetNWEntity( "AmongUs:Vent" ) ) then return end
    self.Cooldown = self.Cooldown + FrameTime() / 4
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end

    --  > Target
    local target = AmongUs.GetFacingTarget( self.Owner )
    if not target then return end

    --  > Role validating
    local role = AmongUs.GetRoleOf( target )
    if role and role.immortal then return end

    --  > Kill target
    if SERVER then
        self.Owner:SetPos( target:GetPos() )
        target:TakeDamage( math.huge, self.Owner, self )
        target:EmitSound( "amongus/kill01.wav", 120, 100 + math.random( -15, 15 ) )
    end

    --  > Cooldown
    self:ApplyCooldown( AmongUs.Settings.KillCooldown )
end

function SWEP:SecondaryAttack() end

--  > Halos
hook.Add( "PreDrawHalos", "AmongUs:Kill", function()
    local ply = LocalPlayer()
    local weapon = ply:GetWeapon( "au_kill" )
    if not IsValid( weapon ) then return end

    --  > Target
    local target = AmongUs.GetFacingTarget( ply )
    if not target then return end

    --  > Role validating
    local role = AmongUs.GetRoleOf( target )
    if role and role.immortal then return end

    local ply_role = AmongUs.GetRoleOf( ply )
    halo.Add( { target }, ply_role:get_name_color( AmongUs.GetRoleOf( ply ) ), 3, 3, weapon:CanKill() and 5 or .1, false )
end )