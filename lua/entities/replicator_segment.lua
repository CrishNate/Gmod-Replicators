AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= false
ENT.PrintName		= "Replicator Segment"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"

//if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

function ENT:Initialize()
	if SERVER  then
		self:SetHealth( 150 )

		self:SetModel( "models/stargate/replicators/replicator_segment.mdl" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		//self:SetModelScale( self:GetModelScale() * 1.5, 0 )

		self:SetUnFreezable( true ) 
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		
		self:SetVar( "assembling", false )
		self:SetVar( "used", Entity( 0 ) )
		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	

		self:SetVar( "rCraftingQueen", false )
		
		local phys = self:GetPhysicsObject()
		
		if IsValid( phys ) then 
			phys:EnableGravity( true )
			phys:Wake()
		end
	end //SERVER

	if CLIENT then
	end //CLIENT
end

if SERVER then

	//
	// Hit sounds
	//

	
	function ENT:PhysicsCollide( data, phys )
		if data.Speed > 200 then self:EmitSound( "weapons/fx/tink/shotgun_shell"..math.random( 1, 3 )..".wav", 60, 175 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
	end
	
	
	function ENT:OnTakeDamage( dmginfo )
		//self:TakeDamage( dmginfo:GetDamage(), "", "" )
		local damage = dmginfo:GetDamage()
		
		self:SetHealth( self:Health() - damage )

		if( self:Health() <= 0 ) then
			self:Remove()
		end
	end
	
	function ENT:Think()
		//
		// Assembling segments it to a replicator
		//

		if( !self:GetVar( "used" ):IsValid() ) then

			if( !self:GetVar( "assembling" ) ) then
				self:NextThink( CurTime() + 1 )
				
				local result = ents.FindInSphere( self:GetPos(), 200 )
				local segments = {}
				local save = {}
				
				table.Add( segments, { self } )
				
				for k, v in ipairs( result ) do
					if( v:GetClass() == "replicator_segment" and 
							v:GetVelocity():Length() < 10 and 
								!v:GetVar( "assembling" ) and !v:GetVar( "used" ):IsValid() and v != self ) then
								
									if not self:GetVar( "rCraftingQueen" ) then
									
										if table.Count( segments ) < g_segments_to_assemble_replicator then table.Add( segments, { v } ) 
										elseif table.Count( segments ) + table.Count( save ) < g_segments_to_assemble_queen then
											table.Add( save, { v } )
											
											if table.Count( segments ) + table.Count( save ) == g_segments_to_assemble_queen then
												table.Add( segments, save )
												self:SetVar( "rCraftingQueen", true )
											end
											
										end
										
									elseif v:GetVar( "rCraftingQueen" ) and table.Count( segments ) < g_segments_to_assemble_queen then table.Add( segments, { v } ) end
								end
				end
				
				if table.Count( segments ) == g_segments_to_assemble_replicator and not self:GetVar( "rCraftingQueen" ) or
					table.Count( segments ) == g_segments_to_assemble_queen and self:GetVar( "rCraftingQueen" ) then
					
					self:SetVar( "assembling", true )
					self:SetVar( "assembling_segments", segments )
					
					local middle = Vector( 0, 0, 0 )
					
					for k, v in ipairs( segments ) do
						middle = middle + v:GetPos()
						if v != self then v:SetVar( "used", self ) end
					end
					
					middle = ( middle / table.Count( segments ) )
					
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
					if v:GetPos():Distance( middle ) < self:GetVar( "radius" ) and vVel.z < 10 then
						local dir = ( middle - v:GetPos() )
						dir = Vector( dir.x, dir.y, 0 )
						
						dir:Normalize()
						dir = dir * 50
						
						local phys = v:GetPhysicsObject()
						phys:SetVelocity( Vector( dir.x, dir.y, vVel.z ))
						phys:SetMaterial( "gmod_ice" )
						
						if v:GetPos():Distance( middle ) < math.Rand( 0, table.Count( segments ) / 10 ) + 5 then
							phys:EnableMotion( false )
							phys:EnableCollisions( false )
						end
						
						if v:GetPos():Distance( middle ) <= ( table.Count( segments ) / 10 + 5 ) then inx = inx + 1 end
						
					end
				end
				
				//------------- Spawning replicator
				
				if not self:GetVar( "rCraftingQueen" ) and inx == g_segments_to_assemble_replicator
					or self:GetVar( "rCraftingQueen") and inx == g_segments_to_assemble_queen then
					
					local ent
					local t_Height
					local t_AddTime
					
					if not self:GetVar( "rCraftingQueen" ) then
						ent = ents.Create( "replicator_worker" )
						t_Height = 6
						t_AddTime = 0
					else
						ent = ents.Create( "replicator_queen" )
						t_Height = 13
						t_AddTime = 4
					end
					
					if ( !IsValid( ent ) ) then return end
					
					ent:SetOwner( self:GetOwner() )
					ent:SetPos( middle + Vector( 0, 0, t_Height ) )
					ent:SetAngles( Angle( 0, math.Rand( 0, 360 ), 0 ) )
					ent:SetVar( "assemble", true )
					ent:Spawn()
					
				
					for k, v in ipairs( segments ) do
						local phys = v:GetPhysicsObject()
						
						phys:EnableMotion( false )
						phys:EnableCollisions( false )
						
						v:Fire( "Kill", "", k / ( table.Count( segments ) / t_AddTime ) + math.Rand( 0, 0.25 ) + 1 )
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
end // SERVER