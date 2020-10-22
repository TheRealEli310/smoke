--[[
**************
     8-Ball
 Recreated in CC
**************

By: houseofkraft
]]--

-- Disables Native Terminating
os.pullEvent = os.pullEventRaw

local responses = {
  "Yes",
  "No",
  "Doubt it",
  "Certainly",
  "Without a doubt",
  "Ask me again",
  "I don't understand you",
  "RIP",
  "Uhhhh...",
  "Okay then...",
  "Yeah sure",
  "Get me out of here!!!"
}

local function writeColored( sColor, sText, newLine )
  if newLine == nil then
    newLine = true
  end
  
  local oc = term.getTextColor()
  
  if term.isColor and term.isColor() then
    term.setTextColor(sColor)
  else
    term.setTextColor(colors.white)
  end
    
  write(sText)
    
  if newLine then
    print()
  end  
  term.setTextColor(oc)
end

term.clear()
term.setCursorPos(1,1)

writeColored(colors.yellow, "The famous game of 8-Ball... now in CC!", true)
writeColored(colors.yellow, "Type in a question and have it answered!", true)
print()

local function init()
  while true do
    writeColored(colors.yellow, "8ball> ", false)
    local sText = read()
    textutils.slowPrint(responses[math.random(1, #responses)])
  end
end

local function onTerminate()
  while true do
    local event = os.pullEventRaw()
    if event == "terminate" then
      -- Draw the custom screen
      term.clear()
      term.setCursorPos(1,1)
      writeColored(colors.blue, "I hope you enjoyed the game!")
      writeColored(colors.blue, "Make sure to check 'houseofkraft' on the CC forums!")
      break
    end
  end
end

parallel.waitForAny(onTerminate, init)