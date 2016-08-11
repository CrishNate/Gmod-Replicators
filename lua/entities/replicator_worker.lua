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
	if SERVER then
		self:SetModel( "models/stargate/replicators/replicator_worker.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		local phys = self:GetPhysicsObject()

		self:SetHealth( 25 )
		
		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	

		self:SetVar( "rMove", false )
		self:SetVar( "rMoveMode", 1 )
		
		self:SetVar( "rMoveTo", self:GetPos() )
		self:SetVar( "rMoveStep", 0 )
		
		self:SetVar( "rTargetEnt", Entity( 0 ) )
		self:SetVar( "rTargetMetalId", 0 )
		
		self:SetVar( "rMetalAmount", 0 )
		
		// -1 Deactivated
		// 0 Research
		// 1 Work
		// 2 Attack
		// 3 Defence
		// 4 Transform
		
		self:SetVar( "rMode", 0 )

		// Research 0 - Stay 1 - Walk
		// Work 0 - Moving 1 - Eating
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
						//phys:EnableCollisions( true )
						phys:Wake()
					end
				end
				
			end )
		else
			PlaySequence( self, "stand" )
		end

		//-------- Init point
		//local id = AddPathPoint( self:GetPos(), { } )
		self:SetVar( "rPrevPointId", { case = "", index = 0 } )
		self:SetVar( "rPrevPos", self:GetPos() )
	end // SERVER

	if CLIENT  then
		
		
	end // CLIENT
end
/*
function ENT:Draw()

	self:DrawModel()

	local ent = self

	local maxs = Vector( 4, 4, 4 )
	local startpos = ent:GetPos() - ent:GetUp() * 5
	local dir = ent:GetForward() * 15

	local tr = traceLine( startpos, startpos + dir, maxs, ent )

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

	self:NextThink( CurTime() )

	//------------ Moving of replicator
	if SERVER then
	
		local h_phys = self:GetPhysicsObject()
		local h_Move = self:GetVar( "rMove" )
		local h_MoveMode = self:GetVar( "rMoveMode" )
		local t_YawRot = self:GetVar( "rYawRot" )
		local t_Reset = false
		
		local mm = Vector( 4, 4, 4 )
		local ground, groundDist = traceHullQuick( 
			self:GetPos(), 
			-self:GetUp() * 15, 
			mm, replicatorNoCollideGroup_Witch )

		// ----------------------------------- Modes

		local t_Mode = self:GetVar( "rMode" )
		local t_ModeStatus = self:GetVar( "rModeStatus" )
		local t_PrevInfo = self:GetVar( "rPrevPointId" )

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
						
							self:SetVar( "rYawRot", math.Rand( 3, -3 ) )
							
							print( self:GetVar( "rYawRot" ) )
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

					timer.Destroy( "rRefind"..self:EntIndex() )
					timer.Destroy( "rWalking" .. tostring( self:EntIndex() ) )
					timer.Destroy( "rRun" .. tostring( self:EntIndex() ) )
					
					self:SetVar( "rMove", false )
					self:SetVar( "rMoveStep", 0 )
					self:SetVar( "rModeStatus", 1 )
					
					h_phys:EnableMotion( false )
					//h_phys:EnableCollisions( false )
				end
				
			// ----------------------------------- Eating metal
			elseif t_ModeStatus == 1 then
				
				self:SetVar( "rModeStatus", -1 )
				
				self:NextThink( CurTime() + 100 )
				timer.Simple( PlaySequence( self, "eating" ), function()
				
					if self:IsValid() then
					
						t_TargetMetalId = self:GetVar( "rTargetMetalId" )

						local t_targetMetalAmount = m_metalPoints[ t_TargetMetalId ].amount
						local t_rMetalAmount = self:GetVar( "rMetalAmount" )

						t_ModeStatus = self:GetVar( "rModeStatus" )
						
						if t_ModeStatus == -1 then
							self:NextThink( CurTime() )
							
							local t_Amount = g_replicator_collection_speed

							if t_targetMetalAmount < t_Amount then
								t_Amount = t_targetMetalAmount
							end

							if t_rMetalAmount + t_Amount < g_segments_to_assemble_replicator
								or table.Count( m_queenCount ) == 0 and t_rMetalAmount + t_Amount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator ) then
								
								self:SetVar( "rModeStatus", 1 )
							else
								// --------- Next Step
								//m_metalPoints[ t_TargetMetalId ].used = false
								
								self:SetVar( "rModeStatus", 2 )
							end
							
							if t_targetMetalAmount == 0 then
								table.RemoveByValue( m_metalPoints, t_TargetMetalId )
								print( "REMOVE METAL" )
								
								t_Reset = true
								self:SetVar( "rMode", 0 )
								self:SetVar( "rMove", true )
								self:SetVar( "rMoveMode", 1 )
								self:SetVar( "rMoveReverse", false )
								self:SetVar( "rTargetEnt", Entity( 0 ) )
								
								h_phys:EnableMotion( true )
								//h_phys:EnableCollisions( true )
								
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
				
					local t_PathResult
					local t_QueenEnt
					
					if self:GetVar( "rTargetEnt" ):IsValid() then
					
						t_PathResult = self:GetVar( "rMovePath" )
						t_QueenEnt = self:GetVar( "rTargetEnt" )
						
						self:SetVar( "rMoveReverse", false )
					else
						t_PathResult = { self:GetPos() }

						local t_PathGet
						t_PathGet, t_QueenEnt = GetPatchWayToClosestEnt( t_PrevInfo, m_queenCount )
						
						table.Add( t_PathResult, t_PathGet )
					end
					
					if table.Count( t_PathResult ) > 0 then
					
						self:SetVar( "rMode", 1 )
						self:SetVar( "rModeStatus", 3 )
						
						self:SetVar( "rTargetEnt", t_QueenEnt )
						
						self:SetVar( "rMove", true )
						self:SetVar( "rMoveMode", 1 )
						
						self:SetVar( "rMoveStep", 1 )
						self:SetVar( "rMovePath", t_PathResult )
						
						h_phys:EnableMotion( true )
						//h_phys:EnableCollisions( true )
					end
					
				elseif table.Count( m_darkPoints ) > 0 then
					self:SetVar( "rMove", true )
					h_phys:EnableMotion( true )
					//h_phys:EnableCollisions( true )

					local t_PathResult, t_DarkId = GetPatchWayToClosestDark( t_PrevInfo )

					if table.Count( t_PathResult ) > 0 then
						
						self:SetVar( "rMode", 4 )
						self:SetVar( "rModeStatus", 1 )

						self:SetVar( "rMoveReverse", false )
						
						self:SetVar( "rTargetDarkId", t_DarkId )
						
						self:SetVar( "rMove", true )
						self:SetVar( "rMoveStep", 1 )
						self:SetVar( "rMovePath", t_PathResult )
					end
				end
				
			elseif t_ModeStatus == 3 then
			
				local t_QueenEnt = self:GetVar( "rTargetEnt" )
				
				if t_QueenEnt:GetPos():Distance( self:GetPos() ) < 40 then
					self:SetVar( "rModeStatus", 4 )
					self:SetVar( "rMove", false )
					h_phys:EnableMotion( false )
				end
				
			elseif t_ModeStatus == 4 then
			
				self:SetVar( "rModeStatus", -2 )

				print( "give metal" )
				self:NextThink( CurTime() + 100 )
				
				timer.Simple( PlaySequence( self, "stand" ), function()
				
					if self:IsValid() then
						self:NextThink( CurTime() )
					
						local t_QueenEnt = self:GetVar( "rTargetEnt" )
						t_ModeStatus = self:GetVar( "rModeStatus" )
					
						if t_ModeStatus == -2 then
							
							local t_rMetalAmount = math.min( g_replicator_giving_speed, self:GetVar( "rMetalAmount" ) )

							t_QueenEnt:SetVar( "rMetalAmount" , t_QueenEnt:GetVar( "rMetalAmount" ) + t_rMetalAmount )
							self:SetVar( "rMetalAmount", self:GetVar( "rMetalAmount" ) - t_rMetalAmount )
							
							if t_rMetalAmount == 0 then
							
								self:SetVar( "rMoveReverse", true )
								
								h_phys:EnableMotion( true )
								self:SetVar( "rMove", true )
								self:SetVar( "rMode", 1 )
								self:SetVar( "rModeStatus", 0 )
								
							else
								self:SetVar( "rModeStatus", 4 )
							end
							
						end
						
					end
				end )
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

				if m_darkPoints[ t_DarkId ].pos:Distance( self:GetPos() ) < 5 then

					timer.Destroy( "rWalking" .. tostring( self:EntIndex() ) )
					timer.Destroy( "rRun" .. tostring( self:EntIndex() ) )
					
					self:SetVar( "rMove", false )
					self:SetVar( "rMoveStep", 0 )
					self:SetVar( "rModeStatus", 2 )
					
					timer.Simple( PlaySequence( self, "crafting_start" ), function()
						timer.Create( "rCrafting" .. tostring( self:EntIndex() ), PlaySequence( self, "crafting" ) / 10, 0, function()
						
							if self:IsValid() then
								if self:GetVar( "rMetalAmount" ) >= 1 then
									local ent = ents.Create( "replicator_segment" )
									self:EmitSound( "physics/metal/weapon_impact_soft" .. math.random( 1, 3 ) .. ".wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
									
									if ( !IsValid( ent ) ) then return end
									ent:SetPos( self:GetPos() + self:GetForward() * 6 - self:GetUp() * 3 )
									ent:SetAngles( AngleRand() )
									ent:SetOwner( self:GetOwner() )
									ent:Spawn()
									
									ent:SetVar( "rCraftingQueen", true )
									
									local phys = ent:GetPhysicsObject()
									phys:Wake()
									phys:SetVelocity( VectorRand() * 40 + self:GetForward() * 60 )	
									
									self:SetVar( "rMetalAmount", self:GetVar( "rMetalAmount" ) - 1 )
								else
									// ------------------------------- Self Destruction
									//table.remove( m_darkPoints, t_DarkId )
									m_darkPoints[ t_DarkId ].used = false
									
									for i = 1, g_segments_to_assemble_replicator do
	
										local ent = ents.Create( "replicator_segment" )
										
										if not IsValid( ent ) then return end
										ent:SetPos( self:GetPos() + VectorRand() * 3 )
										ent:SetOwner( self:GetOwner() )
										ent:Spawn()
										
										ent:SetVar( "rCraftingQueen", true )
										
										local phys = ent:GetPhysicsObject()
										phys:Wake()
										phys:SetVelocity( VectorRand() * 100 )
										
									end
									
									self:Remove()
								end
							end
							
						end )
					end )
					
					h_phys:EnableMotion( false )
					//h_phys:EnableCollisions( false )
				end

			elseif t_ModeStatus == 2 then
			end
		end
		
		//-------------- Wall climbing / walking system
		
		h_phys:EnableGravity( !ground.Hit )
		
		local velocity = Vector()
		
		if h_Move then
			if h_MoveMode == 0 then velocity:Add( self:GetForward() * 2 )
			else velocity:Add( self:GetForward() * 4 ) end

			if ground.Hit then
			
				velocity:Add( -self:GetUp() * groundDist * 2 )
				
				mm = Vector( 4, 4, 4 )
				
				local forward, forwardDist = traceHullQuick( 
					self:GetPos(), 
					self:GetForward() * 15, 
					mm, replicatorNoCollideGroup_Witch )
					
				local lForward, lForwardDist = traceQuick(
					self:GetPos() - self:GetUp() * 6,
					self:GetForward() * 20,
					replicatorNoCollideGroup_Witch )

				if forward.Hit or lForward.Hit then
					local rotation = 1000 * math.max( 1 - forwardDist / 20, 0.5 )
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
						-self:GetUp() * 10, 
						mm, replicatorNoCollideGroup_Witch )

					if not fordown.Hit then
					
						local rotation = 1200 * math.max( 1 - fordownDist / 20, 0.25 )
						h_phys:AddAngleVelocity( Vector( 0, rotation, 0 ) - h_phys:GetAngleVelocity() )
						
					end
					
				end
			else
				mm = Vector( 15, 15, 15 )
				
				local ceiling = traceHullQuick( 
					self:GetPos(), 
					self:GetUp() * 15, 
					mm, replicatorNoCollideGroup_Witch )
					
				if ceiling.Hit then
				
					local zeroAng = self:WorldToLocalAngles( Angle( 0, self:GetAngles().y, 0 ) )
					h_phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, 0 ) * 10 - h_phys:GetAngleVelocity() )
					
				end
			end
			
		end
		
		local point = {}
		
		
		if m_pathPoints[ t_PrevInfo.case ] then point = m_pathPoints[ t_PrevInfo.case ][ t_PrevInfo.index ] end
		
		
		if ground.Hit then	
		
			if( h_Move ) then
			
				local JUANG = self:WorldToLocalAngles( ( self:GetVar( "rMoveTo" ) - self:GetPos() ):Angle() ).y
				
				h_phys:AddAngleVelocity( Vector( 0, 0, JUANG ) * 2 )
				
			end

			// ---------------------------------------------------- Modes moving
			
			
			// ---------------------------------------------------- Path moving
			local t_MoveStep = self:GetVar( "rMoveStep" )

			if t_MoveStep > 0 then
			
				local t_MovePath = self:GetVar( "rMovePath" )

				if table.Count( t_MovePath ) > 0 then
				
					local t_MoveReverse = self:GetVar( "rMoveReverse" )
				
					local t_MToPos
					local t_Dist
					local t_DistTo
					
					if not timer.Exists( "rRefind"..self:EntIndex() ) then
					
						timer.Create( "rRefind"..self:EntIndex(), 10, 1, function()
							
							if self:IsValid() then
								t_TargetMetalId = self:GetVar( "rTargetMetalId" )
								
								m_metalPoints[ t_TargetMetalId ].used = false

								t_Reset = true
								self:SetVar( "rMode", 0 )
								self:SetVar( "rMove", true )
								self:SetVar( "rMoveMode", 1 )
								self:SetVar( "rMoveReverse", false )
								self:SetVar( "rTargetEnt", Entity( 0 ) )
								
								h_phys:EnableMotion( true )
							end
							
						end )
						
					end
					
					if t_MoveReverse then
					
						if t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 and not m_pathPoints[ t_MovePath[ t_MoveStep ] ] then
							
							t_MToPos = t_MovePath[ t_MoveStep ]
							t_Dist = 40
							t_DistTo = self:GetPos()
							
						else
						
							local t_Id = t_MovePath[ t_MoveStep ]

							t_MToPos = m_pathPoints[ t_Id ].pos
							
							t_Dist = 50
							t_DistTo = self:GetPos()
							
						end
						
						if t_MToPos:Distance( t_DistTo ) > t_Dist then
						
							self:SetVar( "rMoveTo", t_MToPos )
							
						elseif t_MoveStep > 1 then
						
							self:SetVar( "rMoveStep", t_MoveStep - 1 )
							timer.Start( "rRefind"..self:EntIndex() )
							
						end
					
					else
						if t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 and not m_pathPoints[ t_MovePath[ t_MoveStep ] ] then

							t_MToPos = t_MovePath[ t_MoveStep ]
							t_Dist = 40
							t_DistTo = self:GetPos()
							
						else
						
							local t_Id = t_MovePath[ t_MoveStep ]

							t_MToPos = m_pathPoints[ t_Id ].pos
							
							t_Dist = 50
							t_DistTo = self:GetPos()
							
						end
						
						if t_MToPos:Distance( t_DistTo ) > t_Dist then
						
							self:SetVar( "rMoveTo", t_MToPos )
							
						elseif t_MoveStep < table.Count( t_MovePath ) then
						
							self:SetVar( "rMoveStep", t_MoveStep + 1 )
							timer.Start( "rRefind"..self:EntIndex() )

						end
						
					end					
				end
			end
		
			velocity:Add( -self:GetVelocity() / 10 )

			h_phys:AddVelocity( velocity )
			h_phys:AddAngleVelocity( -h_phys:GetAngleVelocity() / 5 )
			
			//------------------- Pathway
			
			if table.Count( point ) > 0 then
			
				local prevPos = self:GetVar( "rPrevPos" )
				self:SetVar( "rPrevPos", ground.HitPos )
				
				if point.pos:Distance( ground.HitPos ) > 50 or traceLine( ground.HitPos, point.pos, replicatorNoCollideGroup_Witch ).Hit then
				
					local info, merge = AddPathPoint( prevPos, { t_PrevInfo } )
					print( 123 )
					self:SetVar( "rPrevPointId", info )
					t_Reset = true
					
				end
				
			else
			
				local info, merge = AddPathPoint( ground.HitPos, { } )
				print( 321 )
				self:SetVar( "rPrevPointId", info )
				t_Reset = true
				
			end
			
		elseif table.Count( point ) > 0 and point.pos:Distance( ground.HitPos ) > 50 then self:SetVar( "rPrevPointId", { case = "", index = 0 } ) end

		h_Move = self:GetVar( "rMove" )
		h_MoveMode = self:GetVar( "rMoveMode" )
		
		
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

		if ground.MatType == MAT_METAL and ground.HitWorld and not m_metalPointsAsigned[ t_Pos ] then
		
			AddMetalPoint( t_Pos, ground.HitPos, ground.HitNormal, 100 )
			
		end
		
		// ------------------------- Setting path to metal
		if table.Count( m_metalPoints ) > 0 and t_Reset and t_Mode == 0 and t_PrevInfo > 0 then

			local t_Name = "rScanner"..self:EntIndex()
			
			if not timer.Exists( t_Name ) then
			
				timer.Create( t_Name, math.Rand( 6, 10 ), 1, function()
					
					if self:IsValid() then
						t_Mode = self:GetVar( "rMode" )
						t_PrevInfo = self:GetVar( "rPrevPointId" )
					
						if table.Count( m_metalPoints ) > 0 and t_Mode == 0 and t_PrevInfo > 0 then
							
							print( "Scanning" )
							
							local t_PathResult, t_MetalId
							
							if self:GetVar( "rTargetEnt" ):IsValid() then
								t_PathResult = self:GetVar( "rMovePath" )
								t_MetalId = self:GetVar( "rTargetMetalId" )
							else
								t_PathResult, t_MetalId = GetPatchWayToClosestMetal( t_PrevInfo )			
							end
							
							if table.Count( t_PathResult ) > 0 then
								print( "Scaned" )

								self:SetVar( "rMoveReverse", false )
								self:SetVar( "rMode", 1 )
								self:SetVar( "rModeStatus", 0 )
								
								self:SetVar( "rTargetMetalId", t_MetalId )
								
								self:SetVar( "rMove", true )
								self:SetVar( "rMoveStep", 1 )
								self:SetVar( "rMovePath", t_PathResult )
							end
							
						end
					end
				end )
			end
		end
	end // SERVER

	// ------------------------- Initialize dark spots
	if CLIENT then
		
		local mm = Vector( 4, 4, 4 )
		local ground, groundDist = traceHullQuick( 
			self:GetPos(), 
			-self:GetUp() * 20, 
			mm, replicatorNoCollideGroup_Witch )
			
		local t_lColor = render.GetLightColor( self:GetPos() )
		local t_DarkLevel = ( t_lColor.x + t_lColor.y + t_lColor.z ) / 3 * 100
		
		local t_HitNormal = ground.HitNormal
		t_HitNormal = Vector( math.Round( t_HitNormal.x ), math.Round( t_HitNormal.y ), math.Round( t_HitNormal.z ) )

		local t_Pos, t_StringPos = convertToGrid( self:GetPos(), 100 )
		
		mm = Vector( 20, 20, 20 )
		local trace = traceHullQuick( 
			self:GetPos() + Vector( 0, 0, 22 ), 
			Vector( ),
			mm, replicatorNoCollideGroup_Witch )
		
		if t_HitNormal == Vector( 0, 0, 1 ) and t_DarkLevel < 10 and not m_darkPoints[ t_StringPos ] and not trace.Hit then AddDarkPoint( t_StringPos, ground.HitPos ) end
		
	end // CLIENT
	
	return true
end

if SERVER then

	function ENT:OnRemove()
	
		timer.Destroy( "rWalking" .. tostring( self:EntIndex() ) )
		timer.Destroy( "rRun" .. tostring( self:EntIndex() ) )
		
	end
	
end
	
