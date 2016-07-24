AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Segment"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"

//if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

//
//
//
local segments_count = 30


function ENT:Initialize()
	if( SERVER ) then
		self:SetModel( "models/stargate/replicators/replicator_segment.mdl" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		local phys = self:GetPhysicsObject()
		phys:EnableGravity( true )
		phys:Wake()
		
		self:Activate()
		self:SetUnFreezable( true ) 
		
		self:SetVar( "assembling", false )
		self:SetVar( "used", false )
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
		
		//
		// Assembling segments it to a replicator
		//
		
		if( !self:GetVar( "used" ) ) then
			if( !self:GetVar( "assembling" ) ) then
				self:NextThink( CurTime() + 1 )

				local result = ents.FindInSphere( self:GetPos(), 50 )
				local segments = {}
				
				for k, v in ipairs( result ) do
					if( v:GetClass() == "replicator_segment" and 
							v:GetVelocity():Length() < 10 and 
								table.Count(segments) < segments_count and 
									!v:GetVar( "assembling" ) && !v:GetVar( "used" ) ) then table.Add(segments, { v } ) end
				end
				
				PrintMessage( HUD_PRINTTALK, table.Count(segments) )

				if( table.Count(segments) == segments_count ) then
					self:SetVar( "assembling", true )
					self:SetVar( "assembling_segments", segments )
					
					//local max = 0
					local middle = Vector( 0, 0, 0 )
					for k, v in ipairs( segments ) do
						local a = v:GetPos()
						middle:Add( v:GetPos() )
						
						//if( max < v:GetPos():Distance(self:GetPos()) ) then max = v:GetPos():Distance(self:GetPos()) end
					
						local phys = v:GetPhysicsObject()
						v:Fire( "Kill", "", 4 )
						phys:SetMaterial( "gmod_ice" )
						if( v != self ) then v:SetVar( "used" ) end
					end
					middle = middle / segments_count
					
					v:SetVar( "segments_center", middle )
					//v:SetVar( "dMax", max )
				end

			else
				//local middle = self:GetVar( "segments_center" )
				
				self:NextThink( CurTime() )

				local segments = self:GetVar( "assembling_segments" )

				if( !self:GetVar( "spawn" ) ) then
					local ent = ents.Create( "replicator_worker" )
					
					if ( !IsValid( ent ) ) then return end
					ent:SetPos( self:GetPos() + Vector( 0, 0, 5 ) )
					ent:Spawn()
					
					self:SetVar( "radius", 0 )
					self:SetVar( "spawn", true )
				end
				
				self:SetVar( "radius", self:GetVar( "radius" ) + 1 )
				
				//local inx = 0
				for k, v in ipairs( segments ) do
				
					if( v:GetPos():Distance( self:GetPos() ) < self:GetVar( "radius" ) ) then
						local dir = ( self:GetPos() - v:GetPos() )
						dir:Normalize()
						dir = dir * 50 - v:GetVelocity() / 10
						
						local phys = v:GetPhysicsObject()
						phys:SetVelocity( Vector( dir.x, dir.y, 0 ))
						
						if( v:GetPos():Distance( self:GetPos() ) < 5 ) then
							phys:EnableMotion( false )
							phys:EnableCollisions( false )
							//v:Remove()
							
							if( v != self ) then v:Remove() end
							table.remove( segments, k )
						end
					end
				end
				// Spawning replicator
				/*
				PrintMessage( HUD_PRINTTALK, inx )
				if( inx > segments_count ) then
					local button = ents.Create( "replicator_worker" )
					
					if ( !IsValid( button ) ) then return end
					button:SetPos( self:GetPos() + Vector( 0, 0, 5 ) )
					button:Spawn()
					
					self:SetVar( "used", true )
					
					for k, v in ipairs( segments ) do
						v:Fire( "Kill", "", 2 )
						local phys = v:GetPhysicsObject()
						phys:EnableMotion( false )
					end
				end
				*/
				
				local dir = -self:GetVelocity() * 10
				local phys = self:GetPhysicsObject()
				
				phys:SetVelocity( Vector( dir.x, dir.y, 0 ))
			end
		end

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