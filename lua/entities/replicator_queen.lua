AddCSLuaFile( )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Gueen"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

function ENT:Initialize()

	if SERVER then
	
		self:SetModel( "models/stargate/replicators/replicator_queen.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetHealth( 100 )
		
	end // SERVER

	if CLIENT  then
	
		self:SetVar( "rEffectFrame", 0 )
		
	end // CLIENT

	REPLICATOR.ReplicatorInitialize( self )
	
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 15
	local SpawnAng = Angle( 0,  ply:EyeAngles().yaw, 0 )

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	return ent

end

net.Receive( "CNR_RDrawStorageEffect", function()

	local queen = net.ReadEntity()
	
	queen.rEffectFrame = 1
	
	local pos = queen:GetPos() - queen:GetForward() * 16 - queen:GetUp() * 1
	local dlight = DynamicLight( queen:EntIndex() )
	if ( dlight ) then
		dlight.pos = pos
		dlight.r = 150
		dlight.g = 200
		dlight.b = 255
		dlight.brightness = 2
		dlight.Decay = 10
		dlight.Size = 150
		dlight.DieTime = CurTime() + 1000000 // you can not reach a point where light will disappear :D
	end
	
end )
	
function ENT:Draw()

	self:DrawModel()

	local effectTime = self.rEffectFrame
	
	if effectTime > 0 then
	
		local pos = self:GetPos() - self:GetForward() * 16 - self:GetUp() * 1
		if self:GetVar( "rEffectFrame" ) < 100 then self.rEffectFrame = effectTime + 1 else self.rEffectFrame = 100 end
		
		
		render.SetMaterial( Material( "sprites/gmdm_pickups/light" ) )
		render.DrawSprite( pos, 80, 80, Color( 255, 255, 255, 255 ) )

		render.SetColorMaterial()
		render.DrawSphere( pos, effectTime / 100 * 12, 20, 20, Color( 100, 150, 255, 50 ) )
		
	end
	
end

if SERVER then

	function ENT:OnTakeDamage( dmginfo )

		REPLICATOR.ReplicatorOnTakeDamage( 2, self, dmginfo )
		
	end
end

function ENT:Think()

	self:NextThink( CurTime() + 0.1 )

	if SERVER then
		
		REPLICATOR.ReplicatorAI( 2, self )
		
	end // SERVER

	if CLIENT then
		
		REPLICATOR.ReplicatorDarkPointAssig( self )

	end // CLIENT

	return true
end

if SERVER then

	function ENT:OnRemove()
	
		REPLICATOR.ReplicatorOnRemove( replicatorType, self )

	end
	
end