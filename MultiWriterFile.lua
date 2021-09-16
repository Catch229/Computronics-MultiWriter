local tape = peripheral.find("tape_drive")
local header

if not tape then
	print("This program requires a tape drive.")
	return
elseif not tape.isReady() then
	print("Please insert a tape.")
end

tape.stop()
tape.seek(-tape.getSize())
tape.stop()

function downloadFile(url)
	gitFile = http.get(url, nil, true)
	song = gitFile.readAll()
	gitFile.close()
	return song
end

function confirm(msg)
  term.clear()
  term.setCursorPos(1,1)
  print(msg)
  print("Type `y` to confirm, `n` to cancel.")
  repeat
    local response = read()
    if response and response:lower():sub(1, 1) == "n" then
      print("Canceled.")
      return false
    end
  until response and response:lower():sub(1, 1) == "y"
  return true
end

function calculateNextPos(h)
	if #h > 0 then
		return h[#h].startpos + h[#h].length
	else
		return 2049
	end
end

function headerToTrackNames(h)
	temp = {}
	for k, v in pairs(h) do
		--table.insert(temp, string.sub(v.text, 1, 18))
		table.insert(temp, v.text)
	end
	return temp
end

function addToHeader(fn, sp, ln)
	temp = {text = fn, 
			startpos = sp, 
			length = ln}
	table.insert(header , temp)
	tape.seek(-tape.getSize())
	tape.write(42)
	tape.write(textutils.serialize(header))
end

function getHeaderFromTape()
	tape.seek(-tape.getSize())
	tape.seek(1)
	local h = ""
	for i = 0, 15, 1 do
		h = h .. tape.read(128)
	end
	tape.seek(-tape.getSize())
	return textutils.unserialize(h)
end

function clearHeader()
	tape.stop()
	tape.seek(-tape.getSize())
	for i=0,2048,1 do
		tape.write(0)
	end
end

loopTitle = "***     Found songs on tape. Songs include...   ***"

while true do
	header = getHeaderFromTape()
	term.clear()
	term.setCursorPos(1,1)
	
	if header then
		print(loopTitle)
		print("---------------------------------------------------")
		print("       File Name         |           Length        ")
		print("---------------------------------------------------")
		for i=1,#header,1 do
			term.setCursorPos(1, i+4)
			term.write(" "..i..". "..header[i].text)
			term.setCursorPos(26, i+4)
			term.write(string.format("| %19.2f", (header[i].length/6000)/60).." MIN")
		end
		print("\n")
	else
		print("***   No songs found on tape. Starting empty.   ***\n")
		clearHeader()
		header = {}
	end
	
	idEntered = false
	while not idEntered do
		print("Please enter a file name with links:")
		songFile = read()
		print("Is the file correct? (y/n):")
		answer = read()
		if answer == "y" then
			idEntered = true
		end
	end
	
	f = fs.open(songFile)
	songName = fs.readLine()
	while(songName)
		fileName = songName
		song = downloadFile(f.readLine())

		if song then
			startPos = calculateNextPos(header)
			length = #song
			tape.stop()
			tape.seek(-tape.getSize())
			tape.seek(startPos)
			tape.write(song)
			term.clear()
			term.setCursorPos(1,1)
			addToHeader(filename, startPos, length)
		else
		end
		songName = f.readLine()
	end
	
	loopTitle = "***          File added! Songs include...       ***"
end