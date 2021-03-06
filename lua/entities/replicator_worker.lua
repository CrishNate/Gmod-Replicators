AddCSLuaFile( )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Worker"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

function ENT:Initialize()

	if SERVER then
	
		self:SetModel( "models/stargate/replicators/replicator_worker.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		self:SetHealth( 25 )
	
	end // SERVER

	if CLIENT  then
		
		
	end // CLIENT

	
	REPLICATOR.ReplicatorInitialize( self )
	
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 6
	local SpawnAng = Angle( 0,  ply:EyeAngles().yaw, 0 )

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:Draw()

	self:DrawModel()

end


if SERVER then

	function ENT:OnTakeDamage( dmginfo )
	
		REPLICATOR.ReplicatorOnTakeDamage( 1, self, dmginfo )
		
	end
end

function ENT:Think()

	self:NextThink( CurTime() + 0.1 )

	if SERVER then
		
		REPLICATOR.ReplicatorAI( 1, self )
		
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
	
