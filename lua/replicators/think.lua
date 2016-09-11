AddCSLuaFile( )

--[[

	REPLICATORS Artificial Intelligence ( AI )
	
]]

REPLICATOR.ReplicatorThink = function( replicatorType, self  )
	
	// ======================= Varibles =================
	
	local h_Ground 			= {}
	local h_GroundDist 		= 0
	
	local h_Phys 			= self:GetPhysicsObject()
	local h_YawRot 			= self.rYawRot
	local h_Move 			= self.rMove
	local h_MoveMode 		= self.rMoveMode
	local h_Research 		= self.rResearch
	local h_Mode 			= self.rMode
	local h_ModeStatus 		= self.rModeStatus
	local h_PrevInfo 		= self.rPrevPointId

	local h_StandAnimReset 	= false
	
	if replicatorType == 1 then
	
		h_Ground, h_GroundDist = CNRTraceHullQuick( self:GetPos() + self:GetUp() * 15, -self:GetUp() * 30, Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )
			
	elseif replicatorType == 2 then
	
		h_Ground, h_GroundDist = CNRTraceHullQuick( self:GetPos() + self:GetUp() * 10, -self:GetUp() * 40, Vector( 8, 8, 8 ), g_ReplicatorNoCollideGroupWith )
			
	end

	// =================================================== Modes ===================================================
	
	if h_Research then
	
		//print( h_Mode, h_ModeStatus )
		// ==================== Redirecting when stuck ======================
		
		self.rMove 			= true
		self.rMoveMode 		= 1
		self.rMoveReverse 	= false
		
		timer.Remove( "rRefind"..self:EntIndex() )

		local m_Name = "rRotateBack" .. self:EntIndex()
		
		if not timer.Exists( m_Name ) then
			
			timer.Create( m_Name, 4, 0, function()
			
				if self:IsValid() then self:SetAngles( self:LocalToWorldAngles( Angle( 0, 90, 0 ) ) ) end
				
			end )
		end		
			
		local m_Name = "rChangingDirection"..self:EntIndex()
		
		if not timer.Exists( m_Name ) then
		
			timer.Create( m_Name, math.Rand( 2, 8 ), 0, function()
			
				if self:IsValid() then self.rYawRot = math.Rand( 3, -3 ) end
				
			end )
		end
					
		// ===================== Searching path to a metal ======================
		
		local m_MetalAmount = self.rMetalAmount

		local m_Name = "rScanner"..self:EntIndex()
		local m_TargetEnt = self.rTargetEnt

		if table.Count( g_MetalPoints ) > 0 and table.Count( h_PrevInfo ) > 0 
			and ( h_Mode == 0 or ( h_Mode == 1 and ( h_ModeStatus == 0 or h_ModeStatus == 1 ) ) )
				and not timer.Exists( m_Name ) then

			timer.Create( m_Name, math.Rand( 5, 5 ), 1, function() end )

			local m_PathResult 	= { }
			local m_MetalId		= 0
			
			if m_TargetEnt:IsValid() then

				m_PathResult = self.rMovePath
				m_MetalId = self.rTargetMetalId
				
			else m_PathResult, m_MetalId = GetPatchWayToClosestMetal( h_PrevInfo ) end

			if table.Count( m_PathResult ) > 0 then
			
				if not g_MetalPoints[ m_MetalId ].m_Ent then g_MetalPoints[ m_MetalId ].used = true end
				
				timer.Remove( "rRotateBack"..self:EntIndex() )
				timer.Remove( "rScannerDark"..self:EntIndex() )
				timer.Remove( "rScanner"..self:EntIndex() )

				self.rResearch = false
				self.rMoveStep = 1
				
				self.rMode = 1
				self.rModeStatus = 0
				self.rTargetMetalId = m_MetalId
				self.rMovePath = m_PathResult
				
			end
		end

		// ===================== Searching path to a dark point ======================
		
		local m_Name = "rScannerDark"..self:EntIndex()
		
		if ( h_Mode == 1 and h_ModeStatus == 2 or h_Mode == 4 ) and table.Count( g_DarkPoints ) > 0 and not timer.Exists( m_Name ) then
			
			timer.Create( m_Name, math.Rand( 5, 5 ), 1, function()

				if self:IsValid() then

					self.rResearch = false
					self.rMode = 1
					self.rModeStatus = 2

					timer.Remove( "rRotateBack"..self:EntIndex() )
					timer.Remove( "rScanner"..self:EntIndex() )
					timer.Remove( "rScannerDark"..self:EntIndex() )
					
				end
			end )				
		end
		
		// ===================== Searching path to an enemy ======================
		
		if table.Count( g_Attackers ) > 0 and not timer.Exists( m_Name ) then
			
			local m_PathResult, t_TargetEnt, t_TargetId
			
			local m_TargetEnt = self.rTargetEnt
			if m_TargetEnt:IsValid() then

				m_PathResult = self.rMovePath
				t_TargetId = self.rTargetId
				
			else
			
				local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )
				m_PathResult, t_TargetEnt, t_TargetId = GetPatchWayToClosestEnt( { case = m_Case, index = m_Index }, g_Attackers )

			end

			if table.Count( m_PathResult ) > 0 then
			
				//if not g_Attackers[ t_TargetId ].m_Ent then g_Attackers[ t_TargetId ].used = true end
				
				timer.Remove( "rRotateBack" .. self:EntIndex() )
				timer.Remove( "rScanner" .. self:EntIndex() )
				timer.Remove( "rScannerDark"..self:EntIndex() )

				self.rResearch 	= false
				self.rMoveStep 	= 1
				
				self.rMode 			= 2
				self.rModeStatus 	= 0
				self.rTargetId 		= t_TargetId
				self.rMovePath 		= m_PathResult
				
			end
		end
		
		local t_MoveTo 	= self:GetPos() + self:GetForward() * 40 + self:GetRight() * h_YawRot
		self.rMoveTo 	= t_MoveTo
		
	else
	
		// ======================================= Getting metal ===============================
		if h_Mode == 1 then
			
			local t_TargetMetalId = self.rTargetMetalId
			
			if h_ModeStatus == 0 then
			
				local mPointPos 	= Vector( )
				local mPointInfo 	= g_MetalPoints[ t_TargetMetalId ]
				
				if mPointInfo then

					if mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() then mPointPos = mPointInfo.m_Ent:GetPos()
					elseif mPointInfo.pos then mPointPos = mPointInfo.pos else self.rResearch = true end

				end
				
				if h_Ground.HitPos:Distance( mPointPos ) < 50 then self.rMoveMode = 0
				else self.rMoveMode = 1 end
								
				if h_Ground.MatType == MAT_METAL and ( ( h_Ground.HitWorld and h_Ground.HitPos:Distance( mPointPos ) < 20 )
					or ( mPointInfo and mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() and h_Ground.Entity == mPointInfo.m_Ent ) ) then

					timer.Remove( "rRefind" .. self:EntIndex() )
					timer.Remove( "rWalking" .. self:EntIndex() )
					timer.Remove( "rRun" .. self:EntIndex() )
					h_StandAnimReset = true
					
					self.rMove 			= false
					self.rMoveStep 		= 0
					self.rModeStatus	= 1
					
					if mPointInfo then
					
						if mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() then
						
							constraint.Weld( mPointInfo.m_Ent, self, 0, 0, 0, collision == true, false )
							self.rDisableMovining = true
							
						end
					end
				end
				
			// ========================== Eating metal ======================
			elseif h_ModeStatus == 1 then
				
				local m_Name = "rEating"..self:EntIndex()
				
				if not timer.Exists( m_Name ) then
				
					timer.Create( m_Name, CNRPlaySequence( self, "eating" ), 0, function()
					
						if self:IsValid() then
						
							local t_TargetMetalId = self.rTargetMetalId
							local mPointInfo = g_MetalPoints[ t_TargetMetalId ]

							local t_m_TargetMetalAmount = 0
							if mPointInfo then t_m_TargetMetalAmount = mPointInfo.amount end
							
							local m_MetalAmount = self.rMetalAmount
							local h_ModeStatus = self.rModeStatus
							local m_Amount = g_replicator_collection_speed

							if t_m_TargetMetalAmount < g_replicator_collection_speed then m_Amount = t_m_TargetMetalAmount end

							if not ( ( m_MetalAmount + m_Amount ) < g_segments_to_assemble_replicator
								or table.Count( g_QueenCount ) == 0 and m_MetalAmount + m_Amount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator ) ) then

								timer.Remove( "rEating"..self:EntIndex() )
								
								self.rModeStatus 		= 2
								self.rMove 				= true
								self.rMoveMode 			= 1
								self.rDisableMovining 	= false

								if mPointInfo and mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() then constraint.RemoveAll( self ) end
								
							end
							
							if t_m_TargetMetalAmount == 0 then
								
								timer.Remove( "rEating"..self:EntIndex() )
								
								self.rDisableMovining 	= false
								self.rResearch			= true
								self.rModeStatus 		= 0

								if mPointInfo and ( mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() ) then
									MsgC( Color( 0, 255, 255 ), "REMOVE METAL ", mPointInfo.m_Ent, "\n" )
								
									self.rTargetEnt = Entity( 0 )
									
									if mPointInfo.m_Ent and mPointInfo.m_Ent:IsValid() then
									
										constraint.RemoveAll( self )
										CNRDissolveEntity( mPointInfo.m_Ent )
										g_MetalPointsAsigned[ "_"..mPointInfo.m_Ent:EntIndex() ] = nil
										
									end
									

									if g_MetalPoints[ t_TargetMetalId ] then g_MetalPoints[ t_TargetMetalId ] = nil end
									
								end
							end

							if mPointInfo and g_MetalPoints[ t_TargetMetalId ] then
							
								if mPointInfo.m_Ent then g_MetalPoints[ t_TargetMetalId ].amount = t_m_TargetMetalAmount - m_Amount
								elseif mPointInfo.pos then UpdateMetalPoint( t_TargetMetalId, t_m_TargetMetalAmount - m_Amount ) end
								
							end
							
							m_MetalAmount = m_MetalAmount + m_Amount
							self.rMetalAmount = m_MetalAmount
							
						end
					end )
				end
				
			// ============================== Transporting metal ======================
			elseif h_ModeStatus == 2 then

				local m_QueenFounded = false
								
				if table.Count( g_QueenCount ) > 0 then
				
					local m_PathResult	= { }
					local m_QueenEnt 	= Entity( 0 )
					
					if self.rTargetGueen:IsValid() then
					
						m_PathResult 	= self.rMovePath
						m_QueenEnt 		= self.rTargetGueen
						
						self.rMoveReverse = false
					else
						m_PathResult = { self:GetPos() }

						local t_Path = {}
						local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )

						t_PathGet, m_QueenEnt = GetPatchWayToClosestEnt( { case = m_Case, index = m_Index }, g_QueenCount )
						
						table.Add( m_PathResult, t_PathGet )
					end
					
					if table.Count( m_PathResult ) > 0 and m_QueenEnt:IsValid() then
					
						self.rMode = 1
						self.rModeStatus = 3
						
						self.rTargetGueen = m_QueenEnt
						
						self.rMove = true
						self.rMoveMode = 1
						
						self.rMoveStep = 1
						self.rMovePath = m_PathResult
						
						m_QueenFounded = true
						
					end
					
				elseif not m_QueenFounded then
				
					local m_MetalId = self.rTargetMetalId

					if g_MetalPoints[ m_MetalId ] and g_MetalPoints[ m_MetalId ].used then g_MetalPoints[ m_MetalId ].used = false end
					
					if table.Count( g_DarkPoints ) > 0 then
						
						local m_MetalId = self.rTargetMetalId

						if g_MetalPoints[ m_MetalId ].used then g_MetalPoints[ m_MetalId ].used = false end
						
						local m_Case, m_Index = FindClosestPoint( self:GetPos(), 1 )
						local m_PathResult, m_DarkId = GetPatchWayToClosestId( { case = m_Case, index = m_Index }, g_DarkPoints )
						
						if table.Count( m_PathResult ) > 0 then
						
							g_DarkPoints[ m_DarkId ].used = true
							
							self.rMode = 4
							self.rModeStatus = 1

							self.rMoveReverse = false
							
							self.rTargetDarkId = m_DarkId
							
							self.rMove= true
							self.rMoveStep = 1
							self.rMovePath = m_PathResult
							
						else self.rResearch = true end
						
					else self.rResearch = true end
				else MsgC( Color( 255, 0, 0 ), "ERROR queen doesn't found ( transport )\n" ) end
				
			elseif h_ModeStatus == 3 then
			
				// ======================= Wait until Replicator reaches queen ======================
				local m_QueenEnt = self.rTargetGueen
				
				if m_QueenEnt:GetPos():Distance( self:GetPos() ) < 40 then
				
					self.rModeStatus = 4
					self.rMove = false
					
				end
				
			elseif h_ModeStatus == 4 then

				// ======================= Giving metal ==========================
				local m_Name = "rGiving"..self:EntIndex()
				
				if not timer.Exists( m_Name ) then
				
					timer.Create( m_Name, CNRPlaySequence( self, "stand" ), 0, function()
					
						if self:IsValid() then
						
							self:NextThink( CurTime() )
						
							local m_QueenEnt = self.rTargetGueen

							local m_MetalAmount = math.min( g_replicator_giving_speed, self.rMetalAmount )
							
							if m_QueenEnt and m_QueenEnt:IsValid() then
							
								m_QueenEnt.rMetalAmount = m_QueenEnt.rMetalAmount + m_MetalAmount
								self.rMetalAmount = self.rMetalAmount - m_MetalAmount
								
							else MsgC( Color( 255, 0, 0 ), "ERROR queen doesn't found ( giving )\n" ) self.rModeStatus = 2 end
							
							if self.rMetalAmount == 0 then
							
								timer.Remove( "rGiving"..self:EntIndex() )

								self.rMoveReverse = true
								
								self.rMove = true
								self.rMode = 1
								self.rModeStatus = 0
							end
						end
					end )
				end
			end
			
		// ===================== Attack mode ======================
		elseif h_Mode == 2 then
		
			if h_ModeStatus == 0 then
			
				local m_Target = g_Attackers[ self.rTargetId ]
				
				if m_Target and m_Target:IsValid() then
				
					local m_Filter = { }
					table.Add( m_Filter, g_ReplicatorNoCollideGroupWith )
					table.Add( m_Filter, { "player" } )
					
					local m_Trace, m_TraceDist = CNRTraceLine( self:GetPos(), m_Target:GetPos(), m_Filter )
					
					if not m_Trace.Hit then
					
						self.rMoveTo = m_Target:GetPos()
						timer.Start( "rRefind"..self:EntIndex() )
						
						if m_Target:GetPos():Distance( self:GetPos() ) < 100 then
						
							if h_Ground.Hit then
							
								if h_Ground.Entity == m_Target then
								
									h_Phys:SetAngles( ( m_Target:GetPos() - h_Phys:GetPos() ):Angle() + Angle( -90, 0, 0 ) )
									h_Phys:SetPos( h_Ground.HitPos )

									self.rModeStatus 	= 1
									self.rMove 			= false
									h_StandAnimReset 	= true
									
									h_Phys:EnableCollisions( false )
									timer.Remove( "rRefind"..self:EntIndex() )

									if m_Target:IsPlayer() or m_Target:IsNPC() then self:SetParent( m_Target, 1 )
									else self:SetParent( m_Target, -1 ) end
									
								else
								
									self.rDisableMovining = true
									h_Phys:SetVelocity( Vector( 0, 0, 200 ) + ( m_Target:GetPos() - h_Phys:GetPos() ) * 2 )
									
								end
								
							else
							
								local JUANG = self:WorldToLocalAngles( ( m_Target:GetPos() - h_Phys:GetPos() ):Angle() ).y
								local zeroAng = self:WorldToLocalAngles( Angle( -50, JUANG + self:GetAngles().yaw, 0 ) )

								h_Phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, zeroAng.y ) * 6 - h_Phys:GetAngleVelocity() )

							end
							
						else self.rDisableMovining = false end
					end
					
				end
				
			elseif h_ModeStatus == 1 then
			
				local name = "rDamagining"..self:EntIndex()
				
				local function UnParm_Ent( self, h_Phys, m_Target, m_TargetCase )
				
					constraint.RemoveAll( self )
					
					self.rMode 				= 0
					self.rMoveStatus 		= 0
					self.rResearch 			= true
					self.rMove 				= true
					self.rTargetId 			= ""
					self.rDisableMovining 	= false 
					
					timer.Remove( name )
					
					self:SetParent( NULL )
					h_Phys:EnableCollisions( true )
					
					if m_Target then g_Attackers[ m_TargetCase ] = nil end
					
				end

				if not timer.Exists( name ) then
				
					h_StandAnimReset = true

					timer.Create( name, CNRPlaySequence( self, "eating" ), 0, function()
						
						local m_Target = g_Attackers[ self.rTargetId ]
						m_Target:TakeDamage( 25, self, self )
						h_Phys = self:GetPhysicsObject()
						
						if m_Target then
						
							if m_Target:Health() <= 0 then UnParm_Ent( self, h_Phys, m_Target, self.rTargetId ) end
							
						else UnParm_Ent( self, h_Phys ) end
						
					end )
				end
				
				if self.rTargetId then
				
					local m_Target = g_Attackers[ self.rTargetId ]
					
					if m_Target then
					
						if m_Target:Health() <= 0 then UnParm_Ent( self, h_Phys, m_Target, self.rTargetId ) end
						
					else UnParm_Ent( self, h_Phys ) end
					
				end
				
			elseif h_ModeStatus == 2 then
			end
			
		elseif h_Mode == 3 then
			
		// ===================== Transporting mode ======================
		elseif h_Mode == 4 then
		
			if h_ModeStatus == 1 then
			
				local m_DarkId = self.rTargetDarkId
			
				if h_Ground.HitPos:Distance( g_DarkPoints[ m_DarkId ].pos ) < 50 then self.rMoveMode = 0
				else self.rMoveMode = 1 end

				if g_DarkPoints[ m_DarkId ].pos:Distance( h_Ground.HitPos ) < 10 then
					
					timer.Remove( "rWalking" .. self:EntIndex() )
					timer.Remove( "rRun" .. self:EntIndex() )
					timer.Remove( "rRefind"..self:EntIndex() )
					
					h_StandAnimReset 	= true
					
					self.rMove 			= false
					self.rMoveStep		= 0
					self.rModeStatus	= 2
					
					timer.Simple( CNRPlaySequence( self, "crafting_start" ), function()
					
						// IF QUEEN
						if replicatorType == 2 then
						
							table.Add( g_QueenCount, { self } )
							table.RemoveByValue( g_WorkersCount, self )
							
							net.Start( "rDrawStorageEffect" ) net.WriteEntity( self ) net.Broadcast()
							
						end
						
						timer.Create( "rCrafting" .. self:EntIndex(), CNRPlaySequence( self, "crafting" ) / 10, 0, function()
						
							if self:IsValid() and false then // BLOCKED
							
								if self.rMetalAmount >= 1 then
								
									local m_Ent = m_Ents.Create( "replicator_segmm_Ent" )
									self:EmitSound( "physics/metal/weapon_impact_soft" .. math.random( 1, 3 ) .. ".wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
									
									if ( !IsValid( m_Ent ) ) then return end
									m_Ent:SetPos( self:GetPos() + self:GetForward() * 6 - self:GetUp() * 3 )
									m_Ent:SetAngles( AngleRand() )
									m_Ent:SetOwner( self:GetOwner() )
									m_Ent:Spawn()
									
									if replicatorType == 1 then
									
										m_Ent.rCraftingQueen = true
										
									end
									
									local h_Phys = m_Ent:GetPhysicsObject()
									h_Phys:Wake()
									h_Phys:SetVelocity( VectorRand() * 40 + self:GetForward() * 60 )	
									
									self.rMetalAmount = self.rMetalAmount - 1
									
								elseif replicatorType != 2 then
								
									// ====================== Self Destruction ======================
									
									table.RemoveByValue( g_WorkersCount, self )

									g_DarkPoints[ m_DarkId ].used = false
									
									for i = 1, g_segments_to_assemble_replicator do
	
										local m_Ent = m_Ents.Create( "replicator_segmm_Ent" )
										
										if not IsValid( m_Ent ) then return end
										m_Ent:SetPos( self:GetPos() + VectorRand() * 3 )
										m_Ent:SetOwner( self:GetOwner() )
										m_Ent:Spawn()
										
										m_Ent.rCraftingQueen = true
										
										local h_Phys = m_Ent:GetPhysicsObject()
										h_Phys:Wake()
										h_Phys:SetVelocity( VectorRand() * 100 )
										
									end
									
									self:Remove()
									
								end
							end
						end )
					end )
				end

			elseif h_ModeStatus == 2 then
			end
		end
	end
	// ========================================= Creating path web ===================================

	REPLICATOR.CreatingPath( self, h_Ground )
	
	// ========================================= Wall climbing / walking system ===================================
	
	REPLICATOR.ReplicatorWalking( replicatorType, self, h_Ground, h_GroundDist, h_Move, h_MoveMode )
	
	// =================================== Breaks when bullseye die =============================================
	
	if not h_Phys:IsGravityEnabled() and h_Phys:IsMotionEnabled() then h_Phys:SetVelocity( self:GetForward() * h_Phys:GetMass() / 2 ) end
	
	if self.rReplicatorNPCTarget and ( not self.rReplicatorNPCTarget:IsValid() or self.rReplicatorNPCTarget:IsValid() and self.rReplicatorNPCTarget:Health() <= 0 ) then
	
		REPLICATOR.ReplicatorBreak( replicatorType, self, 0, Vector() )
		
	end
	
	// ==================================================== Animations ===============================================
	
	REPLICATOR.ReplicatorWalkingAnimation( replicatorType, self, h_Move, h_MoveMode, h_StandAnimReset )
	
	// ==================================================== Scanner ===============================================
	REPLICATOR.ReplicatorScanningResources( self )
	
	local m_Pos, m_PosString = convertToGrid( h_Ground.HitPos, 30 )

	if h_Ground.MatType == MAT_METAL then
		
		if h_Ground.HitWorld then 
			
			self.rTargetMetalId = m_PosString
			if not g_MetalPointsAsigned[ m_PosString ] then AddMetalPoint( m_PosString, h_Ground.HitPos, h_Ground.HitNormal, 100 ) end
		
		elseif h_Ground.Entity:IsValid() then

			self.rTargetMetalId = "_"..h_Ground.Entity:EntIndex()
			if not g_MetalPointsAsigned[ "_"..h_Ground.Entity:EntIndex() ] then AddMetalEntity( h_Ground.Entity ) end
			
		end
	end
end