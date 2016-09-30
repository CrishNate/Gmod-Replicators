AddCSLuaFile( )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Worker"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

//if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

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
	/*
	local ent = self

	local maxs = Vector( 6, 6, 6 )
	local startpos = ent:GetPos() + self:GetUp() * 2
	local dir = ent:GetForward() * 20

	local tr, trD = cnr_traceHullQuick( 
				self:GetPos(), -self:GetUp() * 20,
				Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )
		
	if tr.Hit then print( trD ) end
	render.DrawLine( tr.HitPos, startpos + dir * len, color_white, true )
	render.DrawLine( startpos, tr.HitPos, Color( 0, 0, 255 ), true )

	local clr = color_white
	if ( tr.Hit ) then
		clr = Color( 255, 0, 0 )
	end

	render.DrawWireframeBox( startpos, Angle( 0, 0, 0 ), -maxs, maxs, Color( 255, 255, 255 ), true )
	render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), -maxs, maxs, clr, true )
	*/
	
	//ReplicatorDrawDebug( self )
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
	
