
function EFFECT:Init( data )

	self.Start = data:GetOrigin()
	self.Direction = data:GetNormal()
	self.Emitter = ParticleEmitter( self.Start )
		
	for i = 1, 10 do
	
		local vec = VectorRand()
		local p = self.Emitter:Add( "sprites/light_glow02_add", self.Start )

		p:SetDieTime( math.random( 1, 2 ) )
		p:SetStartAlpha( 0 )
		p:SetEndAlpha( math.random( 200, 255 ) )
		p:SetStartSize( math.random( 1, 3 ) )
		p:SetEndSize( 0 )
		p:SetRoll( math.Rand( -10, 10 ) )
		p:SetRollDelta( math.Rand( -10, 10 ) )
		p:SetVelocity( vec * 10 + self.Direction * 10 )
		p:SetGravity( Vector( 0, 0, -100 ) )
		p:SetColor( 100, 255, 100 )
		p:SetCollide( true )
		
	end

	for i = 1, 10 do
	
		local vec = VectorRand()
		local p = self.Emitter:Add("particle/smokesprites_000" .. math.random( 1, 9 ), self.Start + vec )

		p:SetDieTime( math.random( 1, 2 ) )
		p:SetStartAlpha( 0 )
		p:SetEndAlpha( math.random( 200, 255 ) )
		p:SetStartSize( math.random( 1, 3 ) )
		p:SetEndSize( 0 )
		p:SetRoll( math.Rand( -10, 10 ) )
		p:SetRollDelta( math.Rand( -10, 10 ) )
		p:SetVelocity( vec * 10 + self.Direction * 10 )
		p:SetGravity( Vector( 0, 0, -100 ) )
		p:SetColor( 100, 255, 100 )
		p:SetCollide( true )
		
	end
	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

	//render.SetMaterial( Material( "sprites/light_ignorez" ) )
	//render.DrawSprite( self.Start, self.size, self.size, Color( 255, 100, 0, 50 ) )
	
end
