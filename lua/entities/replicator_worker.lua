AddCSLuaFile()

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
	if( SERVER ) then
		self:SetModel( "models/stargate/replicators/replicator_worker.mdl" )
		//self:SetTrigger( true )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		//self:SetModelScale( self:GetModelScale(), 0 )
		//self:SetVar( "hit", false )
		
		local phys = self:GetPhysicsObject()
		phys:EnableGravity( true )

		local sequence = self:LookupSequence( "assembling" )
		//self:ResetSequence( sequence )
		self:SetPlaybackRate( 1.0 )
		phys:EnableMotion( false ) 
		phys:EnableCollisions( false )
		//self:SetCycle( -1 )
		
		self:SetSequence( sequence )
		timer.Create( "standanim", self:SequenceDuration( sequence ), 0, function()
			if( self:IsValid() ) then
				local sequence = self:LookupSequence( "stand" )
				phys:EnableMotion( true )
				phys:EnableCollisions( true )
				self:SetPlaybackRate( 1.0 )
				self:SetSequence( sequence )
			end
		end )
	end
	
	//if( CLIENT ) then
		
		
	//end
	
	
	/*
	if( CLIENT ) then
		local vec = self:GetPos()
		local emitter = ParticleEmitter( vec, false )
		
		//effects/fire_cloud1
		for cycles = 1, 10 do
			local particle = emitter:Add( Material( "effects/fire_cloud1" ), vec )
			if( particle ) then
				particle:SetVelocity( VectorRand() * 40 )
				particle:SetColor( 0, 100, 255 ) 
				particle:SetLifeTime( 0 )
				particle:SetDieTime( 1 )
				particle:SetAngles( Angle( math.Rand( 0, 360 ), 0, 0 ) )
				particle:SetAngleVelocity( Angle( math.Rand( -1, 1 ), 0, 0 ) )
				particle:SetStartSize( 20 )
				particle:SetEndSize( 10 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetGravity( Vector( 0, 0, 60 ) )
			end
		end
		
		emitter:Finish()
	end
	*/
end

if( SERVER ) then
	function ENT:Think()
		//self:SendViewModelMatchingSequence( sequence )

		self:NextThink( CurTime() )
		return true
	end
	
	/*
	function ENT:PhysicsUpdate( )
		if( !self:GetVar( "hit", NULL ) ) then
			if( self:GetVelocity():Length() < 1000 ) then
				self:SetVar( "hit", true )
				self:Fire( "Kill", "", 10 )
				local phys = self:GetPhysicsObject()
				phys:EnableGravity( true )
			end
		end
	end
	*/
end