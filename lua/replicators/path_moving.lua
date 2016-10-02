--[[

	REPLICATORS Moving on path
	
]]

AddCSLuaFile( )

REPLICATOR.ReplicatorMovingOnPath = function( self, h_phys, ground )
	
	local h_MoveStep = self.rMoveStep

	if h_MoveStep > 0 then
		
		local m_MovePath = self.rMovePath

		if table.Count( m_MovePath ) > 0 then

			local m_MoveReverse = self.rMoveReverse
		
			local m_MToPos 	= Vector()
			local m_Dist 	= 0
			local m_DistTo 	= 0
			
			local t_Name = "rRefind"..self:EntIndex()
			
			if self.rLastPos then
			
				if self.rLastPos:Distance( self:GetPos() ) > 20 then
				
					timer.Start( "rRefind"..self:EntIndex() )
					self.rLastPos = self:GetPos()
					
				end
				
			else self.rLastPos = self:GetPos() end
			
			if not timer.Exists( t_Name ) then
			
				timer.Create( t_Name, 4, 1, function()
					
					if self:IsValid() then
					
						local t_MetalId = self.rTargetMetalId
						local t_DarkId 	= self.rTargetDarkId
						
						if g_MetalPoints[ t_MetalId ] and g_MetalPoints[ t_MetalId ].used then g_MetalPoints[ t_MetalId ].used = false end
						if g_DarkPoints[ t_DarkId ] and g_DarkPoints[ t_DarkId ].used then g_DarkPoints[ t_DarkId ].used = false end

						self.rResearch 		= true
						self.rMove 			= true
						self.rMoveMode		= 1
						self.rMoveReverse 	= false
						self.rTargetEnt 	= Entity( 0 )
						self.rTargetGueen 	= Entity( 0 )
						self.rMovePath 		= {}
						
						timer.Create( "rScanner"..self:EntIndex(), math.Rand( 5, 5 ), 1, function() end )
						timer.Create( "rScannerDark"..self:EntIndex(), math.Rand( 5, 5 ), 1, function() end )
						
						if self.rMode == 1 and self.rModeStatus == 3 then self.rModeStatus = 2 end
						
						local m_Case = m_MovePath[ h_MoveStep ].case
						
						if not ( ( h_MoveStep == table.Count( m_MovePath ) or h_MoveStep == 1 ) and not g_PathPoints[ m_Case ] ) then
						
							local m_Index = m_MovePath[ h_MoveStep ].index
							
							if not g_PointIsInvalid[ m_Case ] then g_PointIsInvalid[ m_Case ] = {} end
							if not g_PointIsInvalid[ m_Case ][ m_Index ] then g_PointIsInvalid[ m_Case ][ m_Index ] = 0 end
							
							g_PointIsInvalid[ m_Case ][ m_Index ] = g_PointIsInvalid[ m_Case ][ m_Index ] + 1
							
						end						
					end
				end )
			end
			
			local m_Case = m_MovePath[ h_MoveStep ].case

			if m_MoveReverse then
			
				if ( h_MoveStep == table.Count( m_MovePath ) or h_MoveStep == 1 ) and not g_PathPoints[ m_Case ] then
					
					m_MToPos = m_MovePath[ h_MoveStep ]
					
					m_Dist = 20
					m_DistTo = self:GetPos()
					
				else
				
					local m_Index = m_MovePath[ h_MoveStep ].index

					m_MToPos = g_PathPoints[ m_Case ][ m_Index ].pos
					
					m_Dist = 20
					m_DistTo = ground.HitPos
					
				end
				
				if m_MToPos:Distance( m_DistTo ) > m_Dist then
					
					self.rMoveTo = m_MToPos
					
				elseif h_MoveStep > 1 and not REPLICATOR.TraceLine( m_MToPos, m_DistTo, g_ReplicatorNoCollideGroupWith ).Hit then
				
					self.rMoveStep = h_MoveStep - 1

					if not ( ( h_MoveStep == table.Count( m_MovePath ) or h_MoveStep == 1 ) and not g_PathPoints[ m_Case ] ) then
					
						local m_Index = m_MovePath[ h_MoveStep ].index
						
						if g_PointIsInvalid[ m_Case ] and g_PointIsInvalid[ m_Case ][ m_Index ] then
						
							g_PointIsInvalid[ m_Case ][ m_Index ] = 0
							
						end
					end
				end
			
			else

				if ( h_MoveStep == table.Count( m_MovePath ) or h_MoveStep == 1 ) and not g_PathPoints[ m_Case ] then

					m_MToPos = m_MovePath[ h_MoveStep ]

					m_Dist = 20
					m_DistTo = self:GetPos()
					
				else
				
					local m_Index = m_MovePath[ h_MoveStep ].index

					m_MToPos = g_PathPoints[ m_Case ][ m_Index ].pos
					m_Dist = 20
					m_DistTo = ground.HitPos
					
				end
				
				if m_MToPos:Distance( m_DistTo ) > m_Dist then
				
					self.rMoveTo = m_MToPos
					
				elseif h_MoveStep < table.Count( m_MovePath ) and not REPLICATOR.TraceLine( m_MToPos, m_DistTo, g_ReplicatorNoCollideGroupWith ).Hit then
				
					self.rMoveStep = h_MoveStep + 1
					
					if not ( ( h_MoveStep == table.Count( m_MovePath ) or h_MoveStep == 1 ) and not g_PathPoints[ m_Case ] ) then
					
						local m_Index = m_MovePath[ h_MoveStep ].index
						
						if g_PointIsInvalid[ m_Case ] and g_PointIsInvalid[ m_Case ][ m_Index ] then
						
							g_PointIsInvalid[ m_Case ][ m_Index ] = 0
							
						end
					end
				end
			end					
		end
	end
end

REPLICATOR.CreatingPath = function( self, h_Ground )

	local h_PrevInfo 	= self.rPrevPointId
	local h_Phys 		= self:GetPhysicsObject()

	if not self:IsPlayerHolding() and h_Phys:IsGravityEnabled() and not self.rDisableMovining then
	
		local h_Point = {}		
		
		if h_PrevInfo and g_PathPoints[ h_PrevInfo.case ] then h_Point = g_PathPoints[ h_PrevInfo.case ][ h_PrevInfo.index ] end
		
		if h_Ground.Hit then	

			REPLICATOR.ReplicatorMovingOnPath( self, h_Phys, h_Ground )
			
			local t_pPoint = h_Ground.HitPos - self:GetUp() * m_Height
			
			if table.Count( h_Point ) > 0 then
			
				local prevPos = self.rPrevPos
				self.rPrevPos = self:GetPos()
				
				
				if h_Point.pos:Distance( h_Ground.HitPos ) > 50 then

					local info, merge = AddPathPoint( t_pPoint, { h_PrevInfo }, h_Ground.Entity )
					self.rPrevPointId = info
					
					net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( g_PathPoints[ info.case ][ info.index ].pos ) net.Broadcast()
					
					timer.Start( "rRotateBack"..self:EntIndex() )

				else
				
					local trace, trDist = REPLICATOR.TraceLine( self:GetPos(), h_Point.pos, g_ReplicatorNoCollideGroupWith )

					if trace.Hit and trDist > 0 then
					
						local info, merge = AddPathPoint( self:GetPos(), { h_PrevInfo }, h_Ground.Entity )
						self.rPrevPointId = info
						net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( g_PathPoints[ info.case ][ info.index ].pos ) net.Broadcast()

						timer.Start( "rRotateBack"..self:EntIndex() )
						
					end
				end
				
			else
			
				local info, merge = AddPathPoint( t_pPoint, { } )
				self.rPrevPointId = info
				net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( g_PathPoints[ info.case ][ info.index ].pos ) net.Broadcast()
				
				timer.Start( "rRotateBack"..self:EntIndex() )
				
			end
			
		elseif table.Count( h_Point ) > 0 and h_Point.pos:Distance( h_Ground.HitPos ) > 50 then
		
			self.rPrevPointId = { case = "", index = 0 }
			net.Start( "debug_rDrawpPoint" ) net.WriteEntity( self ) net.WriteVector( Vector() ) net.Broadcast()

		end
		
	else

		h_Phys:EnableMotion( true )
		h_Phys:Wake()
		self:PhysWake()

		self.rPrevPointId = { }
		self.rPrevPos = self:GetPos()
		
	end
end