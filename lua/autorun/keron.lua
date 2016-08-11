//--------- Replicators settings
g_segments_to_assemble_replicator 	= 30
g_segments_to_assemble_queen 		= 90

g_replicator_collection_speed		= 2.5
g_replicator_giving_speed			= 10

//--------- Path ways for replicators
m_pathPoints = { }
m_metalPoints = { } m_metalPointsAsigned = { }
m_darkPoints = { }

m_queenCount = { }
m_workersCount = { }

local m_ID = 0
local m_DebugLink = { }

hook.Add( "Initialize", "replicator_keron_initialize", function( )

	if SERVER then
	
		util.AddNetworkString( "rDark_points" )
		util.AddNetworkString( "draw_keron_network" )
		
		//util.AddNetworkString( "draw_metal_points" )
		util.AddNetworkString( "add_metal_points" )
		util.AddNetworkString( "update_metal_points" )
		
		util.AddNetworkString( "debug_render_rerpl" )
		
	end
	
end )

local endPOS

hook.Add( "KeyPress", "debug_render_rerpl", function( ply, key ) 

	if SERVER then
		
		if key == IN_WALK then
		
			net.Start( "draw_keron_network" )
				net.WriteTable( m_pathPoints )
			net.Broadcast()
			
			//print( "__________" )
			//PrintTable( m_pathPoints )
		end
		
		
		if key == IN_RELOAD then endPOS = ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10 print( endPOS ) end

		if key == IN_ZOOM then
		
			local case, index = FindClosestPoint( ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10, 1 )
			print( id )
		end
		
		if key == IN_USE then
			local case, index = FindClosestPoint( ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10, 0 )
			local result = GetPatchWay( { case, index }, endPOS )

			net.Start( "debug_render_rerpl" )
				net.WriteTable( result )
			net.Broadcast()
		end
		
	end
end )


hook.Add( "PostCleanupMap", "replicator_keron_clear", function( )
	m_pathPoints = { }
	m_metalPoints = { }
	m_DebugLink = { }
	m_darkPoints = { }
	m_metalPointsAsigned = { }
	
	m_queenCount = { }
	m_workersCount = { }
	
	m_ID = 0

end )

//
// Converting coordinate to grid
//
function convertToGrid( pos, size )

	local t_Pos = pos / size
	t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * size
	
	local t_StringPos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )
	
	return t_Pos, t_StringPos
end

if SERVER then
	//
	// Returning closest point from Replicators Net Work to pos
	//
	function FindClosestPoint( pos, rad )
	
		local t_Dist = 0

		local t_Case = ""
		local t_Index = 0
		
		local t_pathPoints = {}
				
		for x = -1 * rad, 1 * rad do
		for y = -1 * rad, 1 * rad do
		for z = -1 * rad, 1 * rad do

			local coord, sCoord = convertToGrid( pos + Vector( x, y, z ) * 100, 100 )

			if m_pathPoints[ sCoord ] then table.Add( t_pathPoints, m_pathPoints[ sCoord ] ) end
			
		end
		end
		end
		
		for k, v in pairs( t_pathPoints ) do
			local tracer = traceLine( v.pos, pos, replicatorNoCollideGroup_Witch )
			
			if not tracer.Hit then
			
				if t_Dist > 0 then
				
					local d = v.pos:Distance( pos )
					
					if d < t_Dist then
					
						t_Dist = d

						t_Case = v.case
						t_Index = v.index
						
					end
					
				else
				
					t_Dist = v.pos:Distance( pos )

					t_Case = v.case
					t_Index = v.index
					
				end
			end
		end
		
		return t_Case, t_Index
	end
	
	//
	// Getting Path in Replicators Net Work to endpos
	//
	function GetPatchWay( start, endpos )

		local t_Index, t_Case = FindClosestPoint( endpos, 0 )
		local t_Links = { }
		local t_LinksHistory = { }

		t_Links = { { case = start.case, index = start.index } }
		
		t_LinksHistory[ start.index ] = { start.index }
		
		for k, v in pairs( t_Links ) do
			
			for k2, v2 in pairs( m_pathPoints[ v.case ][ v.index ].connection ) do
			
				if not table.HasValue( t_Links, { case = v2.case, index = v2.index } ) then
				
					table.Add( t_Links, { case = v2.case, index = v2.index } )
					t_LinksHistory[ v2.case ][ v2.index ] = { case = v2.case, index = v2.index }
					
					table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
					
					if v2.case == t_Case or v2.index == t_Index then return table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ) end
					
				end
			end
			
			t_LinksHistory[ v.case ][ v.index ] = { }
		end
		
		return {}
	end
	
	//
	// Getting Path in Replicators Net Work to closest entTable element
	//
	function GetPatchWayToClosestEnt( startid, entTable )

		local t_Links = { }
		local t_LinksHistory = { }

		t_Links = { startid }
		t_LinksHistory[ startid ] = { startid }
		
		for k, v in pairs( t_Links ) do
			
			for k2, v2 in pairs( m_pathPoints[ v ].connection ) do
			
				if not table.HasValue( t_Links, v2 ) then
				
					table.Add( t_Links, { v2 } )
					t_LinksHistory[ v2 ] = { v2 }
					
					table.Add( t_LinksHistory[ v2 ], t_LinksHistory[ v ] )
					
					for k3, v3 in pairs( entTable ) do
					
						if m_pathPoints[ v2 ].pos:Distance( v3:GetPos() ) < 50 and not traceLine( v3:GetPos(), m_pathPoints[ v2 ].pos, replicatorNoCollideGroup_Witch ).Hit then
							
							v3.used = true
							return table.Add( table.Reverse( t_LinksHistory[ v2 ] ), { v3:GetPos() } ), v3

						end
					end
				end
			end

			t_LinksHistory[ v ] = { }
		end
		
		return {}
	end

	//
	// Getting Path in Replicators Net Work to closest metal spot
	//
	function GetPatchWayToClosestMetal( startid )

		local t_Links = { }
		local t_LinksHistory = { }

		t_Links = { startid }
		t_LinksHistory[ startid ] = { startid }
		
		for k, v in pairs( t_Links ) do
			
			for k2, v2 in pairs( m_pathPoints[ v ].connection ) do
			
				if not table.HasValue( t_Links, v2 ) then
					table.Add( t_Links, { v2 } )
					t_LinksHistory[ v2 ] = { v2 }
					
					table.Add( t_LinksHistory[ v2 ], t_LinksHistory[ v ] )
					
					for k3, v3 in pairs( m_metalPoints ) do
					
						if m_pathPoints[ v2 ].pos:Distance( v3.pos ) < 50 and not v3.used and not traceLine( v3.pos, m_pathPoints[ v2 ].pos, replicatorNoCollideGroup_Witch ).Hit then
							v3.used = true
							return table.Add( table.Reverse( t_LinksHistory[ v2 ] ), { v3.pos } ), k3
						end
						
					end
				end
			end

			t_LinksHistory[ v ] = { }
		end
		
		return {}
	end
	
	//
	// Getting Path in Replicators Net Work to closest dark spot
	//
	function GetPatchWayToClosestDark( startid )

		local t_Links = { }
		local t_LinksHistory = { }

		t_Links = { startid }
		t_LinksHistory[ startid ] = { startid }
		
		for k, v in pairs( t_Links ) do
			
			for k2, v2 in pairs( m_pathPoints[ v ].connection ) do
			
				if not table.HasValue( t_Links, v2 ) then
					table.Add( t_Links, { v2 } )
					t_LinksHistory[ v2 ] = { v2 }
					
					table.Add( t_LinksHistory[ v2 ], t_LinksHistory[ v ] )
					
					for k3, v3 in pairs( m_darkPoints ) do

						if m_pathPoints[ v2 ].pos:Distance( v3.pos ) < 50 and not v3.used and not traceLine( v3.pos, m_pathPoints[ v2 ].pos, replicatorNoCollideGroup_Witch ).Hit then
							v3.used = true
							return table.Add( table.Reverse( t_LinksHistory[ v2 ] ), { v3.pos } ), k3
						end
						
					end
				end
			end

			t_LinksHistory[ v ] = { }
		end
		
		return {}
	end
	
	//
	// Adding metal spot
	//
	function UpdateMetalPoint( _stringp, _amount )
		m_metalPoints[ _stringp ].amount = _amount

		net.Start( "update_metal_points" ) net.WriteString( _stringp ) net.WriteFloat( _amount ) net.Broadcast()
	end

	function AddMetalPoint( _stringp, _pos, _normal, _amount )
		m_metalPoints[ _stringp ] = { pos = _pos, normal = _normal, amount = _amount, used = false }
		m_metalPointsAsigned[ _stringp ] = true
		
		local t_tracer = traceQuick( _pos, -_normal * 20, replicatorNoCollideGroup_Witch )
				
		net.Start( "add_metal_points" )
			net.WriteString( _stringp )
			net.WriteTable( { pos = t_tracer.HitPos, normal = t_tracer.HitNormal, amount = _amount, used = false } )
		net.Broadcast()
	end
	
	//
	// Adding path point
	//
	function AddPathPoint( _pos, _connection )
	
		local merge = false
		local t_Mergered = false
		local returnID
		
		local t_pathPoints = {}
		
		for x = -1, 1 do
		for y = -1, 1 do
		for z = -1, 1 do

			local coord, sCoord = convertToGrid( _pos + Vector( x, y, z ) * 100, 100 )
			
			if m_pathPoints[ sCoord ] then table.Add( t_pathPoints, m_pathPoints[ sCoord ] ) print( x, y, z ) end
			
		end
		end
		end
		
		if table.Count( _connection ) > 0 then

			for k2, v2 in pairs( _connection ) do
			
				for k, v in pairs( t_pathPoints ) do
				
					if not merge and not ( v.case == v2.case and v.index == v2.index ) and v.pos:Distance( _pos ) < 50 and not traceLine( v.pos, m_pathPoints[ v2.case ][ v2.index ].pos, replicatorNoCollideGroup_Witch ).Hit then
					
						if not table.HasValue( m_pathPoints[ v.case ][ v.index ].connection, v2 ) then
						
							table.Add( m_pathPoints[ v.case ][ v.index ].connection, {{ case = v2.case, index = v2.index }} )
							table.Add( m_pathPoints[ v2.case ][ v2.index ].connection, {{ case = v.case, index = v.index }} )
							
							PrintMessage( HUD_PRINTTALK, v.case.."/"..v.index.."_"..v2.case.."/"..v2.index )
							
						end
						
						t_Mergered = true
						merge = true
						returnID = v
					end
				end
			end
			
		elseif table.Count( t_pathPoints ) > 0 then
		
			local t_Case, t_Index = FindClosestPoint( _pos, 0 )

			if t_Case != "" and t_Index > 0 then
			
				if m_pathPoints[ t_Case ][ t_Index ].pos:Distance( _pos ) < 50 and not traceLine( _pos, m_pathPoints[ t_Case ][ t_Index ].pos, replicatorNoCollideGroup_Witch ).Hit then
				
					merge = true
					returnID = { case = t_Case, index = t_Index }
					
				end
				
			end
		end
		
		if not merge then
			
			local coord, sCoord = convertToGrid( _pos, 100 )

			if m_pathPoints[ sCoord ] then
			
				m_ID = table.Count( m_pathPoints[ sCoord ] ) + 1
				
			else
			
				m_ID = 1
				m_pathPoints[ sCoord ] = {}
				
			end
			
			returnID = { case = sCoord, index = m_ID }
			
			table.Add( m_pathPoints[ sCoord ], {{ pos = _pos, connection = {}, case = sCoord, index = m_ID }} )
			
			for k, v in pairs( _connection ) do
			
				local result = traceLine( _pos, m_pathPoints[ v.case ][ v.index ].pos, replicatorNoCollideGroup_Witch )

				if not result.Hit then

					table.Add( m_pathPoints[ v.case ][ v.index ].connection, {{ case = sCoord, index = m_ID }} )
					table.Add( m_pathPoints[ sCoord ][ m_ID ].connection, {{ case = v.case, index = v.index }} )

					PrintMessage( HUD_PRINTTALK, m_ID )
					
				end
				
			end
			
		end
		
		//PrintTable( returnID )
		return returnID, t_Mergered
	end

	net.Receive( "rDark_points", function() m_darkPoints[ net.ReadString() ] = { pos = net.ReadVector() } end )
	
end // SERVER


hook.Add("Think", "replicator_keron", function( )
	
	if SERVER then
	end // SERVER
	
	if CLIENT then	
	end // CLIENT
	
end )

if CLIENT then

	function AddDarkPoint( _stringp, _pos )
	
		m_darkPoints[ _stringp ] = { pos = _pos, used = false }
		
		net.Start( "rDark_points" )
			net.WriteString( _stringp )
			net.WriteVector( _pos )
		net.SendToServer()
		
	end
	
end // CLIENT

hook.Add( "PostDrawTranslucentRenderables", "DrawQuadEasyExample", function()

	net.Receive( "draw_keron_network", function() m_pathPoints = net.ReadTable() end )
	
	net.Receive( "update_metal_points", function() m_metalPoints[ net.ReadString() ].amount = net.ReadFloat() end )
	net.Receive( "add_metal_points", function() m_metalPoints[ net.ReadString() ] = net.ReadTable() end )

	for k, v in pairs( m_pathPoints ) do
		local words = string.Explode( "_", k )
	
		render.SetMaterial( Material( "models/wireframe" ) )
		
		render.DrawBox( Vector( tonumber( words[ 1 ], 10 ), tonumber( words[ 2 ], 10 ), tonumber( words[ 3 ], 10 ) ), Angle( ), -Vector( 1, 1, 1 ) * 50, Vector( 1, 1, 1 ) * 50, Color( 255, 255, 255 ), false ) 

		for k2, v2 in pairs( v ) do

			render.SetMaterial( Material( "models/wireframe" ) )

			render.DrawBox( v2.pos, Angle( ), -Vector( 1, 1, 1 ), Vector( 1, 1, 1 ), Color( 255, 255, 255 ), false ) 
			
			for k3, v3 in pairs( v2.connection ) do
			
				if m_pathPoints[ v3.case ] then

					local p = m_pathPoints[ v3.case ][ v3.index ]
					local vec = ( v2.pos - p.pos ):Angle()
					
					render.DrawLine( v2.pos + vec:Right() / 2, p.pos + vec:Right() / 2, Color( 255, 255, 255 ), false )
					
				end
				//else table.remove( m_pathPoints[ v2.case ].connection, k2 ) end
				
			end
		end
	end
	
	for k, v in pairs( m_darkPoints ) do
	
		render.SetMaterial( Material( "models/wireframe" ) )
		render.SetColorModulation( 1, 0, 1 )
		render.SetBlend( 1 )
		
		render.DrawBox( v.pos, Angle( ), -Vector( 1, 1, 1 ), Vector( 1, 1, 1 ), Color( 25, 255, 255 ), true ) 
		
	end


	for k, v in pairs( m_metalPoints ) do
	
		render.SetMaterial( Material( "decals/antlion/shot5" ) )

		local t_Radius = ( 1 - math.exp( -( ( 1 - v.amount / 100 ) * 10 ) / 2 ) ) * 50
		
		render.DrawQuadEasy( v.pos, v.normal, t_Radius, t_Radius, Color( 255, 255, 255 ), t_Radius * 100 ) 
		//render.DrawBox( v.pos, v.angle, -Vector( 1, 1, 1 ), Vector( 1, 1, 1 ), Color( 0, 0, 255 ), false ) 
		
	end

	net.Receive( "debug_render_rerpl", function() m_DebugLink = net.ReadTable() end )
	
	for k, v in pairs( m_DebugLink ) do
	
		render.DrawBox( m_pathPoints[ v ].pos, Angle( 45, 45 ,45 ), -Vector( 9, 9, 9 ) * ( 1 + k / 100 ), Vector( 9, 9, 9 ) * ( 1 + k / 100 ), Color( 0, 0, 255 ), false ) 
		
	end
	
end )