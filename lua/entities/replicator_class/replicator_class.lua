AddCSLuaFile( )
include( "replicator_init.lua" )
include( "replicator_think.lua" )
include( "replicator_walk.lua" )

//
// ======================= Replicator functional
//

REPLICATOR = { }

if SERVER then
	
	function ReplicatorGetDamaged( replicatorType, self, dmginfo )
		
		local damage = dmginfo:GetDamage()
		local attacker = dmginfo:GetAttacker()
		
		self:SetHealth( self:Health() - damage )

		if not m_attackers[ "r"..attacker:EntIndex() ] and ( attacker:IsNPC() or attacker:IsPlayer() and attacker:Alive() ) then
		
			m_attackers[ "r"..attacker:EntIndex() ] = attacker
			self.rResearch = true
			
		end
		
		if self:Health() <= 0 then
			
			ReplicatorBreak( replicatorType, self, damage, dmginfo:GetDamagePosition() )
			
		end
	end
	
	//
	// ========================= Modes of Replicator
	//
	
	
	function ReplicatorOnRemove( self ) 
	
		local t_MetalId = self.rTargetMetalId
		local t_DarkId = self.rTargetDarkId
		
		if m_metalPoints[ t_MetalId ] and m_metalPoints[ t_MetalId ].used then m_metalPoints[ t_MetalId ].used = false end
		if m_darkPoints[ t_DarkId ] and m_darkPoints[ t_DarkId ].used then m_darkPoints[ t_DarkId ].used = false end
							
		timer.Remove( "rWalking"..self:EntIndex() )
		timer.Remove( "rRun"..self:EntIndex() )
		timer.Remove( "rRotateBack"..self:EntIndex() )
		timer.Remove( "rScanner"..self:EntIndex() )
		timer.Remove( "rScannerDark"..self:EntIndex() )
		timer.Remove( "rChangingDirection"..self:EntIndex() )
		timer.Remove( "rEating"..self:EntIndex() )
		timer.Remove( "rGiving"..self:EntIndex() )
		timer.Remove( "rDamagining"..self:EntIndex() )
		
	end
		
end // SERVER

if CLIENT then

	function ReplicatorDarkPointAssig( self )
	
		local mm = Vector( 4, 4, 4 )
		local ground, groundDist = CNRTraceHullQuick( 
			self:GetPos(), -self:GetUp() * 20, 
			mm, replicatorNoCollideGroup_With )
			
		local t_lColor = render.GetLightColor( self:GetPos() )
		local t_DarkLevel = ( t_lColor.x + t_lColor.y + t_lColor.z ) / 3 * 100
		
		local t_HitNormal = ground.HitNormal
		t_HitNormal = Vector( math.Round( t_HitNormal.x ), math.Round( t_HitNormal.y ), math.Round( t_HitNormal.z ) )

		local t_Pos, t_StringPos = convertToGrid( self:GetPos(), 100 )
		
		local mm = Vector( 30, 30, 30 )
		
		local trace = CNRTraceHullQuick( 
			self:GetPos() + Vector( 0, 0, mm.z + 2 ), 
			Vector( ),
			mm, replicatorNoCollideGroup_With )
		
		if t_HitNormal == Vector( 0, 0, 1 ) and t_DarkLevel < g_replicator_min_dark_level and not m_darkPoints[ t_StringPos ] and not trace.Hit then AddDarkPoint( t_StringPos, ground.HitPos ) end

	end
	

	
	function ReplicatorDrawDebug( self )
		
		net.Receive( "rDrawPoint", function() net.ReadEntity().cPoint = net.ReadVector() end )
		render.DrawLine( self:GetPos(), self.cPoint, Color( 255, 255, 255 ), true )
		
		net.Receive( "rDrawpPoint", function() net.ReadEntity().pPoint = net.ReadVector() end )
		render.DrawLine( self:GetPos(), self.pPoint, Color( 255, 255, 255 ), true )
	end
	
	
end // CLIENT