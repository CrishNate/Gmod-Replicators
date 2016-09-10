AddCSLuaFile( )

REPLICATOR.ReplicatorMovingOnPath = function( self, h_phys, ground )
	
	local t_MoveStep = self.rMoveStep

	if t_MoveStep > 0 then
		
		local t_MovePath = self.rMovePath

		if table.Count( t_MovePath ) > 0 then
		
			//print( self.rMode, self.rModeStatus )

			local t_MoveReverse = self.rMoveReverse
		
			local t_MToPos = Vector()
			local t_Dist
			local t_DistTo
			
			local t_Name = "rRefind"..self:EntIndex()
			
			if self.rLastPos then
			
				if self.rLastPos:Distance( self:GetPos() ) > 20 then
				
					timer.Start( "rRefind"..self:EntIndex() )
					self.rLastPos = self:GetPos()
					
				end
				
			else
			
				self.rLastPos = self:GetPos()
				
			end
			
			if not timer.Exists( t_Name ) then
			
				timer.Create( t_Name, 10, 1, function()
					
					if self:IsValid() then
					
						local t_MetalId = self.rTargetMetalId
						local t_DarkId = self.rTargetDarkId
						
						if g_MetalPoints[ t_MetalId ] and g_MetalPoints[ t_MetalId ].used then g_MetalPoints[ t_MetalId ].used = false end
						if g_DarkPoints[ t_DarkId ] and g_DarkPoints[ t_DarkId ].used then g_DarkPoints[ t_DarkId ].used = false end

						self.rResearch = true
						
						self.rMove = true
						self.rMoveMode = 1
						
						self.rMoveReverse = false
						self.rTargetEnt = Entity( 0 )
						self.rTargetGueen = Entity( 0 )
						self.rMovePath = {}
						

						if self.rMode == 1 and self.rModeStatus == 3 then self.rModeStatus = 2 end
						
						local case = t_MovePath[ t_MoveStep ].case
						
						if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not g_PathPoints[ case ] ) then
						
							local index = t_MovePath[ t_MoveStep ].index
							
							if not g_PointIsInvalid[ case ] then g_PointIsInvalid[ case ] = {} end
							if not g_PointIsInvalid[ case ][ index ] then g_PointIsInvalid[ case ][ index ] = 0 end
							
							g_PointIsInvalid[ case ][ index ] = g_PointIsInvalid[ case ][ index ] + 1
							MsgC( Color( 255, 255, 0 ), "Bad Point", case, " ", index, " ", g_PointIsInvalid[ case ][ index ], "\n" )
							
						end
						
					//	MsgC( Color( 255, 255, 0 ), t_MoveStep, " ", table.Count( t_MovePath ), " ", not g_PathPoints[ case ], "\n" )
						
					end
				end )
			end
			
			local case = t_MovePath[ t_MoveStep ].case

			if t_MoveReverse then
				//print( "31231231BLA" )
				if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not g_PathPoints[ case ] then
					
					t_MToPos = t_MovePath[ t_MoveStep ]
					
					t_Dist = 20
					t_DistTo = self:GetPos()
					
				else
				
					local index = t_MovePath[ t_MoveStep ].index

					t_MToPos = g_PathPoints[ case ][ index ].pos
					
					t_Dist = 20
					t_DistTo = ground.HitPos
					
				end
				
				if t_MToPos:Distance( t_DistTo ) > t_Dist then
				
					self.rMoveTo = t_MToPos
					
				elseif t_MoveStep > 1 and not CNRTraceLine( t_MToPos, t_DistTo, g_ReplicatorNoCollideGroupWith ).Hit then
				
					self.rMoveStep = t_MoveStep - 1
					//timer.Start( "rRefind"..self:EntIndex() )
					
					if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not g_PathPoints[ case ] ) then
					
						local index = t_MovePath[ t_MoveStep ].index
						
						if g_PointIsInvalid[ case ] and g_PointIsInvalid[ case ][ index ] then
						
							g_PointIsInvalid[ case ][ index ] = 0
							MsgC( Color( 0, 255, 0 ), "Fixing Point", case, " ", index, " ", g_PointIsInvalid[ case ][ index ], "\n" )
						end
					end
				end
			
			else
				//print( "BLA1231231" )

				if ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not g_PathPoints[ case ] then

					t_MToPos = t_MovePath[ t_MoveStep ]

					t_Dist = 20
					t_DistTo = self:GetPos()
					
				else
				
					local index = t_MovePath[ t_MoveStep ].index

					t_MToPos = g_PathPoints[ case ][ index ].pos
					t_Dist = 20
					t_DistTo = ground.HitPos
					
				end
				
				if t_MToPos:Distance( t_DistTo ) > t_Dist then
				
					self.rMoveTo = t_MToPos
					
				elseif t_MoveStep < table.Count( t_MovePath ) and not CNRTraceLine( t_MToPos, t_DistTo, g_ReplicatorNoCollideGroupWith ).Hit then
				
					self.rMoveStep = t_MoveStep + 1
					//timer.Start( "rRefind"..self:EntIndex() )

					if not ( ( t_MoveStep == table.Count( t_MovePath ) or t_MoveStep == 1 ) and not g_PathPoints[ case ] ) then
					
						local index = t_MovePath[ t_MoveStep ].index
						
						if g_PointIsInvalid[ case ] and g_PointIsInvalid[ case ][ index ] then
						
							g_PointIsInvalid[ case ][ index ] = 0
							MsgC( Color( 0, 255, 0 ), "Fixing Point", case, " ", index, " ", g_PointIsInvalid[ case ][ index ], "\n" )
							
						end
					end
				end
			end					
		end
	end
end