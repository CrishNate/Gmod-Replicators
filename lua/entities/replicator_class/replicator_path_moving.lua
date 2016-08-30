AddCSLuaFile( )

if SERVER then

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

							if self.rMode == 1 and self.rModeStatus == 3 then self.rModeStatus = 2 end
							
							local case = t_MovePath[ t_MoveStep ].case
							
							if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ case ] ) then
							
								local index = t_MovePath[ t_MoveStep ].index
								
								if not m_pointIsInvalid[ case ] then m_pointIsInvalid[ case ] = {} end
								if not m_pointIsInvalid[ case ][ index ] then m_pointIsInvalid[ case ][ index ] = 0 end
								
								m_pointIsInvalid[ case ][ index ] = m_pointIsInvalid[ case ][ index ] + 1
								MsgC( Color( 255, 255, 0 ), "Bad Point", case, " ", index, " ", m_pointIsInvalid[ case ][ index ], "\n" )
								
							end
							MsgC( Color( 255, 255, 0 ), t_MoveStep, " ", table.Count( t_MovePath ), " ", not m_pathPoints[ case ], "\n" )
							
						end
					end )
				end
				
				local case = t_MovePath[ t_MoveStep ].case

				if t_MoveReverse then
					
					if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ case ] then
						
						t_MToPos = t_MovePath[ t_MoveStep ]
						
						t_Dist = 20
						t_DistTo = self:GetPos()
						
					else
					
						local index = t_MovePath[ t_MoveStep ].index

						t_MToPos = m_pathPoints[ case ][ index ].pos
						
						t_Dist = 20
						t_DistTo = ground.HitPos
						
					end
					
					if t_MToPos:Distance( t_DistTo ) > t_Dist then
					
						self.rMoveTo = t_MToPos
						
					elseif t_MoveStep > 1 and not CNRTraceLine( t_MToPos, t_DistTo, replicatorNoCollideGroup_Witch ).Hit then
					
						self.rMoveStep = t_MoveStep - 1
						timer.Start( "rRefind"..self:EntIndex() )
						
						if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ case ] ) then
						
							local index = t_MovePath[ t_MoveStep ].index
							
							if m_pointIsInvalid[ case ] and m_pointIsInvalid[ case ][ index ] then
							
								m_pointIsInvalid[ case ][ index ] = 0
								MsgC( Color( 0, 255, 0 ), "Fixing Point", case, " ", index, " ", m_pointIsInvalid[ case ][ index ], "\n" )
								
							end
						end
					end
				
				else

					if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ case ] then

						t_MToPos = t_MovePath[ t_MoveStep ]

						t_Dist = 20
						t_DistTo = self:GetPos()
						
					else
					
						local index = t_MovePath[ t_MoveStep ].index

						t_MToPos = m_pathPoints[ case ][ index ].pos
						t_Dist = 20
						t_DistTo = ground.HitPos
						
					end
					
					if t_MToPos:Distance( t_DistTo ) > t_Dist then
						self.rMoveTo = t_MToPos
						
					elseif t_MoveStep < table.Count( t_MovePath ) and not CNRTraceLine( t_MToPos, t_DistTo, replicatorNoCollideGroup_Witch ).Hit then
					
						self.rMoveStep = t_MoveStep + 1
						timer.Start( "rRefind"..self:EntIndex() )

						if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not m_pathPoints[ case ] ) then
						
							local index = t_MovePath[ t_MoveStep ].index
							
							if m_pointIsInvalid[ case ] and m_pointIsInvalid[ case ][ index ] then
							
								m_pointIsInvalid[ case ][ index ] = 0
								MsgC( Color( 0, 255, 0 ), "Fixing Point", case, " ", index, " ", m_pointIsInvalid[ case ][ index ], "\n" )
								
							end
						end
					end
				end					
			end
		end
	end
end // SERVER