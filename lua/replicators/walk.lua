AddCSLuaFile( )

--[[

	REPLICATORS Walking system
	
]]

REPLICATOR.ReplicatorWalking = function( replicatorType, self, h_Ground, h_GroundDist, h_Move, h_MoveMode )

	local h_Offset 			= Vector()
	local h_AngleOffset 	= Angle()
	local h_Phys = self:GetPhysicsObject()

	
	if not self:IsPlayerHolding() and h_Phys:IsGravityEnabled() and not self.rDisableMovining then

		if h_GroundDist > 0 then
		
			if h_Ground.Hit then
			
				local m_Height = 0
				
				if replicatorType == 1 then m_Height = 0
				elseif replicatorType == 2 then m_Height = 6 end
				
				h_Phys:EnableMotion( false )
				
				if h_Move then
					
					local m_Forward 	= {}
					local m_ForwardDist = 0
					
					local h_ForwardDown 	= {}
					local h_ForwardDownDist = 0
					
					if replicatorType == 1 then
					
						m_Forward, m_ForwardDist = CNRTraceHullQuick( self:GetPos() + self:GetUp() * 2, self:GetForward() * 20, Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )

					elseif replicatorType == 2 then
					
						m_Forward, m_ForwardDist = CNRTraceHullQuick( self:GetPos() + self:GetUp() * 4, self:GetForward() * 20, Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )
						
					end

					if m_Forward.Hit then
					
						local m_PathStep = self.rMoveStep
						local m_Rotation = 1200
						
						if m_PathStep == 0 then self.rMoveTo = m_Forward.HitPos end
						
						if replicatorType == 1 then m_Rotation = 4000 * math.max( 1 - m_ForwardDist / 20, 0.1 )
						elseif replicatorType == 2 then m_Rotation = 4000 * math.max( 1 - m_ForwardDist / 20, 0.1 )
						end
						
						h_AngleOffset = h_AngleOffset + Angle( -m_Rotation / 40, 0, 0 )
						
					else
						if replicatorType == 1 then
						
							h_ForwardDown, h_ForwardDownDist = CNRTraceHullQuick( self:GetPos() + self:GetForward() * 10, -self:GetUp() * 10, Vector( 6, 6, 6 ), g_ReplicatorNoCollideGroupWith )
								
						elseif replicatorType == 2 then
						
							h_ForwardDown, h_ForwardDownDist = CNRTraceHullQuick( self:GetPos() + self:GetForward() * 20, -self:GetUp() * 10, Vector( 10, 10, 10 ), g_ReplicatorNoCollideGroupWith )
							
						end
						
						if not h_ForwardDown.Hit then
						
							local m_Rotation = 0
							
							if replicatorType == 1 then m_Rotation = 20
							elseif replicatorType == 2 then m_Rotation = 20 end
							
							h_AngleOffset = h_AngleOffset + Angle( m_Rotation, 0, 0 )
							
						end
						
					end
					
					if m_Forward.Hit or not h_ForwardDown.Hit then h_Offset = h_Offset / 4 end

					if replicatorType == 1 then

						if h_MoveMode == 0 then h_Offset:Add( self:GetForward() * 2 )
						else h_Offset:Add( self:GetForward() * 4 ) end
						
					elseif replicatorType == 2 then
					
						if h_MoveMode == 0 then h_Offset:Add( self:GetForward() * 5 )
						else h_Offset:Add( self:GetForward() * 7 ) end
					
					end
					
					local JUANG = self:WorldToLocalAngles( ( self.rMoveTo - h_Phys:GetPos() ):Angle() ).y
					net.Start( "debug_rDrawPoint" ) net.WriteEntity( self ) net.WriteVector( self.rMoveTo ) net.Broadcast()

					h_AngleOffset = h_AngleOffset + Angle( 0, JUANG / 5, 0 )
					h_Offset = h_Offset / math.max( math.abs( JUANG ) / 30, 1 )
					
				end
				
				local W2L_vec, W2L_ang = WorldToLocal( Vector(), self:GetAngles(), Vector(), h_Ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
				W2L_vec, W2L_ang = LocalToWorld( Vector(), Angle( 0, W2L_ang.yaw, 0 ), Vector(), h_Ground.HitNormal:Angle() + Angle( 90, 0, 0 ) )
				W2L_ang = self:WorldToLocalAngles( W2L_ang )
				
				h_AngleOffset = h_AngleOffset + Angle( W2L_ang.pitch / 4 , W2L_ang.yaw / 4 , W2L_ang.roll / 4 )
				
				local m_DistAccess = 0
				
				if replicatorType == 1 then m_DistAccess = 25
				elseif replicatorType == 2 then m_DistAccess = 35
				end
				
				if h_GroundDist < m_DistAccess then
				
					h_Offset:Add( ( h_Ground.HitPos + self:GetUp() * m_Height - self:GetPos() ) / 2 )
					
				end

				if h_MoveMode == 0 then h_Offset = h_Offset / 1,5 end
				
				h_Phys:SetPos( h_Phys:GetPos() + h_Offset )
				h_Phys:SetAngles( self:LocalToWorldAngles( h_AngleOffset ) )
				
				local m_Height = 0
				
				if h_GroundDist != 0 then
				
					if replicatorType == 1 then m_Height = 5
					elseif replicatorType == 2 then m_Height = 7 end
					
				end

			else
				h_Phys:EnableMotion( true )
				
				local ceiling = {}
				
				if replicatorType == 1 then
				
					ceiling = CNRTraceHullQuick( self:GetPos(), self:GetUp() * 15, Vector( 15, 15, 15 ), g_ReplicatorNoCollideGroupWith )
						
				elseif replicatorType == 2 then
				
					ceiling = CNRTraceHullQuick( self:GetPos(), self:GetUp() * 15, Vector( 20, 20, 20 ), g_ReplicatorNoCollideGroupWith )
					
				end

				local t_ZeroAng = self:WorldToLocalAngles( Angle( 0, self:GetAngles().y, 0 ) )
				h_Phys:AddAngleVelocity( Vector( t_ZeroAng.z, t_ZeroAng.x, 0 ) * 10 - h_Phys:GetAngleVelocity() )
				
			end

			self.rPrevPosition = { pos = h_Phys:GetPos(), angle = h_Phys:GetAngles() }
			
		elseif not h_Phys:IsMotionEnabled() then
		
			h_Offset = Vector()
			h_AngleOffset = Angle()
			
			h_Phys:SetPos( self.rPrevPosition.pos )
			
			h_Phys:SetAngles( self.rPrevPosition.angle )

			h_Phys:EnableMotion( true )
			h_Phys:Wake()
			self:PhysWake()
			
			self.rPrevPointId = { }
			self.rPrevPos = self:GetPos()
			
		else
		
			self.rPrevPointId = { }
			self.rPrevPos = self:GetPos()
			
		end
	end
end

REPLICATOR.ReplicatorWalkingAnimation = function( replicatorType, self, h_Move, h_MoveMode, h_StandAnimReset )

	local h_Phys = self:GetPhysicsObject()

	// =============== Stand animation ===================
	local h_NameWalk = "rWalking" .. self:EntIndex()
	local h_NameRun = "rRun" .. self:EntIndex()

	if not h_Move then
	
		if ( timer.Exists( h_NameWalk ) or timer.Exists( h_NameRun ) ) then
			
			timer.Remove( h_NameWalk )
			timer.Remove( h_NameRun )
			
			if not h_StandAnimReset then CNRPlaySequence( self, "stand" ) end
			
		end
	end
	
	// =============== Walk animation ===================
	if h_Move and h_MoveMode == 0 and not timer.Exists( h_NameWalk ) then
	
		h_Phys:Wake()
		timer.Remove( h_NameRun )
		
		timer.Create( h_NameWalk, CNRPlaySequence( self, "walk" ) / 2, 0, function()
		
			if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			
		end )
		
	end
	
	// =============== Run animation ===================
	if h_Move and h_MoveMode == 1 and not timer.Exists( h_NameRun ) then

		h_Phys:Wake()
		timer.Remove( h_NameWalk )
		
		timer.Create( h_NameRun, CNRPlaySequence( self, "run" ) / 2, 0, function()
		
			if self:IsValid() then self:EmitSound( "replicators/replicatorstep" .. math.random( 1, 4 ) .. ".wav", 65, 100 + math.Rand( -25, 25 ), 1, CHAN_AUTO ) end
			
		end )
		
	end
end