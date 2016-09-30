--[[

	REPLICATORS
	
]]

AddCSLuaFile( )

REPLICATOR = { }

include( "replicators/data.lua" )
include( "replicators/keron.lua" )
include( "replicators/collisions.lua" )

include( "replicators/initialize.lua" )
include( "replicators/ai.lua" )
include( "replicators/path_moving.lua" )
include( "replicators/walk.lua" )

list.Add( "OverrideMaterials", "rust/rusty_paint" )

concommand.Add( "tr_replicator_limit", function( ply, cmd, args )

	print( ply, cmd, args )
	PrintTable( args )
	//g_replicator_limit = agrs
	
end )


REPLICATOR.ConvertToGrid = function( pos, size )

	local t_Pos = pos / size
	t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * size
	
	local t_StringPos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )
	
	return t_Pos, t_StringPos
	
end

REPLICATOR.DissolveEntity = function( ent )

	 ent:SetKeyValue( "targetname", "ANIHILATION" )
	 g_Replicator_entDissolver:Fire( "Dissolve", "ANIHILATION", 0 )
	 
end

REPLICATOR.PlaySequence = function( self, seq )

	local sequence = self:LookupSequence( seq )
	self:ResetSequence( sequence )

	self:SetPlaybackRate( 1.0 )
	self:SetSequence( sequence )
	
	return self:SequenceDuration( sequence )
end


REPLICATOR.ReplicatorOnTakeDamage = function( replicatorType, self, dmginfo )
	
	local h_Damage = dmginfo:GetDamage()
	local h_Attacker = dmginfo:GetAttacker()
	
	self:SetHealth( self:Health() - h_Damage )

	if not g_Attackers[ "r"..h_Attacker:EntIndex() ] and ( h_Attacker:IsNPC() or h_Attacker:IsPlayer() and h_Attacker:Alive() ) then
	
		g_Attackers[ "r"..h_Attacker:EntIndex() ] = h_Attacker
		
		if ( replicatorType == 2 and not g_QueenCount[ self:EntIndex() ] ) then
		
			self.rResearch = true
			
		end
	end
	
	if self:Health() <= 0 then
		
		REPLICATOR.ReplicatorBreak( replicatorType, self, h_Damage, dmginfo:GetDamagePosition() )
		
	end
end

REPLICATOR.ReplicatorOnRemove = function( replicatorType, self ) 

	local h_MetalId = self.rTargetMetalId
	local h_DarkId = self.rTargetDarkId
		
	if g_MetalPoints[ h_MetalId ] and g_MetalPoints[ h_MetalId ].used then g_MetalPoints[ h_MetalId ].used = false end
	if g_DarkPoints[ h_DarkId ] and g_DarkPoints[ h_DarkId ].used then g_DarkPoints[ h_DarkId ].used = false end
	
	g_QueenCount[ self:EntIndex() ] = nil 
	g_WorkersCount[ self:EntIndex() ] = nil
	g_Replicators[ self:EntIndex() ] = nil
	
	timer.Remove( "rWalking"..self:EntIndex() )
	timer.Remove( "rRun"..self:EntIndex() )
	timer.Remove( "rRotateBack"..self:EntIndex() )
	timer.Remove( "rScanner"..self:EntIndex() )
	timer.Remove( "rScannerDark"..self:EntIndex() )
	timer.Remove( "rScannerAttacker"..self:EntIndex() )
	timer.Remove( "rChangingDirection"..self:EntIndex() )
	timer.Remove( "rEating"..self:EntIndex() )
	timer.Remove( "rGiving"..self:EntIndex() )
	timer.Remove( "rDamagining"..self:EntIndex() )
	
end

REPLICATOR.ReplicatorDarkPointAssig = function( self )

	local h_Radius = Vector( 4, 4, 4 )
	local h_Ground, h_GroundDist = REPLICATOR.TraceHullQuick( self:GetPos(), -self:GetUp() * 20, h_Radius, g_ReplicatorNoCollideGroupWith )
	local h_LColor = render.GetLightColor( self:GetPos() )
	local h_DarkLevel = ( h_LColor.x + h_LColor.y + h_LColor.z ) / 3 * 100

	local h_HitNormal = h_Ground.HitNormal
	h_HitNormal = Vector( math.Round( h_HitNormal.x ), math.Round( h_HitNormal.y ), math.Round( h_HitNormal.z ) )

	local h_Pos, h_StringPos = REPLICATOR.ConvertToGrid( self:GetPos(), 100 )
	h_Radius = Vector( 30, 30, 30 )
	
	local h_Trace = REPLICATOR.TraceHullQuick( self:GetPos() + Vector( 0, 0, h_Radius.z + 2 ), Vector( ), h_Radius, g_ReplicatorNoCollideGroupWith )
	
	if h_HitNormal == Vector( 0, 0, 1 ) and h_DarkLevel < g_replicator_min_dark_level 
	and not g_DarkPoints[ h_StringPos ] and not h_Trace.Hit then AddDarkPoint( h_StringPos, h_Ground.HitPos ) end

end

REPLICATOR.ReplicatorScanningResources = function( self )
	
	local h_Result = ents.FindInSphere( self:GetPos(), 500 )
	
	for k, v in pairs( h_Result ) do
		
		if v:GetClass() == "prop_physics" then
		
			local m_Dir = VectorRand()
			m_Dir:Normalize()
			
			m_Trace = REPLICATOR.
			TraceQuick( 
			v:WorldSpaceCenter(), m_Dir * v:GetModelRadius(),
			g_ReplicatorNoCollideGroupWith )
			
			if m_Trace.MatType == MAT_METAL and v:IsValid() and not g_MetalPointsAsigned[ "_"..v:EntIndex() ] then AddMetalEntity( v ) end
			
		elseif v:IsNPC() and !v.rNPCTarget then
		
			for k2, v2 in pairs( self.rReplicatorNPCTarget ) do
			
				v:AddEntityRelationship( v2, D_HT , 99 )
			
			end
		end
	end
end

REPLICATOR.ReplicatorBreak = function( replicatorType, self, damage, dmgpos, assembleToGueen )

	local t_Count = 0
	
	if replicatorType == 1 then t_Count = g_segments_to_assemble_replicator
	elseif replicatorType == 2 then t_Count = g_segments_to_assemble_queen
	end
	
	local h_Ent = Entity( 0 )
	
	for i = 1, t_Count do
	
		h_Ent = ents.Create( "replicator_segment" )
		
		if not IsValid( h_Ent ) then return end
		h_Ent:SetPos( self:GetPos() + VectorRand() * 3 )
		h_Ent:SetAngles( AngleRand() )
		h_Ent:SetOwner( self:GetOwner() )
		h_Ent:Spawn()
		
		if assembleToGueen then
			
			h_Ent.rCraftingQueen = true
			
		end
		
		local phys = h_Ent:GetPhysicsObject()
		phys:Wake()
		
		local vec = ( self:GetPos() - dmgpos )
		vec:Normalize()
		
		phys:SetVelocity( ( VectorRand() + vec / 2 ) * ( damage / 2 + 100 ) )
		
	end
	
	h_Ent:EmitSound( "npc/manhack/gib.wav", 75, 150 + math.Rand( -25, 25 ), 1, CHAN_AUTO )
	
	self:Remove()
end

REPLICATOR.ReplicatorDrawDebug = function( self )
	
	net.Receive( "rDrawPoint", function() net.ReadEntity().cPoint = net.ReadVector() end )
	render.DrawLine( self:GetPos(), self.cPoint, Color( 255, 255, 255 ), true )
	
	net.Receive( "rDrawpPoint", function() net.ReadEntity().pPoint = net.ReadVector() end )
	render.DrawLine( self:GetPos(), self.pPoint, Color( 255, 255, 255 ), true )
	
end
