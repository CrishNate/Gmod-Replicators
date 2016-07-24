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
// segments to assemble replicator
//
local segments_count = 30


function ENT:Initialize()
	if( SERVER ) then
		self:SetHealth( 10 )

		self:SetModel( "models/stargate/replicators/replicator_segment.mdl" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetModelScale( self:GetModelScale() * 1.5, 0 )

		self:SetUnFreezable( true ) 
		
		self:SetVar( "assembling", false )
		self:SetVar( "used", Entity( 0 ) )
		
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then 
			phys:EnableGravity( true )
			phys:Wake()
		end
	end
	
	if( CLIENT ) then
	end
end

if( SERVER ) then
	function ENT:Think()
		//
		// Assembling segments it to a replicator
		//
		
		//self:SetColor( Color( 0, 0, 0 ) )

		if( !self:GetVar( "used" ):IsValid() ) then
			//self:SetColor( Color( 255, 255, 0) )

			if( !self:GetVar( "assembling" ) ) then
				self:NextThink( CurTime() + 1 )
				//self:SetColor( Color( 0, 255, 0) )

				local result = ents.FindInSphere( self:GetPos(), 200 )
				local segments = {}
				
				table.Add( segments, { self } )
				
				for k, v in ipairs( result ) do
					if( v:GetClass() == "replicator_segment" and 
							v:GetVelocity():Length() < 10 and 
								table.Count(segments) < segments_count and 
									!v:GetVar( "assembling" ) and !v:GetVar( "used" ):IsValid() and v != self ) then table.Add( segments, { v } ) end
				end
				
				//PrintMessage( HUD_PRINTTALK, table.Count( segments ) )
				//PrintTable( segments )
				
				if( table.Count( segments ) == segments_count ) then
					self:SetVar( "assembling", true )
					self:SetVar( "assembling_segments", segments )
					
					local middle = Vector( 0, 0, 0 )
					for k, v in ipairs( segments ) do
						middle = middle + v:GetPos()
						//v:SetColor( Color( 255, 0, 0 ) )
						
						if( v != self ) then v:SetVar( "used", self ) end
					end
					
					middle = ( middle / segments_count )
					
					self:SetVar( "segments_middle", middle )
					self:SetVar( "radius", 0 )
				end

			else
				//self:SetColor( Color( 255, 0, 255 ) )
				
				self:NextThink( CurTime() )

				local segments = self:GetVar( "assembling_segments" )
				local middle = self:GetVar( "segments_middle" )
				
				self:SetVar( "radius", self:GetVar( "radius" ) + 2 )
				
				local inx = 0

				for k, v in ipairs( segments ) do

					local vVel = v:GetVelocity()
					if( v:GetPos():Distance( middle ) < self:GetVar( "radius" ) and vVel.z < 10 ) then
						local dir = ( middle - v:GetPos() )
						dir = Vector( dir.x, dir.y, 0 )
						
						dir:Normalize()
						dir = dir * 50
						
						local phys = v:GetPhysicsObject()
						phys:SetVelocity( Vector( dir.x, dir.y, vVel.z ))
						phys:SetMaterial( "gmod_ice" )
						
						if( v:GetPos():Distance( middle ) < math.Rand( 0, 7 ) ) then
							phys:EnableMotion( false )
							phys:EnableCollisions( false )
						end
						
						if( v:GetPos():Distance( middle ) <= 10 ) then inx = inx + 1 end
						
					end
				end
				
				//------------- Spawning replicator
				
				if( inx == segments_count ) then
					local ent = ents.Create( "replicator_worker" )
					
					if ( !IsValid( ent ) ) then return end
					ent:SetPos( middle + Vector( 0, 0, 6 ) )
					ent:SetAngles( Angle( 0, math.Rand( 0, 360 ), 0 ) )
					ent:SetOwner( self:GetOwner() )
					ent:SetVar( "assemble", true )
					ent:Spawn()
				
					for k, v in ipairs( segments ) do
						local phys = v:GetPhysicsObject()
						phys:EnableMotion( false )
						phys:EnableCollisions( false )
						v:Fire( "Kill", "", math.Rand( 0.5, 1.5 ) )
						v:SetVar( "used", v )
					end
					
					self:SetVar( "used", self )
					//segments = {}
				end
				//*/
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