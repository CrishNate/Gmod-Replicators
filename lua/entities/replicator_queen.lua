AddCSLuaFile( )
include( "replicator_class/replicator_class.lua" )

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Gueen"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

//if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

function ENT:Initialize()

	if SERVER then

		util.AddNetworkString( "rDrawStorageEffect" )
	
		self:SetModel( "models/stargate/replicators/replicator_queen.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetHealth( 100 )

		ReplicatorInitialize( self )
		
	end // SERVER

	if CLIENT  then
	
		self:SetVar( "rEffectFrame", 0 )
		
	end // CLIENT
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

function ENT:Draw()

	self:DrawModel()

	local effectTime = self.rEffectFrame
	
	net.Receive( "rDrawStorageEffect", function()
	
		if net.ReadEntity() == self then self.rEffectFrame = 1 end
		
	end )
	
	if effectTime > 0 then
	
		if self:GetVar( "rEffectFrame" ) < 100 then self.rEffectFrame = effectTime + 4 else self.rEffectFrame = 100 end
		local pos = self:GetPos() - self:GetForward() * 16 - self:GetUp() * 1
		/*
		local dlight = DynamicLight( LocalPlayer():EntIndex() )
		if ( dlight ) then
			dlight.pos = pos
			dlight.r = 255
			dlight.g = 255
			dlight.b = 255
			dlight.brightness = 2
			dlight.Decay = 10
			dlight.Size = 150
			dlight.DieTime = CurTime() + 1
		end
		*/
		
		local emitter = ParticleEmitter( pos, false )

		local particle = emitter:Add( Material( "sprites/gmdm_pickups/light" ), pos + VectorRand() )
		
		if particle then
		
			local randVec = VectorRand() * math.Rand( 3, 4 ) * 4
			particle:SetVelocity( randVec )
			particle:SetColor( 255, 255, 255 ) 
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 2.3 )
			particle:SetStartSize( 6 )
			particle:SetEndSize( 8 )

			particle:SetGravity( -randVec )
			
		end
		
		emitter:Finish()
		
		render.SetColorMaterial()
		render.DrawSphere( pos, effectTime / 100 * 12, 20, 20, Color( 255, 255, 255, 50 ) )
		
	end
	/*
	local ent = self

	local maxs = Vector( 8, 8, 8 )
	local startpos = self:GetPos() + self:GetUp() * 4
	local dir = ent:GetForward() * 20

	local tr = traceHullQuick( 
		self:GetPos() + self:GetUp() * 4, 
		self:GetForward() * 20, 
		Vector( 8, 8, 8 ), replicatorNoCollideGroup_With )

	render.DrawLine( tr.HitPos, startpos + dir * len, color_white, true )
	render.DrawLine( startpos, tr.HitPos, Color( 0, 0, 255 ), true )

	local clr = color_white
	if ( tr.Hit ) then
		clr = Color( 255, 0, 0 )
	end

	render.DrawWireframeBox( startpos, Angle( 0, 0, 0 ), -maxs, maxs, Color( 255, 255, 255 ), true )
	render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), -maxs, maxs, clr, true )
	*/
end

if SERVER then

	function ENT:OnTakeDamage( dmginfo )

		ReplicatorGetDamaged( 2, self, dmginfo )
		
	end
end

function ENT:Think()

	self:NextThink( CurTime() + 0.1 )

	//------------ Moving of replicator
	if SERVER then
		
		//
		// ---------- Replicator Class
		//
		
		ReplicatorThink( 2, self )
		
		
	end // SERVER

	// ------------------------- Initialize dark spots
	if CLIENT then
		
		ReplicatorDarkPointAssig( self )

	end // CLIENT

	return true
end

if SERVER then

	function ENT:OnRemove()
	
		ReplicatorOnRemove( self )

	end
	
end