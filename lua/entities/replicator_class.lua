AddCSLuaFile()

//
// ---------------------- Replicator functional
//
if SERVER then

	function ReplicatorInitialize( self )
		
		local phys = self:GetPhysicsObject()

		self:CollisionRulesChanged()
		self:SetCustomCollisionCheck( true ) 	
		
		self.rMove = false
		self.rMoveMode = 1
		
		self.rMoveTo= self:GetPos()
		self.rMoveStep = 0
		
		self.rTargetEnt = Entity( 0 )

		self.rTargetMetalId = "" 
		self.rTargetDarkId = ""
		
		self.rMetalAmount = 0
		
		// 1 Work
		// 2 Attack
		// 3 Defence
		// 4 Transform
		
		self.rMode = 0
		self.rResearch = true

		// Research 0 - Stay 1 - Walk
		// Work 0 - Moving 1 - Eating
		self.rModeStatus = 0
		self.rYawRot = 0
		
		phys:SetMaterial( "gmod_ice" )

		table.Add( m_workersCount, self )
		
		if  IsValid( phys ) and self.assemble then 
			
			phys:EnableGravity( true )
			//phys:EnableMotion( false ) 
			
			self.rMode = -1
			self.rResearch = false
			
			timer.Simple(PlaySequence( self, "assembling" ), function()

				self.rMode = 0
				self.rResearch = true
			
				if self:IsValid() then
					
					PlaySequence( self, "stand" )
					
					if IsValid( phys ) then phys:Wake() end
				end
			end )
		else PlaySequence( self, "stand" ) end

		//-------- Initialize point
		
		self.rPrevPointId = { case = "", index = 0 }
		self.rPrevPos = self:GetPos()
		
	end
	
	//
	// ----------------- Moving replicator to a point on a path
	//
	
	function ReplicatorMovingOnPath( self, h_phys, ground )
		
		local t_MoveStep = self.rMoveStep

		if t_MoveStep > 0 then
			
			local t_MovePath = self.rMovePath

			if table.Count( t_MovePath ) > 0 then
			
				local t_MoveReverse = self.rMoveReverse
			
				local t_MToPos = Vector()
				local t_Dist
				local t_DistTo
				
				local t_Name = "rRefind"..self:EntIndex()
				
				if not timer.Exists( t_Name ) then
				
					timer.Create( t_Name, 10, 1, function()
						
						if self:IsValid() then
						
							local t_TargetMetalId = self.rTargetMetalId
							local t_TargetDarkId = self.rTargetDarkId
							
							if t_TargetMetalId and t_TargetMetalId != "" then m_metalPoints[ t_TargetMetalId ].used = false end
							if t_TargetDarkId and t_TargetDarkId != "" then m_darkPoints[ t_TargetDarkId ].used = false end

							self.rResearch = true
							
							self.rMove = true
							self.rMoveMode = 1
							self.rMoveReverse = false
							self.rTargetEnt = Entity( 0 )
							
						end
					end )
				end
				
				local t_Case = t_MovePath[ t_MoveStep ].case

				if t_MoveReverse then
					
					if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ t_Case ] then
						
						t_MToPos = t_MovePath[ t_MoveStep ]
						
						t_Dist = 40
						t_DistTo = self:GetPos()
						
					else
					
						local t_Index = t_MovePath[ t_MoveStep ].index

						t_MToPos = m_pathPoints[ t_Case ][ t_Index ].pos
						
						t_Dist = 30
						t_DistTo = ground.HitPos
						
					end
					
					if t_MToPos:Distance( t_DistTo ) > t_Dist then
					
						self.rMoveTo = t_MToPos
						
					elseif t_MoveStep > 1 and not traceLine( t_MToPos, t_DistTo, replicatorNoCollideGroup_Witch ).Hit then
					
						self.rMoveStep = t_MoveStep - 1
						timer.Start( "rRefind"..self:EntIndex() )
						
					end
				
				else

					if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ t_Case ] then

						t_MToPos = t_MovePath[ t_MoveStep ]

						t_Dist = 40
						t_DistTo = self:GetPos()
						
					else
					
						local t_Index = t_MovePath[ t_MoveStep ].index

						t_MToPos = m_pathPoints[ t_Case ][ t_Index ].pos
						t_Dist = 30
						t_DistTo = ground.HitPos
						
					end
					
					if t_MToPos:Distance( t_DistTo ) > t_Dist then
						self.rMoveTo = t_MToPos
						
					elseif t_MoveStep < table.Count( t_MovePath ) and not traceLine( t_MToPos, t_DistTo, replicatorNoCollideGroup_Witch ).Hit then
					
						self.rMoveStep = t_MoveStep + 1
						timer.Start( "rRefind"..self:EntIndex() )

					end
					
				end					
			end
		end
	end
	
	//
	// ----------------- Modes of Replicator
	//
	function ReplicatorThink( replicatorType, self  )
		
		// -------------------------------- Varibles
		
		local ground = {}
		local groundDist = 0
		
		if replicatorType == 1 then
		
			ground, groundDist = traceHullQuick( 
				self:GetPos(), -self:GetUp() * 20,
				Vector( 4, 4, 4 ), replicatorNoCollideGroup_Witch )
				
		elseif replicatorType == 2 then
		
			ground, groundDist = traceHullQuick( 
				self:GetPos(), -self:GetUp() * 30,
				Vector( 8, 8, 8 ), replicatorNoCollideGroup_Witch )		
		
		end

		local h_phys = self:GetPhysicsObject()

		local h_YawRot = self.rYawRot
		local h_Move = self.rMove
		local h_MoveMode = self.rMoveMode

		local h_Research = self.rResearch
		local h_Mode = self.rMode
		local h_ModeStatus = self.rModeStatus
		local h_PrevInfo = self.rPrevPointId

		local t_StandAnimReset = false
		local t_Offset = Vector()
		local t_AngleOffset = Angle()

		
		//print( h_Mode, h_ModeStatus, h_Research )
		//
		// ----------------------------------- Modes
		//

		// -------------------------- Research mode
		if h_Research then
			//print( h_Mode, h_ModeStatus )
			
			self.rMove = true
			self.rMoveMode = 1
			self.rMoveReverse = false
			
			timer.Remove( "rRefind"..self:EntIndex() )
		
			local t_Name = "rChangingDirection"..self:EntIndex()
			
			if not timer.Exists( t_Name ) then
			
				timer.Create( t_Name, math.Rand( 2, 8 ), 0, function()
				
					//if self:IsValid() then self.rYawRot = math.Rand( 3, -3 ) end
					
				end )
				
			end
			
			// ------------------------- Setting path to metal
			
			local t_rMetalAmount = self.rMetalAmount

			local t_Name = "rScanner"..self:EntIndex()
			local targetEnt = self.rTargetEnt
			
			//print( h_Mode, h_ModeStatus )
			//print( timer.Exists( t_Name ) )
			
			if table.Count( m_metalPoints ) > 0 and table.Count( h_PrevInfo ) > 0 
				and ( targetEnt:IsValid() and t_rMetalAmount < g_segments_to_assemble_replicator 
					or not targetEnt:IsValid() and t_rMetalAmount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator ) ) 
						and not timer.Exists( t_Name ) then
						
				print( "START SCANNING")
				//PrintTable( m_metalPoints )
				
				timer.Create( t_Name, math.Rand( 5, 5 ), 1, function()
					
					if self:IsValid() then
					
						local targetEnt = self.rTargetEnt
						local h_PrevInfo = self.rPrevPointId
					
						if table.Count( m_metalPoints ) > 0 and table.Count( h_PrevInfo ) > 0 then

							print( "scanned" )
							
							local t_PathResult, t_MetalId
							
							if targetEnt:IsValid() then

								t_PathResult = self.rMovePath
								t_MetalId = self.rTargetMetalId
								
							else t_PathResult, t_MetalId = GetPatchWayToClosestMetal( h_PrevInfo ) end

							if table.Count( t_PathResult ) > 0 then
							
								if not m_metalPoints[ t_MetalId ].ent then m_metalPoints[ t_MetalId ].used = true end
								print( "Scanned" )
								
								timer.Remove( "rRotateBack" .. self:EntIndex() )
								timer.Remove( "rScanner" .. self:EntIndex() )

								self.rResearch = false
								self.rMoveStep = 1
								
								self.rMode = 1
								self.rModeStatus = 0
								self.rTargetMetalId = t_MetalId
								self.rMovePath = t_PathResult
								
							end
						end
					end
				end )
				
				
			end
			
			if h_Mode == 1 and h_ModeStatus == 2 and table.Count( m_darkPoints ) > 0 and not timer.Exists( t_Name ) then
			
				print( "SCANNING DARK" )
				timer.Create( t_Name, math.Rand( 5, 5 ), 1, function()
					print( "Scanned dark" )
					
					if self:IsValid() then

						self.rResearch = false
						timer.Remove( "rRotateBack" .. self:EntIndex() )
						timer.Remove( "rScanner" .. self:EntIndex() )
						
					end
				end )				
			end
			
			// ------------Redirecting when stuck
			local t_Name = "rRotateBack" .. self:EntIndex()
			
			if not timer.Exists( t_Name ) then
				
				timer.Create( t_Name, 4, 0, function()
				
					if self:IsValid() then
					
						//h_phys = self:GetPhysicsObject()
						//h_phys:AddVelocity( -self:GetForward() * 100 )
						self:SetAngles( self:LocalToWorldAngles( Angle( 0, 90, 0 ) ) )
						
					end
				end )
			end
			
			local t_MoveTo = self:GetPos() + self:GetForward() * 40 + self:GetRight() * h_YawRot
			
		
			self.rMoveTo = t_MoveTo
			
		else
		
			//
			// ----------------------------------- Getting metal
			//
			if h_Mode == 1 then
				
				local t_TargetMetalId = self.rTargetMetalId
				
				if h_ModeStatus == 0 then
				
					local mPointPos = Vector( )
					local mPointInfo = m_metalPoints[ t_TargetMetalId ]
					
					if mPointInfo then

						if mPointInfo.ent and mPointInfo.ent:IsValid() then mPointPos = mPointInfo.ent:GetPos()
						elseif mPointInfo.pos then mPointPos = mPointInfo.pos else self.rResearch = true end

					end
					
					if ground.HitPos:Distance( mPointPos ) < 50 then self.rMoveMode = 0
					else self.rMoveMode = 1 end

					if ground.MatType == MAT_METAL then
					
						if ground.HitWorld and ground.HitPos:Distance( mPointPos ) < 10
							or mPointInfo and mPointInfo.ent and mPointInfo.ent:IsValid() and ground.Entity == mPointInfo.ent then

							timer.Remove( "rRefind" .. self:EntIndex() )
							timer.Remove( "rWalking" .. self:EntIndex() )
							timer.Remove( "rRun" .. self:EntIndex() )
							t_StandAnimReset = true
							
							self.rMove = false
							self.rMoveStep = 0
							self.rModeStatus = 1
							
							if mPointInfo then
							
								if mPointInfo.ent and mPointInfo.ent:IsValid() then constraint.Weld( mPointInfo.ent, self, 0, 0, 0, collision == true, false ) end
								//else h_phys:EnableMotion( false ) end
								
							end
						end
					end
					
				// ----------------------------------- Eating metal
				elseif h_ModeStatus == 1 then
					
					//self:NextThink( CurTime() + 100 )
					local t_Name = "rEating"..self:EntIndex()
					
					if not timer.Exists( t_Name ) then
					
						timer.Create( t_Name, PlaySequence( self, "eating" ), 0, function()
						
							if self:IsValid() then
							
								local t_TargetMetalId = self.rTargetMetalId
								local mPointInfo = m_metalPoints[ t_TargetMetalId ]

								local t_targetMetalAmount = 0
								if mPointInfo then t_targetMetalAmount = mPointInfo.amount end
								
								local t_rMetalAmount = self.rMetalAmount

								local h_ModeStatus = self.rModeStatus

								//self:NextThink( CurTime() )
								
								local t_Amount = g_replicator_collection_speed

								if t_targetMetalAmount < g_replicator_collection_speed then t_Amount = t_targetMetalAmount end

								// --------- Next Step
								if not ( t_rMetalAmount + t_Amount < g_segments_to_assemble_replicator
									or table.Count( m_queenCount ) == 0 and t_rMetalAmount + t_Amount < ( g_segments_to_assemble_queen - g_segments_to_assemble_replicator )) then

									timer.Remove( "rEating"..self:EntIndex() )
									self.rModeStatus = 2
									self.rMove = true
									self.rMoveMode = 1

									//h_phys:EnableMotion( true )
									if mPointInfo and mPointInfo.ent and mPointInfo.ent:IsValid() then constraint.RemoveAll( self ) end
								end
								
								if t_targetMetalAmount == 0 then
									print( "AMOUNT 0" )
									
									timer.Remove( "rEating"..self:EntIndex() )
									
									self.rResearch = true
									self.rModeStatus = 0
									//h_phys:EnableMotion( true )

									if mPointInfo and ( mPointInfo.ent and mPointInfo.ent:IsValid() ) then
										print( "REMOVE METAL", mPointInfo.ent )
									
										self.rTargetEnt = Entity( 0 )
										
										if mPointInfo.ent and mPointInfo.ent:IsValid() then
										
											constraint.RemoveAll( self )
											mPointInfo.ent:Remove()
											
										end
										

										if m_metalPoints[ t_TargetMetalId ] then table.RemoveByValue( m_metalPoints, t_TargetMetalId ) end
										
									end
								end

								if mPointInfo then
								
									if mPointInfo.ent then m_metalPoints[ t_TargetMetalId ].amount = t_targetMetalAmount - t_Amount
									else UpdateMetalPoint( t_TargetMetalId, t_targetMetalAmount - t_Amount ) end
									
								end
								
								t_rMetalAmount = t_rMetalAmount + t_Amount
								
								print( t_Amount, t_targetMetalAmount, t_rMetalAmount )
								self.rMetalAmount = t_rMetalAmount
								
							end
						end )
					end
					
				// ----------------------------------- Transporting metal
				elseif h_ModeStatus == 2 then

					local t_QueenFounded = false
					
					print( table.Count( m_queenCount ), "<" , math.ceil( table.Count( m_workersCount ) / g_amount_of_worker_for_one_queen ) )
					//and table.Count( m_queenCount ) < math.ceil( table.Count( m_workersCount ) / g_amount_of_worker_for_one_queen )
					
					if table.Count( m_queenCount ) > 0 then
					
						local t_PathResult
						local t_QueenEnt = Entity( 0 )
						
						if self.rTargetEnt:IsValid() then
						
							t_PathResult = self.rMovePath
							t_QueenEnt = self.rTargetEnt
							
							self.rMoveReverse = false
						else
							t_PathResult = { self:GetPos() }

							local t_PathGet
							t_PathGet, t_QueenEnt = GetPatchWayToClosestEnt( h_PrevInfo, m_queenCount )
							
							table.Add( t_PathResult, t_PathGet )
						end
						
						if table.Count( t_PathResult ) > 0 and t_QueenEnt:IsValid() then
						
							self.rMode = 1
							self.rModeStatus = 3
							
							self.rTargetEnt = t_QueenEnt
							
							self.rMove = true
							self.rMoveMode = 1
							
							self.rMoveStep = 1
							self.rMovePath = t_PathResult
							
							t_QueenFounded = true
							
						end
						
					end
					
					if not t_QueenFounded then
					
						if table.Count( m_darkPoints ) > 0 then
							
							local t_MetalId = self.rTargetMetalId

							if m_metalPoints[ t_MetalId ].used then m_metalPoints[ t_MetalId ].used = false end
							
							local t_PathResult, t_DarkId = GetPatchWayToClosestId( h_PrevInfo )
							
							if table.Count( t_PathResult ) > 0 then
							
								//PrintTable( t_PathResult )
								
								m_darkPoints[ t_DarkId ].used = true
								
								self.rMode = 4
								self.rModeStatus = 1

								self.rMoveReverse = false
								
								self.rTargetDarkId = t_DarkId
								
								self.rMove= true
								self.rMoveStep = 1
								self.rMovePath = t_PathResult
								
							else self.rResearch = true end
							
						else self.rResearch = true end
					end
					
				elseif h_ModeStatus == 3 then
				
					local t_QueenEnt = self.rTargetEnt
					
					if t_QueenEnt:GetPos():Distance( self:GetPos() ) < 40 then
					
						self.rModeStatus = 4
						self.rMove = false
						//h_phys:EnableMotion( false )
						
					end
					
				elseif h_ModeStatus == 4 then

					
					local t_Name = "rGiving"..self:EntIndex()
					
					if not timer.Exists( t_Name ) then
					
						timer.Create( t_Name, PlaySequence( self, "stand" ), 0, function()
						
							if self:IsValid() then
							
								self:NextThink( CurTime() )
							
								local t_QueenEnt = self.rTargetEnt

								local t_rMetalAmount = math.min( g_replicator_giving_speed, self.rMetalAmount )
								
								if t_QueenEnt and t_QueenEnt:IsValid() then
								
									print( "give metal", t_rMetalAmount )
									t_QueenEnt.rMetalAmount = t_QueenEnt.rMetalAmount + t_rMetalAmount
									self.rMetalAmount = self.rMetalAmount - t_rMetalAmount
									
								else
									print( "ERROR queen doesn't found")
								end
								
								if self.rMetalAmount == 0 then
								
									timer.Remove( "rGiving"..self:EntIndex() )
									
									self.rMoveReverse = true
									
									//h_phys:EnableMotion( true )
									self.rMove = true
									self.rMode = 1
									self.rModeStatus = 0
									
								end
							end
						end )
					end
				end
				
			elseif h_Mode == 2 then
			elseif h_Mode == 3 then
			elseif h_Mode == 4 then
			
				if h_ModeStatus == 1 then
				
					local t_DarkId = self.rTargetDarkId
				
					if ground.HitPos:Distance( m_darkPoints[ t_DarkId ].pos ) < 50 then self.rMoveMode = 0
					else self.rMoveMode = 1 end

					if m_darkPoints[ t_DarkId ].pos:Distance( ground.HitPos ) < 10 then
						
						timer.Remove( "rWalking" .. self:EntIndex() )
						timer.Remove( "rRun" .. self:EntIndex() )
						timer.Remove( "rRefind"..self:EntIndex() )
						t_StandAnimReset = true
						
						self.rMove = false
						self.rMoveStep = 0
						self.rModeStatus = 2
						

						timer.Simple( PlaySequence( self, "crafting_start" ), function()
						
							// IF QUEEN
							if replicatorType == 2 then
							
								table.Add( m_queenCount, { self } )
								table.RemoveByValue( m_workersCount, self )
								
								net.Start( "rDrawStorageEffect" ) net.Broadcast()
								
							end
							
							timer.Create( "rCrafting" .. self:EntIndex(), PlaySequence( self, "crafting" ) / 10, 0, function()
							
								if self:IsValid() then
								
									if self.rMetalAmount >= 1 then
									
										local ent = ents.Create( "replicator_segment" )
										self:EmitSound( "physics/metal/weapon_impact_soft" .. math.random( 1, 3 ) .. ".wav", 60, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
										
										if ( !IsValid( ent ) ) then return end
										ent:SetPos( self:GetPos() + self:GetForward() * 6 - self:GetUp() * 3 )
										ent:SetAngles( AngleRand() )
										ent:SetOwner( self:GetOwner() )
										ent:Spawn()
										
										if replicatorType == 1 then
											ent.rCraftingQueen = true
										end
										
										local phys = ent:GetPhysicsObject()
										phys:Wake()
										phys:SetVelocity( VectorRand() * 40 + self:GetForward() * 60 )	
										
										self.rMetalAmount = self.rMetalAmount - 1
										
									elseif replicatorType != 2 then
									
										// ------------------------------- Self Destruction
										
										table.RemoveByValue( m_workersCount, self )

										m_darkPoints[ t_DarkId ].used = false
										
										for i = 1, g_segments_to_assemble_replicator do
		
											local ent = ents.Create( "replicator_segment" )
											
											if not IsValid( ent ) then return end
											ent:SetPos( self:GetPos() + VectorRand() * 3 )
											ent:SetOwner( self:GetOwner() )
											ent:Spawn()
											
											ent.rCraftingQueen = true
											
											local phys = ent:GetPhysicsObject()
											phys:Wake()
											phys:SetVelocity( VectorRand() * 100 )
											
										end
										
										self:Remove()
										
									end
								end
								
							end )
						end )
						
						//h_phys:EnableMotion( false )
						//h_phys:EnableCollisions( false )
					end

				elseif h_ModeStatus == 2 then
				end
			end
		end
		
		//
		//-------------- Wall climbing / walking system
		//
		
		h_phys:EnableGravity( !ground.Hit )
		

		if ground.Hit and groundDist != 0 then
		
			local t_height = 0
			
			if replicatorType == 1 then t_height = 3
			elseif replicatorType == 2 then t_height = 10 end
			
			h_phys:EnableMotion( false )
			
			if h_Move then
				
				local forward = {}
				local forwardDist = 0
				
				local lForward = {}
				local lForwardDist = 0
				
				local fordown = {}
				local fordownDist = 0
				
				if replicatorType == 1 then
				
					forward, forwardDist = traceHullQuick( 
						self:GetPos() + self:GetUp() * 2, 
						self:GetForward() * 20, 
						Vector( 6, 6, 6 ), replicatorNoCollideGroup_Witch )

				elseif replicatorType == 2 then
				
					forward, forwardDist = traceHullQuick( 
						self:GetPos() + self:GetUp() * 4, 
						self:GetForward() * 20, 
						Vector( 10, 10, 10 ), replicatorNoCollideGroup_Witch )
				end

				if forward.Hit then
				
					local t_MoveStep = self.rMoveStep
					local t_Rotation = 1200
					
					if t_MoveStep == 0 then self.rMoveTo = forward.HitPos end
					
					if replicatorType == 1 then t_Rotation = 3000 * math.max( 1 - forwardDist / 20, 0.1 )
					elseif replicatorType == 2 then t_Rotation = 5000 * math.max( 1 - forwardDist / 20, 0.1 )
					end
					
					t_AngleOffset = t_AngleOffset + Angle( -t_Rotation / 40, 0, 0 )
					
				else
					if replicatorType == 1 then
					
						fordown, fordownDist = traceHullQuick( 
							self:GetPos() + self:GetForward() * 10, 
							-self:GetUp() * 10,
							Vector( 6, 6, 6 ), replicatorNoCollideGroup_Witch )
							
					elseif replicatorType == 2 then
					
						fordown, fordownDist = traceHullQuick( 
							self:GetPos() + self:GetForward() * 20, 
							-self:GetUp() * 20, 
							Vector( 12, 12, 12 ), replicatorNoCollideGroup_Witch )
					end
					
					if not fordown.Hit then
					
						local t_Rotation = 20
						
						if replicatorType == 1 then
						elseif replicatorType == 2 then
						end
						
						t_AngleOffset = t_AngleOffset + Angle( t_Rotation, 0, 0 )
						
					end
					
				end
				
				if replicatorType == 1 then

					if h_MoveMode == 0 then t_Offset:Add( self:GetForward() * 2 )
					else t_Offset:Add( self:GetForward() * 4 ) end
					
				elseif replicatorType == 2 then
				
					if h_MoveMode == 0 then t_Offset:Add( self:GetForward() * 5 )
					else t_Offset:Add( self:GetForward() * 7 ) end
				
				end
				
				if forward.Hit or not fordown.Hit then
					t_Offset = t_Offset / 2
				end

				local JUANG = self:WorldToLocalAngles( ( self.rMoveTo - h_phys:GetPos() ):Angle() ).y
				
				//h_phys:AddAngleVelocity( Vector( 0, 0, JUANG ) * 2 )
				t_AngleOffset = t_AngleOffset + Angle( 0, JUANG / 3, 0 )
			end
			
			local W2L_vec, W2L_ang = WorldToLocal( Vector(), self:GetAngles(), Vector(), ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
			W2L_vec, W2L_ang = LocalToWorld( Vector(), Angle( 0, W2L_ang.yaw, 0 ), Vector(), ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
			W2L_ang = self:WorldToLocalAngles( W2L_ang )
			
			t_AngleOffset = t_AngleOffset + Angle( W2L_ang.pitch / 4 , W2L_ang.yaw / 4 , W2L_ang.roll / 4 )

			t_Offset:Add( ( ground.HitPos + self:GetUp() * t_height - self:GetPos() ) )

		else
			h_phys:EnableMotion( true )
			
			local ceiling = {}
			
			if replicatorType == 1 then
			
				ceiling = traceHullQuick( 
					self:GetPos(), 
					self:GetUp() * 15, 
					Vector( 15, 15, 15 ), replicatorNoCollideGroup_Witch )
					
			elseif replicatorType == 2 then
			
				ceiling = traceHullQuick( 
					self:GetPos(), 
					self:GetUp() * 15, 
					Vector( 20, 20, 20 ), replicatorNoCollideGroup_Witch )
			end
				
			//if ceiling.Hit then
			
				local zeroAng = self:WorldToLocalAngles( Angle( 0, self:GetAngles().y, 0 ) )
				h_phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, 0 ) * 10 - h_phys:GetAngleVelocity() )
				
			//end
		end
	
		//
		// ---------------------------------------------------- Path moving
		//
		local point = {}		
		
		if h_PrevInfo and m_pathPoints[ h_PrevInfo.case ] then point = m_pathPoints[ h_PrevInfo.case ][ h_PrevInfo.index ] end
		
		if ground.Hit then	

			ReplicatorMovingOnPath( self, h_phys, ground )
			
			h_phys:SetPos( h_phys:GetPos() + t_Offset )
			h_phys:SetAngles( self:LocalToWorldAngles( t_AngleOffset ) )
			
			//------------------- Pathway
			
			if table.Count( point ) > 0 then
			
				local prevPos = self.rPrevPos
				self.rPrevPos = self:GetPos()
				
				
				if point.pos:Distance( ground.HitPos ) > 50 then

					local info, merge = AddPathPoint( ground.HitPos, { h_PrevInfo } )
					self.rPrevPointId = info
					timer.Start( "rRotateBack" .. self:EntIndex() )

				else
				
					local trace, trDist = traceLine( self:GetPos(), point.pos, replicatorNoCollideGroup_Witch )

					if trace.Hit and trDist > 0 then
					
						local info, merge = AddPathPoint( prevPos, { h_PrevInfo } )
						self.rPrevPointId = info
						timer.Start( "rRotateBack" .. self:EntIndex() )
						
					end
				end
				
			else
			
				local info, merge = AddPathPoint( ground.HitPos, { } )
				self.rPrevPointId = info
				timer.Start( "rRotateBack" .. self:EntIndex() )
				
			end
			
		elseif table.Count( point ) > 0 and point.pos:Distance( ground.HitPos ) > 50 then self.rPrevPointId = { case = "", index = 0 } end
		
		//
		// ------------------------ Animations
		//
		
		// ------ Stand animation
		local t_tNameWalk = "rWalking" .. self:EntIndex()
		local t_tNameRun = "rRun" .. self:EntIndex()

		if not h_Move then
		
			if ( timer.Exists( t_tNameWalk ) or timer.Exists( t_tNameRun ) ) and not t_StandAnimReset then
				
				timer.Remove( t_tNameWalk )
				timer.Remove( t_tNameRun )
				
				PlaySequence( self, "stand" )
				
			end
			
		end
		
		// ------ Walk animation
		if h_Move and h_MoveMode == 0 and not timer.Exists( t_tNameWalk ) then
		
			h_phys:Wake()
			timer.Remove( t_tNameRun )
			
			timer.Create( t_tNameWalk, PlaySequence( self, "walk" ) / 2, 0, function()
			
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
				
			end )
			
		end
		
		// ------ Run animation
		if h_Move and h_MoveMode == 1 and not timer.Exists( t_tNameRun ) then

			h_phys:Wake()
			timer.Remove( t_tNameWalk )
			
			timer.Create( t_tNameRun, PlaySequence( self, "run" ) / 2, 0, function()
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			end )
			
		end

		
		//
		// --------------- Scanner
		//
		
		// ------------------------ Metal identification
		local t_Pos = ground.HitPos / 30
		
		t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * 30
		t_Pos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )

		
		if ground.MatType == MAT_METAL then
			
			if ground.HitWorld and not m_metalPointsAsigned[ t_Pos ] then AddMetalPoint( t_Pos, ground.HitPos, ground.HitNormal, 100 )
			elseif ground.Entity:IsValid() and not m_metalPointsAsigned[ "_"..ground.Entity:EntIndex() ] then AddMetalEntity( ground.Entity ) end

		end
	end
	
end // SERVER

if CLIENT then

	function ReplicatorDarkPointAssig( self )
	
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
		
		mm = Vector( 30, 30, 30 )
		local trace = traceHullQuick( 
			self:GetPos() + Vector( 0, 0, mm.z + 2 ), 
			Vector( ),
			mm, replicatorNoCollideGroup_Witch )
		
		if t_HitNormal == Vector( 0, 0, 1 ) and t_DarkLevel < g_replicator_min_dark_level and not m_darkPoints[ t_StringPos ] and not trace.Hit then AddDarkPoint( t_StringPos, ground.HitPos ) end

	end
	
	
end // CLIENT