AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_anim"

ENT.Editable		= true
ENT.PrintName		= "Replicator Gueen"
ENT.Spawnable 		= true
ENT.AdminSpawnable 	= false
ENT.Category		= "Stargate"
ENT.AutomaticFrameAdvance = true 

//if( CLIENT ) then killicon.Add( "ent_undertale_bone_throw", "undertale/killicon_bone", color_white ) end

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/stargate/replicators/replicator_queen.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		local phys = self:GetPhysicsObject()

		self:SetHealth( 100 )

		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	
		
		self:SetVar( "rMove", false )
		self:SetVar( "rMoveMode", 1 )
		
		self:SetVar( "rMoveTo", self:GetPos() )
		self:SetVar( "rMoveStep", 0 )
		
		self:SetVar( "rMetalAmount", 0 )
		
		// -1 Deactivated
		// 0 Research
		// 1 Crafting
		// 2 Attack
		// 3 Defence
		
		self:SetVar( "rMode", 0 )

		self:SetVar( "rModeStatus", 0 )
		self:SetVar( "rYawRot", 0 )
		
		phys:SetMaterial( "gmod_ice" )
		
		if  IsValid( phys ) and self:GetVar( "assemble" ) then 
			
			phys:EnableGravity( true )
			phys:EnableMotion( false ) 
			self:SetVar( "rMode", -1 )
			
			timer.Simple(PlaySequence( self, "assembling" ), function()

				self:SetVar( "rMode", 0 )
			
				if self:IsValid() then
					
					PlaySequence( self, "stand" )
					
					if IsValid( phys ) then 
						phys:EnableMotion( true )
						phys:EnableCollisions( true )
						phys:Wake()
					end
				end
				
			end )
		else
			PlaySequence( self, "stand" )
		end

		//-------- Init point
		//local id = AddPathPoint( self:GetPos(), { } )
		self:SetVar( "rPrevPointId", 0 )
		self:SetVar( "rPrevPos", self:GetPos() )
	end // SERVER

	if CLIENT  then
		
		
	end // CLIENT
end

function ENT:Draw()

	self:DrawModel()
	/*
	render.SetColorMaterial()
	//render.SetMaterial( Material("models/shiny") )
	//render.SetColorModulation( 255, 225, 255 ) 
	render.DrawSphere( self:GetPos() - self:GetForward() * 16 - self:GetUp() * 1, 12, 20, 20, Color( 255, 255, 255,100 ) )
	*/
end
if SERVER then

	function ENT:OnTakeDamage( dmginfo )
		local damage = dmginfo:GetDamage()
		
		self:SetHealth( self:Health() - damage )

		if self:Health() <= 0 then
		
			local phys = self:GetPhysicsObject()
			phys:EnableCollisions( false )

			local ent
			for i = 1, g_segments_to_assemble_replicator do
			
				ent = ents.Create( "replicator_segment" )
				
				if not IsValid( ent ) then return end
				ent:SetPos( self:GetPos() + VectorRand() * 3 )
				ent:SetOwner( self:GetOwner() )
				ent:Spawn()
				
				local phys = ent:GetPhysicsObject()
				phys:Wake()
				phys:SetVelocity( VectorRand() * damage * 4 )
				
			end
			ent:EmitSound( "npc/manhack/gib.wav", 75, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
			
			self:Remove()
		end
		
	end
end

function ENT:Think()

	//------------ Moving of replicator
	if SERVER then
	
		local h_phys = self:GetPhysicsObject()
		local h_Move = self:GetVar( "rMove" )
		local h_MoveMode = self:GetVar( "rMoveMode" )

		local mm = Vector( 10, 10, 10 )
		local ground, groundDist = traceHullQuick( 
			self:GetPos(), 
			-self:GetUp() * 20, 
			mm, replicatorNoCollideGroup_Witch )

		// ----------------------------------- Modes

		local t_Mode = self:GetVar( "rMode" )
		local t_ModeStatus = self:GetVar( "rModeStatus" )
		local t_PrevId = self:GetVar( "rPrevPointId" )

		// ----------------------------------- Research mode
		if t_Mode == 0 then
			
			if t_ModeStatus == 0 then
			
				self:SetVar( "rMove", true )
				self:SetVar( "rModeStatus", -1 )
				
			elseif t_ModeStatus == -1 then
			
				self:SetVar( "rModeStatus", 1 )
				
				timer.Simple( math.Rand( 2, 8 ), function()
				
					if self:IsValid() then
					
						local t_Mode = self:GetVar( "rMode" )
					
						if t_Mode == 0 then
							
							self:SetVar( "rYawRot", math.Rand( 5, -5 ) )
							self:SetVar( "rModeStatus", -1 )
							
						end
						
					end
					
				end )
				
			end
			
			local t_MoveTo = self:GetPos() + self:GetForward() * 40 + self:GetRight() * t_YawRot
		
			self:SetVar( "rMoveTo", t_MoveTo )
		
		// ----------------------------------- Getting metal
		elseif t_Mode == 1 then
			
			local t_TargetMetalId = self:GetVar( "rTargetMetalId" )
			
			if t_ModeStatus == 0 then
				if ground.HitPos:Distance( m_metalPoints[ t_TargetMetalId ].pos ) < 50 then
					self:SetVar( "rMoveMode", 0 )
				else
					self:SetVar( "rMoveMode", 1 )
				end

				if ground.MatType == MAT_METAL and ground.HitWorld and ground.HitPos:Distance( m_metalPoints[ t_TargetMetalId ].pos ) < 10 then

					timer.Destroy( "rWalking" .. tostring( self:EntIndex() ) )
					timer.Destroy( "rRun" .. tostring( self:EntIndex() ) )
					
					self:SetVar( "rMove", false )
					self:SetVar( "rMoveStep", 0 )
					self:SetVar( "rModeStatus", 1 )
					
					h_phys:EnableMotion( false )
					h_phys:EnableCollisions( false )
				end
				
			// ----------------------------------- Eating metal
			elseif t_ModeStatus == 1 then
				
				self:SetVar( "rModeStatus", -1 )
				
				timer.Simple( PlaySequence( self, "crafting" ), function()
				
					if self:IsValid() then
					
						t_TargetMetalId = self:GetVar( "rTargetMetalId" )

						local t_targetMetalAmount = m_metalPoints[ t_TargetMetalId ].amount
						local t_rMetalAmount = self:GetVar( "rMetalAmount" )

						t_ModeStatus = self:GetVar( "rModeStatus" )
						
						if t_ModeStatus == -1 then
							local t_Amount = g_replicator_collection_speed

							if t_targetMetalAmount < t_Amount then
								t_Amount = t_targetMetalAmount
							end

							if t_rMetalAmount + t_Amount < g_segments_to_assemble_replicator
								or table.Count( m_queenCount ) == 0 and t_rMetalAmount + t_Amount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator ) then
								
								self:SetVar( "rModeStatus", 1 )
							else
								// --------- Next Step
								m_metalPoints[ t_TargetMetalId ].used = false
								self:SetVar( "rModeStatus", 2 )
							end
							
							if t_targetMetalAmount == 0 then
								t_Reset = true
								self:SetVar( "rMode", 0 )
								self:SetVar( "rMove", true )
								self:SetVar( "rMoveMode", 1 )

								
								h_phys:EnableMotion( true )
								h_phys:EnableCollisions( true )
							end
							
							UpdateMetalPoint( t_TargetMetalId, t_targetMetalAmount - t_Amount )
							//m_metalPoints[ t_TargetMetalId ].amount = t_targetMetalAmount - t_Amount
							t_rMetalAmount = t_rMetalAmount + t_Amount
							
							print( t_Amount, t_rMetalAmount )
							self:SetVar( "rMetalAmount", t_rMetalAmount )
							
						end
						
					end
				end )
				
			// ----------------------------------- Transporting metal
			elseif t_ModeStatus == 2 then

				
				if table.Count( m_queenCount ) > 0 then
				
				elseif table.Count( m_darkPoints ) > 0 then
					self:SetVar( "rMove", true )
					h_phys:EnableMotion( true )
					h_phys:EnableCollisions( true )

					local t_PathResult, t_DarkId = GetPatchWayToClosestDark( t_PrevId )

					if table.Count( t_PathResult ) > 0 then
						self:SetVar( "rMode", 4 )
						
						table.Add( m_queenCount, { self } )
						
						self:SetVar( "rModeStatus", 1 )
						
						self:SetVar( "rTargetDarkId", t_DarkId )
						
						self:SetVar( "rMove", true )
						self:SetVar( "rMoveStep", 1 )
						self:SetVar( "rMovePath", t_PathResult )
					end
				end
				
			end
			
		elseif t_Mode == 2 then
		elseif t_Mode == 3 then
		elseif t_Mode == 4 then
			
			if t_ModeStatus == 1 then
			
				local t_DarkId = self:GetVar( "rTargetDarkId" )
			

				if ground.HitPos:Distance( m_darkPoints[ t_DarkId ].pos ) < 50 then
					self:SetVar( "rMoveMode", 0 )
				else
					self:SetVar( "rMoveMode", 1 )
				end

				if m_darkPoints[ t_DarkId ].pos:Distance( self:GetPos() ) < 15 then

					timer.Destroy( "rWalking" .. tostring( self:EntIndex() ) )
					timer.Destroy( "rRun" .. tostring( self:EntIndex() ) )
					
					self:SetVar( "rMove", false )
					self:SetVar( "rMoveStep", 0 )
					self:SetVar( "rModeStatus", 2 )
					
					timer.Simple( PlaySequence( self, "crafting_start" ), function()
						timer.Create( "rCrafting" .. tostring( self:EntIndex() ), PlaySequence( self, "crafting" ), 0, function()
						
							if self:IsValid() then
								if self:GetVar( "rMetalAmount" ) >= 1 then
									local ent = ents.Create( "replicator_segment" )
									self:EmitSound( "physics/metal/weapon_impact_soft" .. math.random( 1, 3 ) .. ".wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
									
									if ( !IsValid( ent ) ) then return end
									ent:SetPos( self:GetPos() + self:GetForward() * 6 - self:GetUp() * 3 )
									ent:SetAngles( AngleRand() )
									ent:SetOwner( self:GetOwner() )
									ent:Spawn()
									
									local phys = ent:GetPhysicsObject()
									phys:Wake()
									phys:SetVelocity( VectorRand() * 20 + self:GetForward() * 40 )	
									
									self:SetVar( "rMetalAmount", self:GetVar( "rMetalAmount" ) - 1 )
								end
							end
							
						end )
					end )
					
					h_phys:EnableMotion( false )
					h_phys:EnableCollisions( false )
				end

			elseif t_ModeStatus == 2 then
			end
		end

	
		//-------------- Wall climbing / walking system
		
		h_phys:EnableGravity( !ground.Hit )
		
		local velocity = Vector()
		
		if h_Move then
			if ground.Hit then

				if h_MoveMode == 0 then velocity:Add( self:GetForward() * 5 )
				else velocity:Add( self:GetForward() * 7 ) end
			
				velocity:Add( -self:GetUp() * groundDist * 2 )
				
				mm = Vector( 8, 8, 8 )
				
				local forward, forwardDist = traceHullQuick( 
					self:GetPos(), 
					self:GetForward() * 20, 
					mm, replicatorNoCollideGroup_Witch )
					
				local lForward, lForwardDist = traceQuick(
					self:GetPos() - self:GetUp() * 13.5,
					self:GetForward() * 20,
					replicatorNoCollideGroup_Witch )

				if forward.Hit or lForward.Hit then
				
					local rotation = 500 * math.max( 1 - forwardDist / 20, 0.5 )
					h_phys:AddAngleVelocity( Vector( 0, -rotation, 0 ) - h_phys:GetAngleVelocity() )
					
					local lh = math.min( 0, forwardDist - lForwardDist ) / 15
					velocity = velocity / math.max( forwardDist / math.max( 10 - lh * 10, 1 ), 1 )
					
					local t_Stabilization = self:GetPos() + self:GetVelocity()
					t_Stabilization = self:WorldToLocal( t_Stabilization )
					t_Stabilization = -Vector( t_Stabilization.x, t_Stabilization.y , 0 )
					t_Stabilization = self:LocalToWorld( t_Stabilization )
					t_Stabilization = t_Stabilization - self:GetPos()
					
					velocity:Add( t_Stabilization )
				else
				
					local fordown, fordownDist = traceHullQuick( 
						self:GetPos() + self:GetForward() * 10, 
						-self:GetUp() * 20, 
						mm, replicatorNoCollideGroup_Witch )

					if not fordown.Hit then
					
						local rotation = 1200 * math.max( 1 - fordownDist / 20, 0.25 )
						h_phys:AddAngleVelocity( Vector( 0, rotation, 0 ) - h_phys:GetAngleVelocity() )
						
					end
					
				end
			else
				mm = Vector( 20, 20, 20 )
				
				local ceiling = traceHullQuick( 
					self:GetPos(), 
					self:GetUp() * 15, 
					mm, replicatorNoCollideGroup_Witch )
					
				if ceiling.Hit then
				
					local zeroAng = self:WorldToLocalAngles( Angle( 0, self:GetAngles().y, 0 ) )
					h_phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, 0 ) * 15 - h_phys:GetAngleVelocity() )
					
				end
			end
			
		end
		
		local point = m_pathPoints[ t_PrevId ]
		
		local t_Reset = false
		
		if ground.Hit then	
		
			if( h_Move ) then
			
				local JUANG = self:WorldToLocalAngles( ( self:GetVar( "rMoveTo" ) - self:GetPos() ):Angle() ).y
				
				h_phys:AddAngleVelocity( Vector( 0, 0, JUANG ) * 2 )				
			end

			// ---------------------------------------------------- Modes moving
			local t_YawRot = self:GetVar( "rYawRot" )
			
			
			local t_MoveStep = self:GetVar( "rMoveStep" )
			local t_MovePath = self:GetVar( "rMovePath" )
			
			// ---------------------------------------------------- Path moving
			if t_MoveStep > 0 then
			
				if table.Count( t_MovePath ) > 0 then
				
					local t_MToPos
					local t_Dist
					local t_DistTo
					
					if t_MoveStep == table.Count( t_MovePath ) then
					
						t_MToPos = t_MovePath[ t_MoveStep ]
						t_Dist = 5
						t_DistTo = ground.HitPos
						
					else
					
						local t_Id = t_MovePath[ t_MoveStep ]
						
						t_MToPos = m_pathPoints[ t_Id ].pos
						t_Dist = 50
						t_DistTo = self:GetPos()
						
					end
					
					if t_MToPos:Distance( t_DistTo ) > t_Dist then
					
						self:SetVar( "rMoveTo", t_MToPos )
						
					else
					
						if t_MoveStep < table.Count( t_MovePath ) then
						
							self:SetVar( "rMoveStep", t_MoveStep + 1 )
							
						end
					end					
				end
			end
		
			velocity:Add( -self:GetVelocity() / 10 )

			h_phys:AddVelocity( velocity )
			h_phys:AddAngleVelocity( -h_phys:GetAngleVelocity() / 5 )
			
			//------------------- Pathway			
		
			if point then
			
				local prevPos = self:GetVar( "rPrevPos" )
				self:SetVar( "rPrevPos", ground.HitPos )
				
				if point.pos:Distance( ground.HitPos ) > 50 or traceLine( ground.HitPos, point.pos, replicatorNoCollideGroup_Witch ).Hit then
				
					local id = AddPathPoint( prevPos, { t_PrevId } )
					
					self:SetVar( "rPrevPointId", id )
					t_Reset = true
					
				end
				
			else
			
				local id = AddPathPoint( ground.HitPos, { } )
				
				self:SetVar( "rPrevPointId", id )
				t_Reset = true
				
			end
			
		elseif point and point.pos:Distance( ground.HitPos ) > 50 then self:SetVar( "rPrevPointId", 0 ) end
		
		
		// ------ Stand animation
		local t_tNameWalk = "rWalking" .. tostring( self:EntIndex() )
		local t_tNameRun = "rRun" .. tostring( self:EntIndex() )

		if not h_Move then
			if timer.Exists( t_tNameWalk ) or timer.Exists( t_tNameRun ) then
				timer.Destroy( t_tNameWalk )
				timer.Destroy( t_tNameRun )
				PlaySequence( self, "stand" )
			end
		end
		
		// ------ Walk animation
		if h_Move and h_MoveMode == 0 and not timer.Exists( t_tNameWalk ) then
			timer.Destroy( t_tNameRun )
			
			timer.Create( t_tNameWalk, PlaySequence( self, "walk" ) / 2, 0, function()
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			end )
		end
		
		// ------ Run animation
		if h_Move and h_MoveMode == 1 and not timer.Exists( t_tNameRun ) then
			timer.Destroy( t_tNameWalk )
			
			timer.Create( t_tNameRun, PlaySequence( self, "run" ) / 2, 0, function()
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			end )
			
		end

		// ------------------------ Metal identification
		local t_Pos = ground.HitPos / 30
		
		t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * 30
		t_Pos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )

		if ground.MatType == MAT_METAL and ground.HitWorld and not m_metalPoints[ t_Pos ] then
		
			AddMetalPoint( t_Pos, ground.HitPos, ground.HitNormal, 100 )
			
		end
		
		// ------------------------- Setting path to metal
		if table.Count( m_metalPoints ) > 0 and t_Reset and t_Mode != 4 and t_PrevId > 0 then
		
			local t_PathResult, t_MetalId = GetPatchWayToClosestMetal( t_PrevId )
			
			if table.Count( t_PathResult ) > 0 then
			
				self:SetVar( "rMode", 1 )
				self:SetVar( "rModeStatus", 0 )
				
				self:SetVar( "rTargetMetalId", t_MetalId )
				
				self:SetVar( "rMove", true )
				self:SetVar( "rMoveStep", 1 )
				self:SetVar( "rMovePath", t_PathResult )
				
			end
			
		end
		
	end // SERVER

	// ------------------------- Initialize dark spots
	if CLIENT then

		local mm = Vector( 10, 10, 10 )
		local ground, groundDist = traceHullQuick( 
			self:GetPos(), 
			-self:GetUp() * 20, 
			mm, replicatorNoCollideGroup_Witch )
			
		local t_lColor = render.GetLightColor( self:GetPos() )
		local t_DarkLevel = ( t_lColor.x + t_lColor.y + t_lColor.z ) / 3 * 100
		
		local t_HitNormal = ground.HitNormal
		t_HitNormal = Vector( math.Round( t_HitNormal.x ), math.Round( t_HitNormal.y ), math.Round( t_HitNormal.z ) )

		local t_Pos = self:GetPos() / 100
		t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * 100
		
		local t_StringPos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )
		
		if t_HitNormal == Vector( 0, 0, 1 ) and t_DarkLevel < 10 and not m_darkPoints[ t_StringPos ] then AddDarkPoint( t_StringPos, ground.HitPos ) end
		
	end // CLIENT

	self:NextThink( CurTime() )
	return true
end