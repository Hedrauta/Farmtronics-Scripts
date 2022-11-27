// This is the Farmtronic text editor.  It is imported and invoked
// via the `edit` command defined in /sys/startup.ms.

import "stringUtil" // needed for automatic indent

data = [""]
scrollY = 0
scrollX = 0

screenH = 20  // screen height, in rows
screenW = 40  // screen width, in columns
screenLines = screenH - 1  // number of lines of text we can show
TAB = char(9)

cursorX = 0  // line number, from 0 to data.len-1
cursorY = 0  // column number, from 0 to data[cursorX].len
idealCursorX = cursorX

pal = {}  // "palette"
pal.background = "#222222"
pal.text = "#CCCCCC"
pal.cursor = "#CCCCFF"
pal.topBar = "#AAAAAA"
pal.topBarText = "#8888CC"

cutLines = []
linesCutFromLineNum = null

lineLen = function(lineNum)
	if lineNum < data.len then return data[lineNum].len
	return 0
end function

drawTopBar = function()
	text.backColor = pal.topBar
	text.color = pal.topBarText
	text.row = screenH-1; text.column = 0
	print " " + _sourceFile
	lstr = str(cursorY + 1)
	print " " * (screenW - 13 - lstr.len - text.column)
	print "^H: Help   L" + lstr
	print " " * (screenW - text.column)
end function

printLine = function(row, s)
	if s.len < screenW then
		s = s + " " * (screenW - s.len)
	else if s.len > screenW then
		s = s[:screenW]
	end if
	text.row = row; text.column = 0
	if row > 0 then
		print s
	else
		print s[:-1]
		text.setCell screenW-1, 0, s[-1]
		text.setCellColor screenW-1, 0, text.color
		text.setCellBackColor screenW-1, 0, text.backColor
	end if
end function

refreshRow = function(screenRow)
	if screenRow < 0 or screenRow >= screenLines then return
	text.backColor = pal.background
	text.color = pal.text
	i = scrollY + screenLines - 1 - screenRow
	text.row = screenRow; text.column = 0
	if i < data.len then
		s = data[i][scrollX:]
	else
		s = ""
	end if
	printLine screenRow, s
	if i == cursorY then outer.cursorShown = false
end function

refreshLine = function(lineNum)
	y = lineNum - scrollY  // (rows from the top)
	row = screenLines - 1 - y
	refreshRow row
end function

refreshDisplay = function()
	for row in range(screenLines-1, 0)
		refreshRow row
	end for
	outer.cursorShown = false
	text.backColor = color.clear
end function

showCursor = function(showIt=true)
	if cursorY < scrollY or cursorY >= scrollY + screenLines then return
	if cursorX < scrollX then return
	x = cursorX - scrollX
	if x >= screenW then return
	y = screenLines - 1 - cursorY + scrollY
	if showIt then
		text.setCellColor x, y, color.black
		text.setCellBackColor x, y, pal.cursor
	else
		text.setCellColor x, y, pal.text
		text.setCellBackColor x, y, pal.background
	end if
	outer.cursorShown = showIt
end function

hideCursor = function(); showCursor false; end function

limitCursor = function()
	if cursorY < 0 then
		outer.cursorY = 0
		outer.cursorX = 0
	else if cursorY > data.len then
		outer.cursorY = data.len
	end if
	if cursorX < 0 then
		outer.cursorX = 0
	else if cursorX > lineLen(cursorY) then
		outer.cursorX = lineLen(cursorY)
	end if
end function

scrollCursorIntoView = function()
	scrolled = false
	while cursorY < scrollY
		outer.scrollY = scrollY - floor(screenLines/2)
		if scrollY < 0 then outer.scrollY = 0
		scrolled = true
	end while
	while cursorY >= scrollY + screenLines
		outer.scrollY = scrollY + floor(screenLines/2)
		maxScroll = data.len - floor(screenLines/2)
		if scrollY > maxScroll then outer.scrollY = maxScroll
		scrolled = true
	end while
	while cursorX < scrollX
		outer.scrollX = scrollX - screenW/2
		if scrollX < 0 then outer.scrollX = 0
		scrolled = true
	end while
	while cursorX >= scrollX + screenW
		outer.scrollX = scrollX + screenW/2
		scrolled = true
	end while
	if scrolled then refreshDisplay
end function

isWhiteOrPunc = function(c)
	return c <= " " or "()[]{}.,?!+-*/\|@#$%^&=".indexOf(c) != null
end function

nextWord = function(dir)
	// Advance the cursor to the next word boundary in the
	// given direction (within the current line).
	if cursorY >= data.len then return
	s = data[cursorY]
	x = cursorX
	if dir < 0 then
		// skip whitespace
		while x > 0 and isWhiteOrPunc(s[x-1])
			x = x - 1
		end while
		// then back up until we hit whitespace again
		while x > 0 and not isWhiteOrPunc(s[x-1])
			x = x - 1
		end while
	else
		// skip whitespace
		while x+1 < s.len and (x+1==s.len or isWhiteOrPunc(s[x+1]))
			x = x + 1
		end while
		// then advance until we hit whitespace again
		while x < s.len and (x==s.len or not isWhiteOrPunc(s[x]))
			x = x + 1
		end while
	end if
	outer.cursorX = x
end function

cutLine = function
	if cursorY != linesCutFromLineNum then
		outer.cutLines = []
		outer.linesCutFromLineNum = cursorY
	end if
	if cursorY >= data.len then return "End of File"
	cutLines.push data[cursorY]
	data.remove cursorY
	refreshDisplay
	if cutLines.len == 1 then return "Cut (1 Line)"
	return "Cut (" + cutLines.len + " Lines)"
end function

pasteLines = function
	for line in cutLines
		data.insert cursorY, line
		outer.cursorY = cursorY + 1
	end for
	scrollCursorIntoView
	refreshDisplay
	if cutLines.len == 1 then return "Paste (1 Line)"
	return "Paste (" + cutLines.len + " Lines)"
end function

showHelp =  function
	text.color = pal.text; text.backColor = "#4F1CDBFF"
	text.clear; text.delimiter = char(13)
	text.row = 19; text.column = 0
	text.inverse = true
	print " "*8 + "Farmtronics Text Editor" + " "*9
	text.inverse = false
	print "Hold the Control key and press a letter"
	print "to perform one of the functions below."
	print "Example: "
	print "   ^Q means hold Contol and press Q."
	print
	funcs = [
		"^A: Go to start of line",
		"^E: Go to end of line",
		"^U: Page up",
		"^D: Page down",
		"^K: Cut line(s)",
		"^V: Paste line(s)",
		"^H: View this help",
		"^Q: Quit"]
	text.delimiter = ""
	for func in funcs
		parts = func.split(":")
		text.column = 3; text.inverse = true
		print parts[0] + " "
		text.inverse = false
		print parts[1] + char(13)
	end for
	text.row = 0
	print "(Press any key to continue.)"
	key.get
	text.backColor = color.clear
	refreshDisplay
end function

showCommand = function(keyPress, desc)
	refreshRow 0
	s = keyPress
	if desc then s = s + ": " + desc
	text.row = 0
	text.column = screenW - s.len
	text.color = color.black
	text.backColor = "#FFFFAA"
	print s[:-1]
	text.setCell screenW-1, 0, s[-1]
	text.setCellColor screenW-1, 0, text.color
	text.setCellBackColor screenW-1, 0, text.backColor
end function	

handleControlKey = function(k)
	kcode = k.code
	desc = "(undefined)"

	anyAlt = key.pressed("left alt") or key.pressed("right alt")
	anyShift = key.pressed("left shift") or key.pressed("right shift")

	keyPress = "^" + char(64 + kcode)
	if kcode > 31 then keyPress = "^" + char(kcode)
	if anyShift then keyPress = "Shift-" + keyPress

	// Want to customize your key bindings?  Change
	// the code below, and the help in showHelp above.
	if keyPress == "^A" then  // ctrl-A (start of line)
		desc = "LineStart"
		outer.cursorX = 0
	else if keyPress == "^E" then // ctrl-E (end of line)
		desc = "LineEnd"
		outer.cursorX = lineLen(cursorY)
	else if keyPress == "^H" then  // help
		showHelp
		desc = "Help"
	else if keyPress == "^U" then	// Page Up
		desc = "PageUp"
		outer.cursorY = outer.cursorY - screenLines
	else if keyPress == "^D" then	// Page Down
		desc = "PageDown"
		outer.cursorY = outer.cursorY + screenLines
	else if keyPress == "^K" then  // Cut line
		desc = cutLine
	else if keyPress == "^V" then  // Paste lines
		desc = pasteLines
	else if keyPress == "^Q" then  // Escape or Ctrl+X
		desc = "Quit"
		outer.quitting = true
	end if
	
	if keyPress then showCommand keyPress, desc
end function

handleKey = function(k, fakeControl=false)
	kcode = k.code
	ignoreControl = [91,93,123,125].indexOf(kcode, false) // will ignore Control-Key on brackets and braces
	anyCtrl = ( key.pressed("left ctrl") or key.pressed("right ctrl") or fakeControl ) and not ignoreControl
	anyAlt = key.pressed("left alt") or key.pressed("right alt")
	byWord = anyAlt or anyCtrl
	hideCursor
	
	// Careful with 17-20: these are generated by the arrow keys,
	// which may be used in conjunction with Control, but still
	// should be treated differently than ^Q, ^R, etc.
	isArrowKey = false
	if kcode >= 17 and kcode <= 20 then
		keys = ["left", "right", "up", "down"]
		if key.pressed(keys[kcode-17]) then isArrowKey = true
	end if
	
	if anyCtrl and not isArrowKey then
		handleControlKey k
	else if kcode == 17 then  // left
		keyPress = ""
		outer.cursorX = cursorX - 1
		curYInCo = prepareLine(outer.data[cursorY])[0]
		// case left: if in front of indent, go to previous line end
		if cursorX < curYInCo and cursorY > 0 then
			outer.cursorY = cursorY - 1
			outer.cursorX = lineLen(cursorY)
		end if
		if byWord then nextWord -1
		outer.idealCursorX = cursorX
	else if kcode == 18 then  // right
		keyPress = ""
		outer.cursorX = cursorX + 1
		if cursorX > lineLen(cursorY) and cursorY < data.len then
			curYInCo = prepareLine(outer.data[cursorY+1])[0] 
			// case right: if next line has indent, move cursor to end of indent in next line
			outer.cursorY = cursorY + 1
			outer.cursorX = curYInCo
		end if
		if byWord then nextWord 1
		outer.idealCursorX = cursorX
	else if kcode == 19 then  // up
		keyPress = ""
		if byWord then amount = screenLines else amount = 1
		outer.cursorY = cursorY - amount
		outer.cursorX = idealCursorX
	else if kcode == 20 then  // down
		keyPress = ""
		if byWord then amount = screenLines else amount = 1
		outer.cursorY = cursorY + amount
		outer.cursorX = idealCursorX
	else if kcode == 10 then  // return
		keyPress = ""
		indentCount = 0
		if cursorY >= data.len then
			data.push ""
		else
			data.insert cursorY+1, data[cursorY][cursorX:]
			if data[cursorY].len > 0 then
				// count current line indent (aka "starting spaces")
				while data[cursorY][indentCount] == " "
					indentCount = indentCount + 1
					if indentCount == data[cursorY].len then break
				end while
			end if
		end if
		data[cursorY] = data[cursorY][:cursorX]
		outer.cursorY = cursorY + 1
		outer.cursorX = 0
		if indentCount > 0 then // import existing "starting spaces from previous line
			for i in range(1,indentCount)
				data[cursorY] = data[cursorY][:cursorX] + " " + data[cursorY][cursorX:]
				outer.cursorX = cursorX +1
			end for
		end if
		automaticIndent
		refreshDisplay
	else if kcode == 127 then  // forward-delete
		keyPress = ""
		if cursorX >= data[cursorY].len then
			cuY1InCo = prepareLine(data[cursorY +1])[0]
			if cuY1InCo > 0 then
				data[cursorY] = data[cursorY] + data[cursorY+1][cuY1InCo:]
				data.remove cursorY + 1
				refreshDisplay
			else if cursorY < data.len-1 then
				data[cursorY] = data[cursorY] + data[cursorY+1]
				data.remove cursorY + 1
				refreshDisplay
			end if
		else
			startPos = cursorX
			outer.cursorX = cursorX + 1
			if byWord then nextWord 1
			data[cursorY] = data[cursorY][:startPos] + data[cursorY][cursorX:]
			outer.cursorX = startPos
			refreshLine cursorY
		end if
	else if kcode == 8 then  // backspace
		keyPress = ""
		doBS = true
		if cursorX > 0 then
			endPosX = cursorX
			endPosY = cursorY
			if outer.cursorX == (prepareLine(outer.data[outer.cursorY])[0]) then
				cu1YLen = data[cursorY - 1].len
				cuYInCo = prepareLine(outer.data[outer.cursorY])[0]
				data[cursorY - 1] = data[cursorY - 1][:cu1YLen] + data[cursorY][cuYInCo:]
				data.remove cursorY
				outer.cursorY = cursorY - 1
				outer.cursorX = cu1YLen
				doBS = false
			else if outer.data[cursorY][cursorX - 2] == " " and data[cursorY][cursorX - 1] == " " then 
				outer.cursorX = cursorX - 2
			else 
				outer.cursorX = cursorX - 1
			end if
			if byWord then nextWord -1
			if doBS then
				data[cursorY] = data[cursorY][:cursorX] + data[cursorY][endPosX:]
			end if
			automaticIndent
			refreshDisplay
		else if cursorY > 0 then
			x = data[cursorY-1].len
			if cursorY < data.len then
				data[cursorY-1] = data[cursorY-1] + data[cursorY]
				data.remove cursorY
			end if
			outer.cursorY = cursorY - 1
			outer.cursorX = x
			automaticIndent
			refreshDisplay
		end if
	else if kcode == 27 then  // Escape
		outer.quitting = true
	else if k >= " " or kcode == 9 then  // printable key or TAB
		if kcode == 9 then k = "  "
		if cursorY >= data.len then
			data.push k
		else if not data[cursorY] then
			data[cursorY] = k
		else
			data[cursorY] = data[cursorY][:cursorX] + k + data[cursorY][cursorX:]
		end if
		if kcode == 9 then outer.cursorX = cursorX + 2 else outer.cursorX = cursorX + 1
		automaticIndent
		refreshLine cursorY
	end if

	limitCursor
	scrollCursorIntoView
	drawTopBar
	showCursor	
end function

update = function()
	wantCursor = (time % 1 < 0.75)
	if wantCursor != cursorShown then showCursor wantCursor
	if key.available then
		handleKey key.get
	else if key.pressed("left ctrl") or key.pressed("right ctrl") then
		for c in "1234567890[]/=\;-',.`"
			if key.pressed(c) then
				while key.pressed(c); yield; end while
				handleControlKey c
			end if
		end for
	else if key.pressed("page up") then
		while key.pressed("page up"); yield; end while
		handleKey "U", true
	else if key.pressed("page down") then
		while key.pressed("page down"); yield; end while
		handleKey "D", true	
	end if
	realignCursor(outer.cursorY, outer.cursorX) // will move cursor at the end of indent
end function

// editText: main entry point.
// Pass in a list of strings representing the text to edit.
editText = function(textToEdit)
	if textToEdit == null then textToEdit = []
	if textToEdit.len == 0 then textToEdit.push ""
	outer.data = textToEdit
	// We don't handle tabs properly yet, so let's just:
	for i in data.indexes; data[i] = data[i].replace(TAB, "  "); end for
	origColor = text.color
	origBackColor = text.backColor
	text.backColor = color.clear
	text.delimiter = ""
	clear
	drawTopBar
	refreshDisplay
	
	if not env.hasIndex("bootOpts") then env.bootOpts = {}
	env.bootOpts.controlC = false	// disable Control-C to break
	
	outer.quitting = false
	while not quitting
		yield
		update
	end while
	key.clear

	env.bootOpts.controlC = true	// re-eable Control-C to break

	text.delimiter = char(13)
	text.color = origColor
	text.backColor = origBackColor
	text.clear
	text.row = 1
end function

// Upcoming Code is for automatic Indent on lines,
// Written by GitHub:Hedrauta // Discord:H3draut3r#6722

// Short explanation: 
// "Indent" in the next lines context is meant for 2 spaces

// realignCursor: used in @@update: will move cursor at the end of the indent, 
// if moved up or down into a indent (left/right acts differently) 
realignCursor = function(curY, curX)
	curYInCo = prepareLine(outer.data[curY])[0]
	if curX < curYInCo then
		outer.cursorX = curYInCo
	end if
end function

// prepareLine: Used for upcomming functions to "prepare" the content,
// + counting the "starting spaces" and returns both, spaces-count + 
// the line with removed spaces from start and end.
// Makes is easier to detect '.endsWith("then")' or 'else'
prepareLine = function(uList)
    // for whole line preparing, 
    // returns list with list of line, + counter
    prepList = uList // copy content, keep old untouched
		if prepList.hasIndex("//") then // does line contain a comment?
			prepList = prepList[:prepList.indexOf("//")] // keep everything except the comment
		end if
		pList = prepList.split("")
    pCount = 0
		if pList != null then
			if pList.len > 0 then // remove space from start, and count occurences
					while pList[0] == " "
							pList.remove(0)
							pCount = pCount + 1
							if pList.len == 0 then break // break if content gets "null"
					end while
			end if
			if pList.len > 0 then
				if pList.len > 4 then // keyword "else" or other possible,
						// remove spaces at the end, no count
						while pList[pList.len - 1] == " "
								pList.remove(pList.len - 1) 
						end while
				end if
			end if
		end if
    return [pCount, pList.join("")]
end function

// adjustNextLinesIndent: Used for upcomming functions to 'adjust' "Indent" for every next line
// seriously, the name is probably obvious
adjustNextLinesIndent = function(startingLine)
	dataLen = outer.data.len - 1 // get count of lines (-1 for "index")
	startingIndent = 0
	if outer.data[startingLine] != null then
		startingIndent = prepareLine(outer.data[startingLine])[0]
	end if
	if startingLine < dataLen then
		for editLine in range(startingLine + 1, dataLen)
			splODeL = outer.data[editLine].split("")
			ANLInCount = prepareLine(outer.data[editLine])[0]
			if ANLInCount < startingIndent + 2 then
				while ANLInCount < startingIndent + 2
					splODeL.insert(0," ")
					ANLInCount = ANLInCount + 1
					if outer.cursorY == editLine then outer.cursorX = outer.cursorX + 1
				end while
			else if ANLInCount > startingIndent + 2 then
				while ANLInCount > startingIndent + 2
					splODeL.remove(0)
					ANLInCount = ANLInCount - 1
					if outer.cursorY == editLine then outer.cursorX = outer.cursorX - 1
				end while
			end if
			outer.data[editLine] = splODeL.join("")
			refreshLine editLine
		end for
	end if
end function

// removeNextLinesIndent: In case of "end if/for/while/function", we have
// to remove "indents", so the current line will match the corresponding
// line's indent and every other line will removed one indent
removeNextLinesIndent = function(startingLine, targetLine, notElse=true)
	dataLen = outer.data.len - 1
	startingIndent = 0
	targetIndent = 0
	splOuterData = outer.data[targetLine].split("")
	if startingLine != targetLine then
		startingIndent = prepareLine(outer.data[startingLine])[0]
		targetIndent = prepareLine(outer.data[targetLine])[0]
		if targetIndent > startingIndent then
			while targetIndent > startingIndent
				splOuterData.remove(0)
				targetIndent = prepareLine(splOuterData.join(""))[0]
				if outer.cursorY == targetLine then outer.cursorX = outer.cursorX - 1
			end while
			outer.data[targetLine] = splOuterData.join("")
			refreshLine targetLine
		end if
	end if
	if targetLine < dataLen and notElse then
		for editLine in range(targetLine + 1, dataLen)
			splODeL = outer.data[editLine].split("")
			while prepareLine(splODeL.join(""))[0] > prepareLine(outer.data[startingLine])[0]
				splODeL.remove(0)
				if outer.cursorY == editLine then outer.cursorX = outer.cursorX - 1
				if splOuterData.len == 0 then break
			end while
			outer.data[editLine] = splODeL.join("")
			refreshLine editLine
		end for
	end if
end function

automaticIndent = function()
	// prepare empty list of lists, one for each "condition"
	mapCond = {"ifLines":[], "forLines":[], "whileLines":[], "functionLines":[]}
	if outer.data.len > 1 then // indent works only on 2+ lines
		for lineNumber in range(0, outer.data.len - 1)
			lineString = prepareLine(outer.data[lineNumber])[1]
			if lineString.len > 2 then
				if lineString.startsWith("else") or lineString.startsWith("else if") then
					listConLine = mapCond.ifLines[mapCond.ifLines.len - 1]
					removeNextLinesIndent(listConLine, lineNumber, false)
				else if lineString.startsWith("if") or lineString.endsWith("if") then
					if lineString.endsWith("then") or lineString.endsWith("else") then
						if lineNumber < outer.data.len - 1 then
							adjustNextLinesIndent(lineNumber)
							mapCond.ifLines.push(lineNumber)
						end if
					else if lineString.contains("end if") then
						if lineNumber < outer.data.len - 1 then
							if mapCond.ifLines.hasIndex(lineNumber) then
								listConLine = mapCond.ifLines.pop
								removeNextLinesIndent(lineNumber, lineNumber)
							else
								listConLine = mapCond.ifLines.pop
								removeNextLinesIndent(listConLine, lineNumber)
							end if
						end if
					end if
				else if lineString.contains("for") then
					if lineString.contains("end for") then
						listConLine = mapCond.forLines
						removeNextLinesIndent(listConLine, lineNumber)
					else
						adjustNextLinesIndent(lineNumber)
						mapCond.forLines.push(lineNumber)
					end if
				else if lineString.startsWith("while") or lineString.endsWith("while") then
					if lineString.contains("end while") then
						listConLine = mapCond.whileLines.pop
						removeNextLinesIndent(listConLine, lineNumber)
					else
						adjustNextLinesIndent(lineNumber)
						mapCond.whileLines.push(lineNumber)
					end if
				else if lineString.contains("function") then
					if lineString.contains("end function") then
						listConLine = mapCond.functionLines.pop
						removeNextLinesIndent(listConLine, lineNumber)
					else
						adjustNextLinesIndent(lineNumber)
						mapCond.functionLines.push(lineNumber)
					end if
				end if
			end if
		end for
	end if
end function

// Back to game-Code
if locals == globals then
	editText _source
end if