AddCSLuaFile( )
include( "replicator_path_moving.lua" )

if SERVER then

	//
	// ======================== Replicator scanning resources
	//
	
	function ReplicatorScanningResources( self )
		
		local result = ents.FindInSphere( self:GetPos(), 500 )
		
		for k, v in pairs( result ) do
			
			if v:GetClass() == "prop_physics" then
			
				local dir = VectorRand()
				dir:Normalize()
				
				trace = CNRTraceQuick( 
				v:WorldSpaceCenter(), dir * v:GetModelRadius(),
				replicatorNoCollideGroup_With )
				
				if trace.MatType == MAT_METAL and v:IsValid() and not m_metalPointsAsigned[ "_"..v:EntIndex() ] then AddMetalEntity( v ) end
				
			elseif v:IsNPC() then
				
				v:AddEntityRelationship( self.rReplicatorNPCTarget, D_HT , 99 ) 
				
			end
		end
	end
	
	//
	// ======================== Replicator breaking
	//
	
	function ReplicatorBreak( replicatorType, self, damage, dmgpos )
	
		local phys = self:GetPhysicsObject()
		//phys:EnableCollisions( false )

		local t_Count = 0
		
		if replicatorType == 1 then t_Count = g_segments_to_assemble_replicator
		elseif replicatorType == 2 then t_Count = g_segments_to_assemble_queen
		end
		
		local ent
		for i = 1, t_Count do
		
			ent = ents.Create( "replicator_segment" )
			
			if not IsValid( ent ) then return end
			ent:SetPos( self:GetPos() + VectorRand() * 3 )
			ent:SetAngles( AngleRand() )
			ent:SetOwner( self:GetOwner() )
			ent:Spawn()
			
			local phys = ent:GetPhysicsObject()
			phys:Wake()
			
			local vec = ( self:GetPos() - dmgpos )
			vec:Normalize()
			
			phys:SetVelocity( ( VectorRand() + vec / 2 ) * ( damage / 2 + 100 ) )
			
		end
		
		ent:EmitSound( "npc/manhack/gib.wav", 75, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
		
		self:Remove()
	end
	

	function ReplicatorThink( replicatorType, self  )
		
		// ======================= Varibles
		
		local ground = {}
		local groundDist = 0
		
		if replicatorType == 1 then
		
			ground, groundDist = CNRTraceHullQuick( 
				self:GetPos() + self:GetUp() * 15, -self:GetUp() * 30,
				Vector( 6, 6, 6 ), replicatorNoCollideGroup_With )
				
		elseif replicatorType == 2 then
		
			ground, groundDist = CNRTraceHullQuick( 
				self:GetPos() + self:GetUp() * 10, -self:GetUp() * 40,
				Vector( 8, 8, 8 ), replicatorNoCollideGroup_With )		
		
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
		
		//
		// ============================ Modes
		//
		
		// ============================= Research mode
		if h_Research then
		
			//print( h_Mode, h_ModeStatus )
			// ==================== Redirecting when stuck
			
			local t_Name = "rRotateBack" .. self:EntIndex()
			
			if not timer.Exists( t_Name ) then
				
				timer.Create( t_Name, 4, 0, function()
				
					if self:IsValid() then self:SetAngles( self:LocalToWorldAngles( Angle( 0, 90, 0 ) ) ) end
					
				end )
			end
			
			//print( h_Mode, h_ModeStatus )
			
			self.rMove = true
			self.rMoveMode = 1
			self.rMoveReverse = false
			
			timer.Remove( "rRefind"..self:EntIndex() )
		
			local t_Name = "rChangingDirection"..self:EntIndex()
			
			if not timer.Exists( t_Name ) then
			
				timer.Create( t_Name, math.Rand( 2, 8 ), 0, function()
				
					if self:IsValid() then self.rYawRot = math.Rand( 3, -3 ) end
					
				end )
			end
						
			// ===================== Setting path to metal
			
			local t_rMetalAmount = self.rMetalAmount

			local t_Name = "rScanner"..self:EntIndex()
			local targetEnt = self.rTargetEnt

			if table.Count( m_metalPoints ) > 0 and table.Count( h_PrevInfo ) > 0 
				and ( h_Mode == 0 or ( h_Mode == 1 and ( h_ModeStatus == 0 or h_ModeStatus == 1 ) ) )
					and not timer.Exists( t_Name ) then
				
				timer.Create( t_Name, math.Rand( 5, 5 ), 1, function() end )

				local t_PathResult, t_MetalId
				
				if targetEnt:IsValid() then

					t_PathResult = self.rMovePath
					t_MetalId = self.rTargetMetalId
					
				else t_PathResult, t_MetalId = GetPatchWayToClosestMetal( h_PrevInfo ) end

				if table.Count( t_PathResult ) > 0 then
				
					if not m_metalPoints[ t_MetalId ].ent then m_metalPoints[ t_MetalId ].used = true end
					//print( "Scanned" )
					
					timer.Remove( "rRotateBack"..self:EntIndex() )
					timer.Remove( "rScannerDark"..self:EntIndex() )
					timer.Remove( "rScanner"..self:EntIndex() )

					self.rResearch = false
					self.rMoveStep = 1
					
					self.rMode = 1
					self.rModeStatus = 0
					self.rTargetMetalId = t_MetalId
					self.rMovePath = t_PathResult
					
				end
				
				
			end
			
			local t_Name = "rScannerDark"..self:EntIndex()
			
			if ( h_Mode == 1 and h_ModeStatus == 2 or h_Mode == 4 ) and table.Count( m_darkPoints ) > 0 and not timer.Exists( t_Name ) then
				
				timer.Create( t_Name, math.Rand( 5, 5 ), 1, function()

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
			
			// =================== Attack enemies
			
			if table.Count( m_attackers ) > 0 and not timer.Exists( t_Name ) then
				
				local t_PathResult, t_TargetEnt, t_TargetId
				
				local targetEnt = self.rTargetEnt
				if targetEnt:IsValid() then

					t_PathResult = self.rMovePath
					t_TargetId = self.rTargetId
					
					
				else
					local r_Case, r_Index = FindClosestPoint( self:GetPos(), 1 )
					t_PathResult, t_TargetEnt, t_TargetId = GetPatchWayToClosestEnt( { case = r_Case, index = r_Index }, m_attackers )
				end

				if table.Count( t_PathResult ) > 0 then
				
					//if not m_attackers[ t_TargetId ].ent then m_attackers[ t_TargetId ].used = true end
					
					timer.Remove( "rRotateBack" .. self:EntIndex() )
					timer.Remove( "rScanner" .. self:EntIndex() )
					timer.Remove( "rScannerDark"..self:EntIndex() )

					self.rResearch = false
					self.rMoveStep = 1
					
					self.rMode = 2
					self.rModeStatus = 0
					self.rTargetId = t_TargetId
					self.rMovePath = t_PathResult
					
				end
			end
			
			local t_MoveTo = self:GetPos() + self:GetForward() * 40 + self:GetRight() * h_YawRot
			self.rMoveTo = t_MoveTo
			
		else
		
			//
			// ======================================= Getting metal
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
							
								if mPointInfo.ent and mPointInfo.ent:IsValid() then
								
									constraint.Weld( mPointInfo.ent, self, 0, 0, 0, collision == true, false )
									self.rDisableMovining = true
									
								end
								
								//else h_phys:EnableMotion( false ) end
								
							end
						end
					end
					
				// ========================== Eating metal
				elseif h_ModeStatus == 1 then
					
					//self:NextThink( CurTime() + 100 )
					local t_Name = "rEating"..self:EntIndex()
					
					if not timer.Exists( t_Name ) then
					
						timer.Create( t_Name, CNRPlaySequence( self, "eating" ), 0, function()
						
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
									self.rDisableMovining = false

									//h_phys:EnableMotion( true )
									if mPointInfo and mPointInfo.ent and mPointInfo.ent:IsValid() then constraint.RemoveAll( self ) end
									
								end
								
								if t_targetMetalAmount == 0 then
									
									//MsgC( Color( 0, 255, 255 ), "AMOUNT 0\n" )
									
									timer.Remove( "rEating"..self:EntIndex() )
									
									self.rDisableMovining = false
									self.rResearch = true
									self.rModeStatus = 0
									//h_phys:EnableMotion( true )

									if mPointInfo and ( mPointInfo.ent and mPointInfo.ent:IsValid() ) then
										MsgC( Color( 0, 255, 255 ), "REMOVE METAL ", mPointInfo.ent, "\n" )
									
										self.rTargetEnt = Entity( 0 )
										
										if mPointInfo.ent and mPointInfo.ent:IsValid() then
										
											constraint.RemoveAll( self )
											CNRDissolveEntity( mPointInfo.ent )
											m_metalPointsAsigned[ "_"..mPointInfo.ent:EntIndex() ] = nil
											
										end
										

										if m_metalPoints[ t_TargetMetalId ] then m_metalPoints[ t_TargetMetalId ] = nil end
										
									end
								end

								if mPointInfo and m_metalPoints[ t_TargetMetalId ] then
								
									if mPointInfo.ent then m_metalPoints[ t_TargetMetalId ].amount = t_targetMetalAmount - t_Amount
									elseif mPointInfo.pos then UpdateMetalPoint( t_TargetMetalId, t_targetMetalAmount - t_Amount ) end
									
								end
								
								t_rMetalAmount = t_rMetalAmount + t_Amount
								
								//MsgC( Color( 150, 150, 255 ), "Eat metal " ,t_Amount, " ", t_targetMetalAmount, " ", t_rMetalAmount, "\n" )
								self.rMetalAmount = t_rMetalAmount
								
							end
						end )
					end
					
				// ============================== Transporting metal
				elseif h_ModeStatus == 2 then

					local t_QueenFounded = false
					
					//print( table.Count( m_queenCount ), "<" , math.ceil( table.Count( m_workersCount ) / g_amount_of_worker_for_one_queen ) )
					//and table.Count( m_queenCount ) < math.ceil( table.Count( m_workersCount ) / g_amount_of_worker_for_one_queen )
					
					if table.Count( m_queenCount ) > 0 then
					
						local t_PathResult
						local t_QueenEnt = Entity( 0 )
						
						if self.rTargetGueen:IsValid() then
						
							t_PathResult = self.rMovePath
							t_QueenEnt = self.rTargetGueen
							
							self.rMoveReverse = false
						else
							t_PathResult = { self:GetPos() }

							local t_PathGet
							local r_Case, r_Index = FindClosestPoint( self:GetPos(), 1 )

							t_PathGet, t_QueenEnt = GetPatchWayToClosestEnt( { case = r_Case, index = r_Index }, m_queenCount )
							
							table.Add( t_PathResult, t_PathGet )
						end
						
						if table.Count( t_PathResult ) > 0 and t_QueenEnt:IsValid() then
						
							self.rMode = 1
							self.rModeStatus = 3
							
							self.rTargetGueen = t_QueenEnt
							
							self.rMove = true
							self.rMoveMode = 1
							
							self.rMoveStep = 1
							self.rMovePath = t_PathResult
							
							t_QueenFounded = true
							
						end
						
					elseif not t_QueenFounded then
					
						local t_MetalId = self.rTargetMetalId
						//print( "____", t_MetalId )
						//PrintTable( m_metalPoints[ t_MetalId ] )
						
						if m_metalPoints[ t_MetalId ] and m_metalPoints[ t_MetalId ].used then m_metalPoints[ t_MetalId ].used = false end
						
						if table.Count( m_darkPoints ) > 0 then
							
							local t_MetalId = self.rTargetMetalId

							if m_metalPoints[ t_MetalId ].used then m_metalPoints[ t_MetalId ].used = false end
							
							local r_Case, r_Index = FindClosestPoint( self:GetPos(), 1 )
							local t_PathResult, t_DarkId = GetPatchWayToClosestId( { case = r_Case, index = r_Index }, m_darkPoints )
							
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
					else MsgC( Color( 255, 0, 0 ), "ERROR queen doesn't found ( transport )\n" ) end
					
				elseif h_ModeStatus == 3 then
				
					// ======================= Wait until replicator walked to queen
					local t_QueenEnt = self.rTargetGueen
					
					if t_QueenEnt:GetPos():Distance( self:GetPos() ) < 40 then
					
						self.rModeStatus = 4
						self.rMove = false
						//h_phys:EnableMotion( false )
						
					end
					
				elseif h_ModeStatus == 4 then

					// ======================= Qiving metal
					local t_Name = "rGiving"..self:EntIndex()
					
					if not timer.Exists( t_Name ) then
					
						timer.Create( t_Name, CNRPlaySequence( self, "stand" ), 0, function()
						
							if self:IsValid() then
							
								self:NextThink( CurTime() )
							
								local t_QueenEnt = self.rTargetGueen

								local t_rMetalAmount = math.min( g_replicator_giving_speed, self.rMetalAmount )
								
								if t_QueenEnt and t_QueenEnt:IsValid() then
								
									t_QueenEnt.rMetalAmount = t_QueenEnt.rMetalAmount + t_rMetalAmount
									self.rMetalAmount = self.rMetalAmount - t_rMetalAmount
									
								else MsgC( Color( 255, 0, 0 ), "ERROR queen doesn't found ( giving )\n" ) self.rModeStatus = 2 end
								
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
				
			elseif h_Mode == 2 then // ======================= ATTACK MODE
			
				if h_ModeStatus == 0 then
				
					local target = m_attackers[ self.rTargetId ]
					
					if target and target:IsValid() then
					
						local filter = { }
						table.Add( filter, replicatorNoCollideGroup_With )
						table.Add( filter, { "player" } )
						
						local trace, trDist = CNRTraceLine( self:GetPos(), target:GetPos(), filter )
						
						if not trace.Hit then
						
							self.rMoveTo = target:GetPos()
							timer.Start( "rRefind"..self:EntIndex() )
							
							if target:GetPos():Distance( self:GetPos() ) < 100 then
							
								if ground.Hit then
								
									if ground.Entity == target then
									
										h_phys:SetAngles( ( target:GetPos() - h_phys:GetPos() ):Angle() + Angle( -90, 0, 0 ) )
										h_phys:SetPos( ground.HitPos )

										self.rModeStatus = 1
										self.rMove = false
										
										h_phys:EnableCollisions( false )
										timer.Remove( "rRefind"..self:EntIndex() )

										if target:IsPlayer() or target:IsNPC() then self:SetParent( target, 1 )
										else self:SetParent( target, -1 ) end
										
									else
									
										self.rDisableMovining = true
										h_phys:SetVelocity( Vector( 0, 0, 200 ) + ( target:GetPos() - h_phys:GetPos() ) * 2 )
										
									end
									
								else
								
									local JUANG = self:WorldToLocalAngles( ( target:GetPos() - h_phys:GetPos() ):Angle() ).y
									local zeroAng = self:WorldToLocalAngles( Angle( -50, JUANG + self:GetAngles().yaw, 0 ) )

									h_phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, zeroAng.y ) * 6 - h_phys:GetAngleVelocity() )
									//h_phys:SetVelocity( Vector( 0, 0, 100 ) + ( target:GetPos() - h_phys:GetPos() ) )
								end
								
							else self.rDisableMovining = false end
						end
						
					end
					
				elseif h_ModeStatus == 1 then
				
					local name = "rDamagining"..self:EntIndex()
					
					local function UnParent( self, h_phys, target, targetCase )
					
						constraint.RemoveAll( self )
						
						self.rMode = 0
						self.rMoveStatus = 0
						self.rResearch = true
						self.rMove = true
						self.rTargetId = ""
						self.rDisableMovining = false 
						
						timer.Remove( name )
						
						self:SetParent( NULL )
						
						h_phys:EnableCollisions( true )
						
						if target then
						
							m_attackers[ targetCase ] = nil
							
						end
					end

					if not timer.Exists( name ) then
					
						timer.Create( name, CNRPlaySequence( self, "eating" ), 0, function()
						
							local target = m_attackers[ self.rTargetId ]
							target:TakeDamage( 25, self, self )
							
							if target then
							
								if target:Health() <= 0 then UnParent( self, h_phys, target, self.rTargetId ) end
								
							else UnParent( self, h_phys ) end
							
						end )
					end
					
					if self.rTargetId then
					
						local target = m_attackers[ self.rTargetId ]
						
						if target then
						
							if target:Health() <= 0 then UnParent( self, h_phys, target, self.rTargetId ) end
							
						else UnParent( self, h_phys ) end
						
					end
					
				elseif h_ModeStatus == 2 then
				end
				
			elseif h_Mode == 3 then
			elseif h_Mode == 4 then
			
				// ------ Finding dark spot to assemble into queen
				
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
						

						timer.Simple( CNRPlaySequence( self, "crafting_start" ), function()
						
							// IF QUEEN
							if replicatorType == 2 then
							
								table.Add( m_queenCount, { self } )
								table.RemoveByValue( m_workersCount, self )
								
								net.Start( "rDrawStorageEffect" ) net.WriteEntity( self ) net.Broadcast()
								
							end
							
							timer.Create( "rCrafting" .. self:EntIndex(), CNRPlaySequence( self, "crafting" ) / 10, 0, function()
							
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
		// =============== Wall climbing / walking system
		//

		//print( h_phys:IsGravityEnabled() )
		if not self:IsPlayerHolding() and h_phys:IsGravityEnabled() and not self.rDisableMovining then
		
			if groundDist > 0 then
			
				if ground.Hit then
				
					local t_height = 0
					
					if replicatorType == 1 then t_height = 0
					elseif replicatorType == 2 then t_height = 6 end
					
					h_phys:EnableMotion( false )
					
					if h_Move then
						
						local forward = {}
						local forwardDist = 0
						
						local lForward = {}
						local lForwardDist = 0
						
						local fordown = {}
						local fordownDist = 0
						
						if replicatorType == 1 then
						
							forward, forwardDist = CNRTraceHullQuick( 
								self:GetPos() + self:GetUp() * 2, 
								self:GetForward() * 20, 
								Vector( 6, 6, 6 ), replicatorNoCollideGroup_With )

						elseif replicatorType == 2 then
						
							forward, forwardDist = CNRTraceHullQuick( 
								self:GetPos() + self:GetUp() * 4, 
								self:GetForward() * 20, 
								Vector( 6, 6, 6 ), replicatorNoCollideGroup_With )
						end

						if forward.Hit then
						
							local t_MoveStep = self.rMoveStep
							local t_Rotation = 1200
							
							if t_MoveStep == 0 then self.rMoveTo = forward.HitPos end
							
							if replicatorType == 1 then t_Rotation = 4000 * math.max( 1 - forwardDist / 20, 0.1 )
							elseif replicatorType == 2 then t_Rotation = 4000 * math.max( 1 - forwardDist / 20, 0.1 )
							end
							
							t_AngleOffset = t_AngleOffset + Angle( -t_Rotation / 40, 0, 0 )
							
						else
							if replicatorType == 1 then
							
								fordown, fordownDist = CNRTraceHullQuick( 
									self:GetPos() + self:GetForward() * 10, 
									-self:GetUp() * 10,
									Vector( 6, 6, 6 ), replicatorNoCollideGroup_With )
									
							elseif replicatorType == 2 then
							
								fordown, fordownDist = CNRTraceHullQuick( 
									self:GetPos() + self:GetForward() * 20, 
									-self:GetUp() * 10, 
									Vector( 10, 10, 10 ), replicatorNoCollideGroup_With )
							end
							
							if not fordown.Hit then
							
								local t_Rotation = 0
								
								if replicatorType == 1 then t_Rotation = 20
								elseif replicatorType == 2 then t_Rotation = 20 end
								
								t_AngleOffset = t_AngleOffset + Angle( t_Rotation, 0, 0 )
								
							end
							
						end
						
						if forward.Hit or not fordown.Hit then t_Offset = t_Offset / 4 end

						if replicatorType == 1 then

							if h_MoveMode == 0 then t_Offset:Add( self:GetForward() * 2 )
							else t_Offset:Add( self:GetForward() * 4 ) end
							
						elseif replicatorType == 2 then
						
							if h_MoveMode == 0 then t_Offset:Add( self:GetForward() * 5 )
							else t_Offset:Add( self:GetForward() * 7 ) end
						
						end
						
						local JUANG = self:WorldToLocalAngles( ( self.rMoveTo - h_phys:GetPos() ):Angle() ).y
						net.Start( "debug_rDrawPoint" ) net.WriteEntity( self ) net.WriteVector( self.rMoveTo ) net.Broadcast()
						//print( JUANG )
						//h_phys:AddAngleVelocity( Vector( 0, 0, JUANG ) * 2 )
						t_AngleOffset = t_AngleOffset + Angle( 0, JUANG / 5, 0 )
						t_Offset = t_Offset / math.max( math.abs( JUANG ) / 30, 1 )
					end
					
					local W2L_vec, W2L_ang = WorldToLocal( Vector(), self:GetAngles(), Vector(), ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
					W2L_vec, W2L_ang = LocalToWorld( Vector(), Angle( 0, W2L_ang.yaw, 0 ), Vector(), ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
					W2L_ang = self:WorldToLocalAngles( W2L_ang )
					
					t_AngleOffset = t_AngleOffset + Angle( W2L_ang.pitch / 4 , W2L_ang.yaw / 4 , W2L_ang.roll / 4 )
					
					local t_DistAccess
					
					if replicatorType == 1 then t_DistAccess = 25
					elseif replicatorType == 2 then t_DistAccess = 35
					end
					
					if groundDist < t_DistAccess then
						t_Offset:Add( ( ground.HitPos + self:GetUp() * t_height - self:GetPos() ) / 2 )
					end

				else
					h_phys:EnableMotion( true )
					
					local ceiling = {}
					
					if replicatorType == 1 then
					
						ceiling = CNRTraceHullQuick( 
							self:GetPos(), 
							self:GetUp() * 15, 
							Vector( 15, 15, 15 ), replicatorNoCollideGroup_With )
							
					elseif replicatorType == 2 then
					
						ceiling = CNRTraceHullQuick( 
							self:GetPos(), 
							self:GetUp() * 15, 
							Vector( 20, 20, 20 ), replicatorNoCollideGroup_With )
					end
						
					//if ceiling.Hit then
					
						local zeroAng = self:WorldToLocalAngles( Angle( 0, self:GetAngles().y, 0 ) )
						h_phys:AddAngleVelocity( Vector( zeroAng.z, zeroAng.x, 0 ) * 10 - h_phys:GetAngleVelocity() )
						
					//end
				end

				self.rPrevPosition = { pos = h_phys:GetPos(), angle = h_phys:GetAngles() }
				
			elseif not h_phys:IsMotionEnabled() then
			
				t_Offset = Vector()
				t_AngleOffset = Angle()
				
				h_phys:SetPos( self.rPrevPosition.pos )
				
				h_phys:SetAngles( self.rPrevPosition.angle )

				h_phys:EnableMotion( true )
				h_phys:Wake()
				self:PhysWake()
				
				self.rPrevPointId = { }
				self.rPrevPos = self:GetPos()
				
			else
			
				self.rPrevPointId = { }
				self.rPrevPos = self:GetPos()
				
			end
			
			//
			// ========================================== Path moving
			//
			local point = {}		
			
			if h_PrevInfo and m_pathPoints[ h_PrevInfo.case ] then point = m_pathPoints[ h_PrevInfo.case ][ h_PrevInfo.index ] end
			
			if ground.Hit then	

				ReplicatorMovingOnPath( self, h_phys, ground )
				
				h_phys:SetPos( h_phys:GetPos() + t_Offset )
				h_phys:SetAngles( self:LocalToWorldAngles( t_AngleOffset ) )
				
				// ========================== Pathway
				local t_height = 0
				
				if groundDist != 0 then
				
					if replicatorType == 1 then t_height = 5
					elseif replicatorType == 2 then t_height = 7 end
					
				end
				
				local t_pPoint = ground.HitPos - self:GetUp() * t_height
				
				if table.Count( point ) > 0 then
				
					local prevPos = self.rPrevPos
					self.rPrevPos = self:GetPos()
					
					
					if point.pos:Distance( ground.HitPos ) > 50 then

						local info, merge = AddPathPoint( t_pPoint, { h_PrevInfo }, ground.Entity )
						self.rPrevPointId = info
						
						net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( m_pathPoints[ info.case ][ info.index ].pos ) net.Broadcast()
						
						timer.Start( "rRotateBack" .. self:EntIndex() )

					else
					
						local trace, trDist = CNRTraceLine( self:GetPos(), point.pos, replicatorNoCollideGroup_With )

						if trace.Hit and trDist > 0 then
						
							local info, merge = AddPathPoint( self:GetPos(), { h_PrevInfo }, ground.Entity )
							self.rPrevPointId = info
							net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( m_pathPoints[ info.case ][ info.index ].pos ) net.Broadcast()

							timer.Start( "rRotateBack" .. self:EntIndex() )
							
						end
					end
					
				else
				
					local info, merge = AddPathPoint( t_pPoint, { } )
					self.rPrevPointId = info
					net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( m_pathPoints[ info.case ][ info.index ].pos ) net.Broadcast()
					
					timer.Start( "rRotateBack" .. self:EntIndex() )
					
				end
				
			elseif table.Count( point ) > 0 and point.pos:Distance( ground.HitPos ) > 50 then
			
				self.rPrevPointId = { case = "", index = 0 }
				net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( Vector( 0, 0, 0 ) ) net.Broadcast()
				//print( "SPAM" )
				
			end
			
		else
		
			h_phys:EnableMotion( true )
			h_phys:Wake()
			self:PhysWake()

			self.rPrevPointId = { }
			self.rPrevPos = self:GetPos()
			
		end
		
		if not h_phys:IsGravityEnabled() and h_phys:IsMotionEnabled() then h_phys:SetVelocity( self:GetForward() * h_phys:GetMass() / 2 ) end
		
		if self.rReplicatorNPCTarget and ( not self.rReplicatorNPCTarget:IsValid() or self.rReplicatorNPCTarget:IsValid() and self.rReplicatorNPCTarget:Health() <= 0 ) then
		
			ReplicatorBreak( replicatorType, self, 0, Vector() )
			
		end
		//
		// ================ Animations
		//
		
		// ============ Stand animation
		local t_tNameWalk = "rWalking" .. self:EntIndex()
		local t_tNameRun = "rRun" .. self:EntIndex()

		if not h_Move then
		
			if ( timer.Exists( t_tNameWalk ) or timer.Exists( t_tNameRun ) ) and not t_StandAnimReset then
				
				timer.Remove( t_tNameWalk )
				timer.Remove( t_tNameRun )
				
				CNRPlaySequence( self, "stand" )
				
			end
			
		end
		
		// =========== Walk animation
		if h_Move and h_MoveMode == 0 and not timer.Exists( t_tNameWalk ) then
		
			h_phys:Wake()
			timer.Remove( t_tNameRun )
			
			timer.Create( t_tNameWalk, CNRPlaySequence( self, "walk" ) / 2, 0, function()
			
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
				
			end )
			
		end
		
		// =============== Run animation
		if h_Move and h_MoveMode == 1 and not timer.Exists( t_tNameRun ) then

			h_phys:Wake()
			timer.Remove( t_tNameWalk )
			
			timer.Create( t_tNameRun, CNRPlaySequence( self, "run" ) / 2, 0, function()
				if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			end )
			
		end

		
		//
		// ============= Scanner
		//
		
		// ======================== Metal identification
		ReplicatorScanningResources( self )
		
		local t_Pos = ground.HitPos / 30
		
		t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * 30
		t_Pos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )

		
		if ground.MatType == MAT_METAL then
			
			if ground.HitWorld then 
				
				self.rTargetMetalId = t_Pos
				if not m_metalPointsAsigned[ t_Pos ] then AddMetalPoint( t_Pos, ground.HitPos, ground.HitNormal, 100 ) end
			
			elseif ground.Entity:IsValid() then

				self.rTargetMetalId = "_"..ground.Entity:EntIndex()
				if  not m_metalPointsAsigned[ "_"..ground.Entity:EntIndex() ] then AddMetalEntity( ground.Entity ) end
				
			end

		end
	end
end // SERVER