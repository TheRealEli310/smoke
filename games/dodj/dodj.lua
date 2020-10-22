--[[

	Dodj
	By Dave-ee Jones

	Dodgeball in CC!

--]]

local t_TERM = {} -- Terminal dimensions and positioning
t_TERM.W, t_TERM.H = term.getSize()

local n_VERSION = "BETA"

--[[ CONFIGURATION ]]--

-- Ball update interval
local n_BALL_UPDATE_INTERVAL = 1 / 30 -- seconds / frames (smaller ratio = faster balls)
-- Player update interval
local n_PLAYER_UPDATE_INTERVAL = 1 / 4 -- seconds / frames (smaller ratio = faster movement)

-- Player settings (keybindings, sprites, etc.)
--- This is where you can add more players. Follow the same pattern as 1.
local t_PLAYER_SETTINGS = {
	[1] = {
		LEFT = keys.a, -- Left key (press to move left)
		UP = keys.w, -- Up key (press to move up)
		RIGHT = keys.d, -- Right key (press to move right)
		DOWN = keys.s, -- Down key (press to move down)
		ACTION = keys.leftShift, -- Action key (press to pickup/throw/drop)
		STOP = keys.z, -- Stop key (press while pressing a move key to not move)
		SPRITE = "\1", -- Sprite (1 character)
		TEAM = colors.cyan, -- Team, colour based. Defaults are blue and red.
		X = 3, -- X position at the start of the game and when players are reset
		Y = 3 -- Y position at the start of the game and when players are reset
	},
	[2] = {
		LEFT = keys.left,
		UP = keys.up,
		RIGHT = keys.right,
		DOWN = keys.down,
		ACTION = keys.o,
		STOP = keys.p,
		SPRITE = "\2",
		TEAM = colors.red,
		X = t_TERM.W - 3,
		Y = t_TERM.H - 3
	}
}

-- Default sprites for directions
local t_SPRITES = {
	LEFT = "\17",
	UP = "\30",
	RIGHT = "\16",
	DOWN = "\31",
	BALL = "\7"
}

local c_MAIN_BG = colors.black -- Background colour
local c_MAIN_FG = colors.white -- Foreground colour
local c_BOARD_BG = colors.gray -- Board's background colour

--[[ END CONFIGURATION ]]--

-- Metatables
local t_PLAYER = {}
local t_BALL = {}
t_PLAYER.__index = t_PLAYER
t_BALL.__index = t_BALL

-- Tables
local t_PLAYERS = {} -- Not to be confused with the metatable
local t_BALLS = {} -- Also not to be confused with the metatable
local t_BOARD = { -- t_BOARD dimensions and positioning, along with scoreboard
	X = 1,
	Y = 1,
	W = t_TERM.W - 1,
	H = t_TERM.H - 1,
	XMID = t_TERM.W / 2 + 1,
	TEAMS = {}
}

-- Help
local function f_HELP()
	printError("----------")
	printError("Dodj "..n_VERSION)
	printError("----------")
	printError("Setting up a player:")
	printError("- Edit Dodj")
	printError("- Scroll down to the 't_PLAYER_SETTINGS' table")
	printError("- Make an entry for each player missing")
	error("",0)
end

-- Draw all the players
local function f_PLAYERS_DRAW()
	for i=1,#t_PLAYERS do
		t_PLAYERS[i]:draw()
	end
end

-- Draw all the balls
local function f_BALLS_DRAW()
	for i=1,#t_BALLS do
		t_BALLS[i]:draw()
	end
end

-- Create the teams
local function f_TEAMS_CREATE()
	-- Create a team based on the players' colours
	local n_TEAMS = 0
	for i=1,#t_PLAYERS do
		if not t_BOARD.TEAMS[t_PLAYERS[i].TEAM] then
			-- Team doesn't exist, so let's create it
			t_BOARD.TEAMS[t_PLAYERS[i].TEAM] = {
				SCORE = 0,
				X = 0
			}
			n_TEAMS = n_TEAMS + 1
		end
	end
	local n_INDEX = 1
	if n_TEAMS == 2 then
		-- If there's only 2 teams, draw the text on either side of the board
		for k,v in pairs(t_BOARD.TEAMS) do
			if n_INDEX == 1 then
				t_BOARD.TEAMS[k].X = 2
			else
				t_BOARD.TEAMS[k].X = t_TERM.W - 2
			end
			n_INDEX = n_INDEX + 1
		end
	else
		-- Calculate distance between written text to calculate where we end up drawing them
		local n_XSTART = 2
		local n_DISTANCE_BETWEEN_TEAMS = (t_TERM.W - (n_XSTART*2))/(n_TEAMS-1)
		for k,v in pairs(t_BOARD.TEAMS) do
			t_BOARD.TEAMS[k].X = n_XSTART+n_DISTANCE_BETWEEN_TEAMS*(n_INDEX-1)
			n_INDEX = n_INDEX + 1
		end
	end
end

-- Add one to a team's score
local function f_TEAMS_SCORE(c_TEAM)
	t_BOARD.TEAMS[c_TEAM].SCORE = t_BOARD.TEAMS[c_TEAM].SCORE + 1
end

-- Draw the teams' score
local function f_TEAMS_DRAW()
	term.setBackgroundColor(c_BOARD_BG)
	for k,v in pairs(t_BOARD.TEAMS) do
		term.setTextColor(k)
		term.setCursorPos(t_BOARD.TEAMS[k].X,1)
		write(t_BOARD.TEAMS[k].SCORE)
	end
end

-- Draw the board
local function f_BOARD_DRAW()
	paintutils.drawBox(t_BOARD.X,t_BOARD.Y,t_BOARD.X+t_BOARD.W,t_BOARD.Y+t_BOARD.H,c_BOARD_BG)
	f_TEAMS_DRAW()
end

-- Reset the board
local function f_BOARD_RESET()
	f_BOARD_DRAW()
	-- Reset the players
	for i=1,#t_PLAYERS do
		t_PLAYERS[i]:clear()
		t_PLAYERS[i]:reset()
	end
	-- Reset the balls
	for i=1,#t_BALLS do
		t_BALLS[i]:clear()
		t_BALLS[i]:reset()
	end
	f_BALLS_DRAW()
	f_PLAYERS_DRAW()
	tm_BALL_UPDATE = os.startTimer(1)
end

-- Create a new player
function t_PLAYER:new(n_NUMBER)
	if not t_PLAYER_SETTINGS[n_NUMBER] then
		-- No settings for the player found
		printError("[ERROR] No settings for player "..n_NUMBER)
		printError("Type '"..shell.getRunningProgram().." help' for help.")
		error("",0)
	end
	local self = {
		NUMBER = n_NUMBER,
		DIRECTION = t_SPRITES.DOWN,
		ITEM = nil,
		ACTION_CD = false,
		CATCHING = false,
		STOPPED = false,
		KEY_STATES = {
			LEFT = false,
			UP = false,
			RIGHT = false,
			DOWN = false,
			ACTION = false,
			STOP = false
		}
	}
	-- This is where the t_PLAYER_SETTINGS table comes in handy!
	self.LEFT = t_PLAYER_SETTINGS[n_NUMBER].LEFT
	self.UP = t_PLAYER_SETTINGS[n_NUMBER].UP
	self.RIGHT = t_PLAYER_SETTINGS[n_NUMBER].RIGHT
	self.DOWN = t_PLAYER_SETTINGS[n_NUMBER].DOWN
	self.ACTION = t_PLAYER_SETTINGS[n_NUMBER].ACTION
	self.STOP = t_PLAYER_SETTINGS[n_NUMBER].STOP
	self.X = t_PLAYER_SETTINGS[n_NUMBER].X
	self.Y = t_PLAYER_SETTINGS[n_NUMBER].Y
	self.TEAM = t_PLAYER_SETTINGS[n_NUMBER].TEAM
	self.SPRITE = t_PLAYER_SETTINGS[n_NUMBER].SPRITE
	self.XSTART = self.X
	self.YSTART = self.Y
	setmetatable(self,t_PLAYER)
	return self
end

-- Move a player left
function t_PLAYER:moveLeft()
	self.DIRECTION = t_SPRITES.LEFT
	if not self.KEY_STATES.STOP and self.X > (t_BOARD.X + 1) then
		self:clear()
		self.X = self.X - 1
		if self.ITEM then
			self.ITEM:clear()
			self.ITEM.X = self.X
			self.ITEM.Y = self.Y + 1
		end
		f_BALLS_DRAW()
		f_PLAYERS_DRAW()
	end
	self:draw()
end

-- Move a player up
function t_PLAYER:moveUp()
	self.DIRECTION = t_SPRITES.UP
	if not self.KEY_STATES.STOP and self.Y > (t_BOARD.Y + 1) then
		self:clear()
		self.Y = self.Y - 1
		if self.ITEM then
			self.ITEM:clear()
			self.ITEM.X = self.X
			self.ITEM.Y = self.Y + 1
		end
		f_BALLS_DRAW()
		f_PLAYERS_DRAW()
	end
	self:draw()
end

-- Move a player right
function t_PLAYER:moveRight()
	self.DIRECTION = t_SPRITES.RIGHT
	if not self.KEY_STATES.STOP and self.X < (t_BOARD.X + t_BOARD.W - 1) then
		self:clear()
		self.X = self.X + 1
		if self.ITEM then
			self.ITEM:clear()
			self.ITEM.X = self.X
			self.ITEM.Y = self.Y + 1
		end
		f_BALLS_DRAW()
		f_PLAYERS_DRAW()
	end
	self:draw()
end

-- Move a player down
function t_PLAYER:moveDown()
	self.DIRECTION = t_SPRITES.DOWN
	if not self.KEY_STATES.STOP and self.Y < (t_BOARD.Y + t_BOARD.H - 2) then
		self:clear()
		self.Y = self.Y + 1
		if self.ITEM then
			self.ITEM:clear()
			self.ITEM.X = self.X
			self.ITEM.Y = self.Y + 1
		end
		f_BALLS_DRAW()
		f_PLAYERS_DRAW()
	end
	self:draw()
end

-- Reset a player
function t_PLAYER:reset()
	self.X = self.XSTART
	self.Y = self.YSTART
	self.STOPPED = false
	self.ACTION_CD = false
	self.ITEM = nil
	self.DIRECTION = t_SPRITES.DOWN
	self.CATCHING = false
end

-- Clear a player's drawn sprite
function t_PLAYER:clear()
	paintutils.drawPixel(self.X,self.Y,c_MAIN_BG)
	paintutils.drawPixel(self.X,self.Y+1,c_MAIN_BG)
end

-- Pickup/Throw/Drop something that a player holds
function t_PLAYER:action()
	if self.ITEM then
		-- Player is holding an item and wants to be rid of it
		if self.ITEM.SPRITE == t_SPRITES.BALL then
			-- It's a ball! THROW IT!
			self.ITEM.DIRECTION = self.DIRECTION
			self.ITEM.IS_THROWN = true
			self.ITEM.IS_CAUGHT = false
			self.ITEM = nil
		elseif self.ITEM.SPRITE == t_SPRITES.BLOCK then
			-- It's a block! (of some kind..) DROP IT!
			self.ITEM.IS_HELD = false
		end
	else
		self.CATCHING = true
	end
end

-- Draw a player
function t_PLAYER:draw()
	-- Draw player's sprite
	term.setTextColor(c_MAIN_FG)
	term.setBackgroundColor(self.TEAM)
	term.setCursorPos(self.X,self.Y)
	write(self.SPRITE)
	-- Draw player's direction/item
	term.setTextColor(c_MAIN_FG)
	term.setBackgroundColor(self.TEAM)
	term.setCursorPos(self.X,self.Y+1)
	if not self.ITEM then
		write(self.DIRECTION)
	else
		write(self.ITEM.SPRITE)
	end
end

-- Create a new ball
function t_BALL:new(n_NUMBER)
	local self = {
		NUMBER = n_NUMBER,
		DIRECTION = t_SPRITES.DOWN,
		IS_THROWN = false,
		IS_CAUGHT = false,
		TEAM = c_MAIN_FG,
		SPRITE = t_SPRITES.BALL
	}
	local _n_X = 0
	local _n_Y = 0
	local b_LOOKING = true
	while b_LOOKING do
		-- Looking for a spot to put the ball..
		_n_X = math.random(2,t_TERM.W-1)
		_n_Y = math.random(2,t_TERM.H-1)
		local _collision = false
		for i=1,#t_PLAYERS do
			if t_PLAYERS[i].XSTART == _n_X and t_PLAYERS[i].YSTART == _n_Y then
				-- Ah, can't use this position because it's the same as this player's starting position
				_collision = true
			end
		end
		for i=1,#t_BALLS do
			if t_BALLS[i].XSTART == _n_X and t_BALLS[i].YSTART == _n_Y then
				-- Ah, already a ball there
				_collision = true
			end
		end
		if not _collision then
			-- Okay, we found our spot
			b_LOOKING = false
		end
	end
	self.X = _n_X
	self.Y = _n_Y
	self.XSTART = _n_X
	self.YSTART = _n_Y
	setmetatable(self,t_BALL)
	return self
end

-- Calculate if the ball is touching a player
function t_BALL:collidedWithPlayer()
	for i=1,#t_PLAYERS do
		-- Okay, Player i, are you touching the ball?
		if self.X == t_PLAYERS[i].X and self.Y >= t_PLAYERS[i].Y and self.Y <= (t_PLAYERS[i].Y + 1) then
			-- Oh boi, you are!
			return t_PLAYERS[i]
		end
	end
	-- No one touching the ball!
	return false
end

-- Move a ball
function t_BALL:move()
	if self.IS_THROWN then
		-- Ahh, the ball is supposed to be moving
		if self.DIRECTION == t_SPRITES.LEFT then
			-- Moving left, eh?
			self:clear()
			if self.X > (t_BOARD.X + 1) then
				-- Okay, no wall, so let's keep going!
				self.X = self.X - 1
			else
				-- Oops, hit a wall, so let's rebound!
				self.DIRECTION = t_SPRITES.RIGHT
			end
		elseif self.DIRECTION == t_SPRITES.UP then
			-- Moving up in the world
			self:clear()
			if self.Y > (t_BOARD.Y + 1) then
				-- Okay, no ceiling, so let's keep moving up
				self.Y = self.Y - 1
			else
				-- Okay, hit the ceiling, let's fall
				self.DIRECTION = t_SPRITES.DOWN
			end
		elseif self.DIRECTION == t_SPRITES.RIGHT then
			-- Moving along the right path
			self:clear()
			if self.X < (t_BOARD.X + t_BOARD.W - 1) then
				-- Okay, it really is the right path
				self.X = self.X + 1
			else
				-- It's all gone left (including this ball)
				self.DIRECTION = t_SPRITES.LEFT
			end
		elseif self.DIRECTION == t_SPRITES.DOWN then
			-- Falling
			self:clear()
			if self.Y < (t_BOARD.Y + t_BOARD.H - 1) then
				-- We haven't hit the ground
				self.Y = self.Y + 1
			else
				-- Balls are bouncy, so they rebound off the ground
				self.DIRECTION = t_SPRITES.UP
			end
		end
		f_BALLS_DRAW()
		f_PLAYERS_DRAW()
	end
	if not self.IS_CAUGHT then
		local _other = self:collidedWithPlayer()
		if _other then
			-- Ball is sitting on a player
			if self.TEAM == c_MAIN_FG and _other.CATCHING then
				-- Player is eligible to catch the ball, so they do
				_other.ITEM = self
				self.TEAM = _other.TEAM
				self.IS_CAUGHT = true
				self.IS_THROWN = false
				_other:draw()
			elseif _other.CATCHING then
				-- Ball isn't white, but the player wants to catch the ball
				if (self.DIRECTION == t_SPRITES.DOWN and _other.DIRECTION == t_SPRITES.UP) or (self.DIRECTION == t_SPRITES.UP and _other.DIRECTION == t_SPRITES.DOWN) then
					-- Player is eligible to catch the ball, so they do
					_other.ITEM = self
					self.TEAM = _other.TEAM
					self.IS_CAUGHT = true
					self.IS_THROWN = false
					_other:draw()
				elseif (self.DIRECTION == t_SPRITES.LEFT and _other.DIRECTION == t_SPRITES.RIGHT) or (self.DIRECTION == t_SPRITES.RIGHT and _other.DIRECTION == t_SPRITES.LEFT) then
					-- Player is eligible to catch the ball, so they do
					_other.ITEM = self
					self.TEAM = _other.TEAM
					self.IS_CAUGHT = true
					self.IS_THROWN = false
					_other:draw()
				else
					-- Player isn't in any position to catch the ball, even though he tried..
					if self.TEAM ~= _other.TEAM and self.TEAM ~= c_MAIN_FG then
						-- Player just got hit!
						f_TEAMS_SCORE(self.TEAM)
						f_BOARD_RESET()
					end
				end
			else
				-- Player isn't trying to catch it and the ball isn't white
				if self.TEAM ~= _other.TEAM and self.TEAM ~= c_MAIN_FG then
					-- AND the ball isn't on the same team as the player, NOT GOOD!
					f_TEAMS_SCORE(self.TEAM)
					f_BOARD_RESET()
				end
			end
		end
	end
end

-- Reset a ball
function t_BALL:reset()
	self.X = self.XSTART
	self.Y = self.YSTART
	self.IS_THROWN = false
	self.IS_CAUGHT = false
	self.DIRECTION = t_SPRITES.DOWN
	self.TEAM = c_MAIN_FG
end

-- Clear a ball's drawn sprite
function t_BALL:clear()
	paintutils.drawPixel(self.X,self.Y,c_MAIN_BG)
end

-- Draw a ball
function t_BALL:draw()
	term.setTextColor(self.TEAM)
	term.setBackgroundColor(c_MAIN_BG)
	term.setCursorPos(self.X,self.Y)
	write(t_SPRITES.BALL)
end

-- Creating players based on arguments
local tArgs = { ... }
if tArgs[1] then
	if not tonumber(tArgs[1]) then
		-- Argument isn't a number, therefore we check for keywords
		if tArgs[1] == "help" then
			-- Argument was "help"
			f_HELP()
		else
			-- Unknown argument, error out
			error("[ERROR] Invalid argument: "..tArgs[1],0)
		end
	end
	-- Arguments found, let's create some players
	for i=1,tArgs[1] do
		t_PLAYERS[i] = t_PLAYER:new(i)
	end
	-- Lets create twice the amount of balls (max 10)
	for i=1,(tArgs[1]*2) do
		if #t_BALLS ~= 10 then
			t_BALLS[i] = t_BALL:new(i)
		else
			break
		end
	end
else
	-- No arguments found, default to 2 players
	for i=1,2 do
		t_PLAYERS[i] = t_PLAYER:new(i)
	end
	-- 2 players = 4 balls
	for i=1,4 do
		t_BALLS[i] = t_BALL:new(i)
	end
end

-- Setup the teams
f_TEAMS_CREATE()

-- Back to the drawing board..
local b_RUNNING = true
term.setBackgroundColor(c_MAIN_BG)
term.clear()
f_BOARD_DRAW()

-- Draw all the things before we start looping
f_BALLS_DRAW()
f_PLAYERS_DRAW()

-- Starts the timers
local tm_BALL_UPDATE = os.startTimer(1)
local tm_PLAYER_UPDATE = os.startTimer(1)

-- The Frightening Loop
while b_RUNNING do
	local e_EVENT, e_BUTTON, e_X, e_Y = os.pullEvent()
	if e_EVENT == "key" then
		-- WHICH PLAYER PRESSED A BUTTON, HUH?!
		for i=1,#t_PLAYERS do
			-- WAS IT YOU, i?!
			if e_BUTTON == t_PLAYERS[i].LEFT then
				-- AHA, NOW YOU CAN MOVE LEFT FOR WHAT YOU DID!
				t_PLAYERS[i]:moveLeft()
				t_PLAYERS[i].KEY_STATES.LEFT = true
			elseif e_BUTTON == t_PLAYERS[i].UP then
				-- AHA, NOW YOU CAN MOVE UP FOR WHAT YOU DID!
				t_PLAYERS[i]:moveUp()
				t_PLAYERS[i].KEY_STATES.UP = true
			elseif e_BUTTON == t_PLAYERS[i].RIGHT then
				-- AHA, NOW YOU CAN MOVE RIGHT FOR WHAT YOU DID!
				t_PLAYERS[i]:moveRight()
				t_PLAYERS[i].KEY_STATES.RIGHT = true
			elseif e_BUTTON == t_PLAYERS[i].DOWN then
				-- AHA, NOW YOU CAN MOVE DOWN FOR WHAT YOU DID!
				t_PLAYERS[i]:moveDown()
				t_PLAYERS[i].KEY_STATES.DOWN = true	
			elseif e_BUTTON == t_PLAYERS[i].STOP then
				-- AHH, YOU WANT TO STOP DO YOU? FINE.
				t_PLAYERS[i].KEY_STATES.STOP = true
			elseif e_BUTTON == t_PLAYERS[i].ACTION then
				-- WHAT? YOU WANT TO DO SOMETHING? GO AHEAD.
				t_PLAYERS[i]:action()
				t_PLAYERS[i].KEY_STATES.ACTION = true
			end
		end
	elseif e_EVENT == "key_up" then
		-- WHICH PLAYER PRESSED A BUTTON, HUH?!
		for i=1,#t_PLAYERS do
			-- WAS IT YOU, i?!
			if e_BUTTON == t_PLAYERS[i].LEFT then
				-- AHA, NOW YOU CAN STAY RIGHT THERE!
				t_PLAYERS[i].KEY_STATES.LEFT = false
			elseif e_BUTTON == t_PLAYERS[i].UP then
				-- STOP UPPING THEN!
				t_PLAYERS[i].KEY_STATES.UP = false
			elseif e_BUTTON == t_PLAYERS[i].RIGHT then
				-- AHA, THE RIGHT CHOICE!
				t_PLAYERS[i].KEY_STATES.RIGHT = false
			elseif e_BUTTON == t_PLAYERS[i].DOWN then
				-- AHA, NOW YOU CAN STAY RIGHT THERE!
				t_PLAYERS[i].KEY_STATES.DOWN = false
			elseif e_BUTTON == t_PLAYERS[i].STOP then
				-- AHH, YOU DON'T WANT TO STOP DO YOU? FINE.
				t_PLAYERS[i].KEY_STATES.STOP = false
			elseif e_BUTTON == t_PLAYERS[i].ACTION then
				-- WHAT? YOU DON'T WANT TO DO SOMETHING?
				t_PLAYERS[i].CATCHING = false
				t_PLAYERS[i].KEY_STATES.ACTION = false
			end
		end
	elseif e_EVENT == "timer" then
		if e_BUTTON == tm_BALL_UPDATE then
			-- BALLS ARE BEING MOVED, GET READY..
			for i=1,#t_BALLS do
				-- WANNA MOVE, i? THIS IS YOUR CHANCE.
				t_BALLS[i]:move()
			end
			tm_BALL_UPDATE = os.startTimer(n_BALL_UPDATE_INTERVAL)
		elseif e_BUTTON == tm_PLAYER_UPDATE then
			-- PLAYERS ARE BEING MOVED, GET READY..
			for i=1,#t_PLAYERS do
				if t_PLAYERS[i].KEY_STATES.LEFT then
					-- WHEN YOU GONNA STOP HEADING LEFT?
					t_PLAYERS[i]:moveLeft()
				elseif t_PLAYERS[i].KEY_STATES.UP then
					-- MOVIN' ON UP!
					t_PLAYERS[i]:moveUp()
				elseif t_PLAYERS[i].KEY_STATES.RIGHT then
					-- RIGHT, RIGHT!
					t_PLAYERS[i]:moveRight()
				elseif t_PLAYERS[i].KEY_STATES.DOWN then
					-- DOWN WE GO!
					t_PLAYERS[i]:moveDown()
				end
				tm_PLAYER_UPDATE = os.startTimer(n_PLAYER_UPDATE_INTERVAL)
			end
		end
	end
end