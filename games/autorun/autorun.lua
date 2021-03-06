x = 1
y = 2
vel = 0
score = 0
platforms = {}

term.setBackgroundColor(colors.lightBlue)
term.setTextColor(colors.white)
term.clear()
function createPlatforms() 
  pl = 3
  size = 51/pl
  height = math.random(1, 19)
  for i=0,pl do
    height = height+math.random(8)-4
    for j=0,size do
      platforms[(size*i)+j] = height
    end
    platforms[i*size] = -1  
  end
end
function drawBuildings()
  term.setBackgroundColor(colors.red)
  for i=1, #platforms do
    if(platforms[i] ~= -1) then
    term.setCursorPos(i-1, platforms[i])
    term.write("-")
    for j=platforms[i], 19 do
      term.setCursorPos(i-1, j)
      term.write(" ")
    end
    end
  end
  term.setBackgroundColor(colors.lightBlue)
end
function restart()
  x = 1
  y = 2
  term.setBackgroundColor(colors.lightBlue)
  term.clear()
  createPlatforms()
  drawBuildings()
end
function grounded()
  if(x < #platforms) then
    if(y >= platforms[x]-1) and (platforms[x] ~= -1) then return true end
  end
  return false
end
function Char()
  sleep(0.2)
  term.setCursorPos(x, y)
  term.write(" ")
  if(grounded()) then x = x+1 end
  if(vel > 0) then x = x+1 end
  if(vel <= 0) then
      y = y+1
    else
      y = y-1
      vel = vel-1
  end
  if(x < #platforms) then
    if(y > platforms[x]-1) and (platforms[x] ~= -1) then y = platforms[x]-1 end
  end
  if(y > 19) then restart() end
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.blue)
  term.write(" ")
  term.setCursorPos(1, 19)
  --term.write("Pos:"..tostring(x).." "..tostring(y))
  term.setBackgroundColor(colors.lightBlue)
  
end
function keyPressed()
  event, key = os.pullEvent("key")
  if(key == keys.space) and (grounded()) then
    term.setCursorPos(x,y)
    term.write(" ")
    vel = 3
  end
end
createPlatforms()
drawBuildings()
while true do
  parallel.waitForAny(Char, keyPressed)
  sleep(0.1)
end