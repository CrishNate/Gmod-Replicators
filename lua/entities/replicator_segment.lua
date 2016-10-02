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
		self:SetModelScale( self:GetModelScale() * 1.5, 0 )

		self:SetUnFreezable( true ) 
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		
		self.rAssembling = false
		self.rUsed = Entity( 0 )
		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	

		self.rCraftingQueen = false
		
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
	
	function ENT:PhysicsCollide( data, phys )
	
		if data.Speed > 200 then self:EmitSound( "weapons/fx/tink/shotgun_shell"..math.random( 1, 3 )..".wav", 60, 175 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
		
	end
	
	
	function ENT:OnTakeDamage( dmginfo )
	
		local damage = dmginfo:GetDamage()
		
		self:SetHealth( self:Health() - damage )

		if self:Health() <= 0 then self:Remove() end
	end
	
	function ENT:Think()
	
		if( !self.rUsed:IsValid() ) then

			if( !self.rAssembling ) then
			
				self:NextThink( CurTime() + 1 )
				
				local m_Result = ents.FindInSphere( self:GetPos(), 200 )
				local m_Segments = {}
				local m_Save = {}
				
				table.insert( m_Segments, self )
				
				for k, v in ipairs( m_Result ) do
				
					if( v:GetClass() == "replicator_segment" and 
							v:GetVelocity():Length() < 10 and 
								!v.rAssembling and !v.rUsed:IsValid() and v != self ) then
								
						if not self.rCraftingQueen then
						
							if table.Count( m_Segments ) < g_segments_to_assemble_replicator then table.insert( m_Segments, v ) 
							elseif table.Count( m_Segments ) + table.Count( m_Save ) < g_segments_to_assemble_queen then
								table.insert( m_Save, v )
								
								if table.Count( m_Segments ) + table.Count( m_Save ) == g_segments_to_assemble_queen then
								
									table.Add( m_Segments, m_Save )
									self.rCraftingQueen = true
									
								end
							end
							
						elseif v.rCraftingQueen and table.Count( m_Segments ) < g_segments_to_assemble_queen then table.insert( m_Segments, v ) end
						
					end
				end
				
				if table.Count( m_Segments ) == g_segments_to_assemble_replicator and not self.rCraftingQueen or
					table.Count( m_Segments ) == g_segments_to_assemble_queen and self.rCraftingQueen then
					
					self.rAssembling = true
					self.rAssemblingSegments = m_Segments
					
					local m_Middle = Vector( 0, 0, 0 )
					
					for k, v in ipairs( m_Segments ) do
					
						m_Middle = m_Middle + v:GetPos()
						if v != self then v.rUsed = self end
						
					end
					
					m_Middle = ( m_Middle / table.Count( m_Segments ) )
					
					self.rSegmentsMiddle = m_Middle
					self.rRadius = 0
				end
				
			else
			
				self:NextThink( CurTime() + 0.1 )

				local m_Segments = self.rAssemblingSegments
				local m_Middle = self.rSegmentsMiddle
				
				if self.rRadius < 300 then self.rRadius = self.rRadius + self.rRadius / 10 + 5 else self.rRadius = 300 end
				
				local inx = 0

				if not self.rAssebleSound then
				
					if not self.rCraftingQueen then self:EmitSound( "replicators/repassembling.wav", 60, 100 + math.Rand( 0, 10 ), 1, CHAN_AUTO )
					else self:EmitSound( "replicators/repassembling.wav", 60, 70 + math.Rand( 0, 10 ), 1, CHAN_AUTO ) end
					self.rAssebleSound = true
					
				end

				
				for k, v in ipairs( m_Segments ) do

					if v:IsValid() then
						
						local m_vVel = v:GetVelocity()
						
						if v:GetPos():Distance( m_Middle ) < self.rRadius and m_vVel.z < 10 then
						
							local m_Dir = ( m_Middle - v:GetPos() )
							m_Dir = Vector( m_Dir.x, m_Dir.y, 0 )
							
							m_Dir:Normalize()
							m_Dir = m_Dir * math.min( 200, self.rRadius )
							
							local phys = v:GetPhysicsObject()
							phys:SetVelocity( Vector( m_Dir.x, m_Dir.y, m_vVel.z ))
							phys:SetMaterial( "gmod_ice" )
							
							local t_Rad = 0

							if not self.rCraftingQueen then t_Rad = 5
							else t_Rad = 10 end
							
							if v:GetPos():Distance( m_Middle ) < t_Rad + math.Rand( 0, 5 ) then
							
								phys:EnableMotion( false )
								phys:EnableCollisions( false )
								
							end
							
							if v:GetPos():Distance( m_Middle ) <= t_Rad + 10 then inx = inx + 1 end
							
						end
					end
				end
				
				// ====================== Spawning replicator
				
				if not self.rCraftingQueen and inx == g_segments_to_assemble_replicator
					or self.rCraftingQueen and inx == g_segments_to_assemble_queen then
					
					local m_Ent = Entity( 0 )
					local t_Height = 0
					local t_AddTime = 0
					
					if not self.rCraftingQueen then
					
						m_Ent = ents.Create( "replicator_worker" )
						t_Height = 6
						t_AddTime = 0.5
						
					else
					
						m_Ent = ents.Create( "replicator_queen" )
						t_Height = 13
						t_AddTime = 4
						
					end
					
					if ( !IsValid( m_Ent ) ) then return end
					
					m_Ent:SetOwner( self:GetOwner() )
					m_Ent:SetPos( m_Middle + Vector( 0, 0, t_Height ) )
					m_Ent:SetAngles( Angle( 0, math.Rand( 0, 360 ), 0 ) )
					m_Ent.rAssembling = true
					m_Ent:Spawn()
					
					for k, v in ipairs( m_Segments ) do
					
						local phys = v:GetPhysicsObject()
						
						phys:EnableMotion( false )
						phys:EnableCollisions( false )
						
						v:Fire( "Kill", "", k / ( table.Count( m_Segments ) / t_AddTime ) + math.Rand( 0, 0.25 ) + 1 )
						v.rUsed = v
						
					end
					
					self.rUsed = self
					
				end
			end
		end

		return true
	end
end // SERVER