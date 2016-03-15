function love.conf(t)
	t.window.width = 800
	t.window.height = 600
	t.window.resizable = false
end

function love.load()
	gameState = 0 --0 = Start, 1 = In Progress, 2 = Ended

	-- One meter is 32px in physics engine
	love.physics.setMeter( 32 )

	-- Create physics world with no gravity
	world = love.physics.newWorld(0,0,true)

	-- Set collision callbacks
	world:setCallbacks(beginContact,endContact)

	-- Create walls
	wallPos = {{400,5,800,10},{795,300,10,600},{400,595,800,10},{5,300,10,600}}
	walls = {}

	for i = 1, #wallPos, 1 do
		walls[i] = {
			body = love.physics.newBody(world, wallPos[i][1], wallPos[i][2], "static"),
			shape = love.physics.newRectangleShape(0, 0, wallPos[i][3], wallPos[i][4])
		}
		walls[i].fixture = love.physics.newFixture(walls[i].body, walls[i].shape)
		walls[i].fixture:setFriction(0)
		walls[i].fixture:setUserData("Wall")
	end

	-- bottom wall is "game over"
	walls[3].fixture:setUserData("Ground")

	-- Create blocks
	blocks = {}
	local numRow = 3
	local numCol = 6
	local rowHeight = 50
	local colWidth = 100
	local spacing = 10

	for i = 1, numRow, 1 do
		for k = 1, numCol, 1 do
			blocks[(i-1)*numCol+k] = {
				body = love.physics.newBody(world, 50+(k*colWidth), 50+(i*rowHeight), "static"),
				shape = love.physics.newRectangleShape(0, 0, colWidth-spacing, rowHeight-spacing)
			}
			blocks[(i-1)*numCol+k].fixture = love.physics.newFixture(blocks[(i-1)*numCol+k].body, blocks[(i-1)*numCol+k].shape)
			blocks[(i-1)*numCol+k].fixture:setFriction(0)
			blocks[(i-1)*numCol+k].fixture:setUserData("Block")
		end
	end

	-- Create paddle at (300, 500) dynamic
	paddle = {
		body = love.physics.newBody(world,300,500,"static"),
		shape = love.physics.newRectangleShape(0, 0, 200, 10)
	}
	paddle.fixture = love.physics.newFixture(paddle.body, paddle.shape)
	paddle.fixture:setFriction(0)
	paddle.fixture:setUserData("Paddle")
	paddle_width = 100

	-- Load the image of the ball
	--ball = love.graphics.newImage("love-ball.png")

	-- Create a Body for the circle
	-- Attach a shape to the body
	-- Create a fixture between body and shape
	circle = {
		body = love.physics.newBody(world, 400, 400, "dynamic"),
		shape = love.physics.newCircleShape(0,0,32)
	}
	circle.fixture = love.physics.newFixture(circle.body, circle.shape)
	circle.fixture:setFriction(0)
	circle.fixture:setUserData("Ball")
end

function love.update(dt)
	-- if game is over, do not run update
	if gameState == 2 then
		return
	end

	-- if no blocks left, end game
	if #blocks == 0 then
		gameState = 2
		return
	end

	-- move paddle based on last directional key pressed
	if lastKey == "left" then
		if paddle.body:getX() - paddle_width - 150*dt > 10 then
			paddle.body:setX(paddle.body:getX() - 150*dt)
		end
	elseif lastKey == "right" then
		if paddle.body:getX() + paddle_width + 150*dt < 790 then
			paddle.body:setX(paddle.body:getX() + 150*dt)
		end
	end

	world:update(dt)
end

function love.draw()
	-- determine text to be displayed on screen based on state of game
	if gameState == 0 then
		love.graphics.print("Press Space To Start", 200, 300, 0, 3, 3)
	elseif gameState == 2 and #blocks == 0 then
		love.graphics.print("Game Won!", 300, 300, 0, 3, 3)
	elseif gameState == 2 and #blocks > 0 then
		love.graphics.print("Game Over!", 300, 300, 0, 3, 3)
	end

	-- draw walls
	for i = 1, #walls, 1 do
		love.graphics.polygon("line", walls[i].body:getWorldPoints(walls[i].shape:getPoints()))
	end

	-- draw blocks
	for i = 1, #blocks, 1 do
		if blocks[i].body then
			love.graphics.polygon("line", blocks[i].body:getWorldPoints(blocks[i].shape:getPoints()))
		end
	end

	love.graphics.polygon("line", paddle.body:getWorldPoints(paddle.shape:getPoints()))
	love.graphics.circle("line", circle.body:getX(), circle.body:getY(), circle.shape:getRadius())
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "left" and gameState ~= 2 then
		lastKey = "left"
	elseif key == "right" and gameState ~= 2 then
		lastKey = "right"
	elseif key == " " and gameState == 0 then
		gameState = 1
		circle.body:setLinearVelocity(0,150)
	end
end

function love.keyreleased(key)
	if gameState ~= 2 and (key == "left" or key == "right") then
		if love.keyboard.isDown("left") then
			lastKey = "left"
		elseif love.keyboard.isDown("right") then
			lastKey = "right"
		else
			lastKey = nil
		end
	end
end

function beginContact(a, b, c)
	if inContact then
		return
	end

	inContact = true
	local nX, nY = c:getNormal()

	local bObj, other
	if a:getUserData() == "Ball" then
		bObj = a
		other = b
	elseif b:getUserData() == "Ball" then
		bObj = b
		other = a
	end

	if bObj:getUserData() == "Ball" then
		local bVelX, bVelY = bObj:getBody():getLinearVelocity()

		if nX > 0.1 or nX < -0.1 then
			bVelX = -bVelX
		end

		if nY > 0.1 or nY < -0.1 then
			bVelY = -bVelY
		end

		if other:getUserData() == "Paddle" then
			if lastKey == "left" then
				bVelX = bVelX - 50
			elseif lastKey == "right" then
				bVelX = bVelX + 50
			end
		elseif other:getUserData() == "Ground" then
			gameState = 2
		end

		bObj:getBody():setLinearVelocity(bVelX, bVelY)
	end
end

function endContact(a, b, c)
	inContact = false
	local blockObj = nil
	if a:getUserData() == "Block" then
		blockObj = a
	elseif b:getUserData() == "Block" then
		blockObj = b
	end

	if blockObj ~= nil then
		for i=1, #blocks, 1 do
			if blockObj:getBody():getX() == blocks[i].body:getX() and blockObj:getBody():getY() == blocks[i].body:getY() then
				blocks[i].fixture:destroy()
				table.remove(blocks, i)
				break
			end
		end
	end
end