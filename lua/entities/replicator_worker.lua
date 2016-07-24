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

local segments_count = 30

function PlaySequence( self, seq )
	local sequence = self:LookupSequence( seq )
	
	self:SetPlaybackRate( 1.0 )
	self:SetSequence( sequence )
	self:ResetSequence( sequence )
	
	return self:SequenceDuration( sequence )
end

function traceLineHull( startpos, endpos, _maxs, _mins, ignore )
	local tr = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		mins = -_mins,
		maxs = _maxs,
		filter = function( ent ) if ( ent != ignore ) then return true end end
	} )

	return tr
end

function traceLine( startpos, endpos, ignore )
	local tr = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		filter = function( ent ) if ( ent != ignore ) then return true end end
	} )

	return tr
end

function ENT:Initialize()
	if( SERVER ) then
		self:SetModel( "models/stargate/replicators/replicator_worker.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		local phys = self:GetPhysicsObject()

		self:SetHealth( 25 )
		
		self:SetVar( "rMove", false )
		self:SetVar( "rMoveTo", self:GetPos() )
			
		phys:SetMaterial( "gmod_ice" )

		if ( IsValid( phys ) and self:GetVar( "assemble" ) ) then 
			phys:EnableGravity( true )
			phys:EnableMotion( false ) 
			//phys:EnableCollisions( false )
		
			timer.Simple(PlaySequence( self, "assembling" ), function()
				if( self:IsValid() ) then
					PlaySequence( self, "stand" )

					if ( IsValid( phys ) ) then 
						phys:EnableMotion( true )
						phys:EnableCollisions( true )
						phys:Wake()
					end
				end
			end )
		else
			PlaySequence( self, "stand" )
		end
	end
	
	//if( CLIENT ) then
		
		
	//end
end

if( SERVER ) then

	function ENT:OnTakeDamage( dmginfo )
		//self:TakeDamage( dmginfo:GetDamage(), "", "" )
		local damage = dmginfo:GetDamage()
		
		self:SetHealth( self:Health() - damage )

		if( self:Health() <= 0 ) then
			local phys = self:GetPhysicsObject()
			phys:EnableCollisions( false )

			for i = 1, segments_count do
				local ent = ents.Create( "replicator_segment" )
				
				if ( !IsValid( ent ) ) then return end
				ent:SetPos( self:GetPos() + VectorRand() * 3 )
				ent:SetOwner( self:GetOwner() )
				ent:Spawn()
				
				local phys = ent:GetPhysicsObject()
				phys:Wake()
				phys:SetVelocity( VectorRand() * damage * 4 )
				//local phys = ent:GetPhysicsObject()
			end
			
			self:Remove()
		end
	end
	
	function ENT:Think()
		//
		// Moving a replicator
		//
		
		if( SERVER ) then
			local phys = self:GetPhysicsObject()
			
			
			//
			// Wall climbing system
			//											
			local ground = traceLineHull( self:GetPos(), 
											self:GetPos() - self:GetUp() * 10, 
											Vector( 15, 15, 15 ), -Vector( 15, 15, 15 ), self )
			phys:EnableGravity( !ground.Hit )
			
			local velocity = Vector()
			if( ground.Hit ) then
				//print( ground.HitPos:Distance( self:GetPos() ))
				velocity:Add( -self:GetUp() * ground.HitPos:Distance( self:GetPos() ) * 2 )

				local forward = traceLineHull( self:GetPos(), 
												self:GetPos() + self:GetForward() * 20, 
												Vector( 3, 3, 3 ), -Vector( 3, 3, 3 ), self )
												
				//if( forward.Hit ) then phys:SetAngles( self:LocalToWorldAngles( Angle( -20, 0, 0 ) )  ) else	
				if( forward.Hit ) then phys:AddAngleVelocity( Vector( 0, -1000, 0 ) - phys:GetAngleVelocity() ) else	
				
					local fordown = traceLineHull( self:GetPos() + self:GetForward() * 5, 
													self:GetPos() + self:GetForward() * 5 - self:GetUp() * 15, 
													Vector( 3, 3, 3 ),  -Vector( 3, 3, 3 ), self )

					//if( !fordown.Hit ) then phys:SetAngles( self:LocalToWorldAngles( Angle( 20, 0, 0 ) ) ) end
					if( !fordown.Hit ) then phys:AddAngleVelocity( Vector( 0, 1000, 0 ) - phys:GetAngleVelocity() ) end
				end
			else
				local ceiling = traceLineHull( self:GetPos(), 
												self:GetPos() + self:GetUp() * 20, 
												Vector( 10, 10, 10 ), -Vector( 10, 10, 10 ), self )
					
				if( ceiling.Hit ) then phys:AddAngleVelocity( Vector( math.Rand( 0, 1100 ), math.Rand( 0, 500 ), 0 ) - phys:GetAngleVelocity() ) end
			end
			
			if( Entity( 1 ):KeyPressed( IN_RELOAD ) ) then
				PlaySequence( self, "run" )
				self:SetVar( "rMove", true )
			end
			
			if( self:GetVar( "rMove" ) ) then
				velocity:Add( self:GetForward() * 5 )
			end

			velocity:Add( -self:GetVelocity() / 10 )
			
			if( ground.Hit ) then
				phys:AddVelocity( velocity )
				phys:AddAngleVelocity( -phys:GetAngleVelocity() / 5 )			
			end
		end
		
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