AddCSLuaFile( )
include( "replicator_class.lua" )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= true
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
		
		ReplicatorInitialize( self )
		
	end // SERVER

	if CLIENT  then
		
		
	end // CLIENT
end

/*
function ENT:Draw()

	self:DrawModel()

	local ent = self

	local maxs = Vector( 6, 6, 6 )
	local startpos = ent:GetPos() + self:GetUp() * 2
	local dir = ent:GetForward() * 20

	local tr = traceHullQuick( startpos, dir, maxs, replicatorNoCollideGroup_Witch )

	render.DrawLine( tr.HitPos, startpos + dir * len, color_white, true )
	render.DrawLine( startpos, tr.HitPos, Color( 0, 0, 255 ), true )

	local clr = color_white
	if ( tr.Hit ) then
		clr = Color( 255, 0, 0 )
	end

	render.DrawWireframeBox( startpos, Angle( 0, 0, 0 ), -maxs, maxs, Color( 255, 255, 255 ), true )
	render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), -maxs, maxs, clr, true )

end
*/

if SERVER then

	function ENT:OnTakeDamage( dmginfo )
		local damage = dmginfo:GetDamage()
		
		self:SetHealth( self:Health() - damage )

		if self:Health() <= 0 then
		
			local phys = self:GetPhysicsObject()
			//phys:EnableCollisions( false )

			local ent
			for i = 1, g_segments_to_assemble_replicator do
			
				ent = ents.Create( "replicator_segment" )
				
				if not IsValid( ent ) then return end
				ent:SetPos( self:GetPos() + VectorRand() * 3 )
				ent:SetAngles( AngleRand() )
				ent:SetOwner( self:GetOwner() )
				ent:Spawn()
				
				local phys = ent:GetPhysicsObject()
				phys:Wake()
				phys:SetVelocity( VectorRand() * ( damage * 2 + 100 ) )
				
			end
			ent:EmitSound( "npc/manhack/gib.wav", 75, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
			
			self:Remove()
		end
		
	end
end

function ENT:Think()

	self:NextThink( CurTime() + 0.1 )

	if SERVER then

		//
		// ---------- Replicator Class
		//
		
		ReplicatorThink( 1, self )
		

	end // SERVER

	// ------------------------- Initialize dark spots
	if CLIENT then

		ReplicatorDarkPointAssig( self )

	end // CLIENT
	
	return true
end

if SERVER then

	function ENT:OnRemove()
	
		timer.Remove( "rWalking" .. self:EntIndex() )
		timer.Remove( "rRun" .. self:EntIndex() )
		timer.Remove( "rRotateBack" .. self:EntIndex() )
		timer.Remove( "rScanner"..self:EntIndex() )
		timer.Remove( "rChangingDirection" .. self:EntIndex() )
		timer.Remove( "rEating" .. self:EntIndex() )
		timer.Remove( "rGiving"..self:EntIndex() )

	end
	
end
	
