faceDir = function(dir)
  dir = dir % 4
  if dir < 0 then dir = dir + 4
  while me.facing != dir
    me.left
    wait(0.1)
  end while
end function

faceLoc = function(x,y)
  dx = x - me.position.x
  dy = y - me.position.y
  if abs(dx) > abs(dy) then
    if dx > 0 then target=1 else target=3
    else
    if dy > 0 then target=2 else target=0
  end if
  faceDir target
end function

goTo = function(x,y)
  print "Going to: " + x + ", " + y
  while me.position.x != x or me.position.y != y
    faceLoc x, y
    if me.ahead and not me.ahead.passable then me.clearAhead
    me.forward
  end while
end function

refillWater = function(startX,startY,startFace)
  goTo 71,27
  faceDir 2
  me.select "Watering Can"
  wait(0.1)
  me.useTool
  goTo startX, startY
  faceDir startFace
end function

tendAhead = function
  info = me.ahead
  if info != null then
    if not info.passable then
      me.clearAhead
      info = me.ahead
    end if
    if info != null and info.passable then
      if info.type == "Grass" then
        while info.type == "Grass"
          me.select "Scythe"
          me.useTool
          info = me.ahead
          if info == null then break
        end while
      end if
    end if
  end if // yes, this is looking worse :D
  if info == null then
    me.select "hoe"
    me.useTool
    info = me.ahead
  end if
  if info.type == "HoeDirt" and info.dry then
    me.select "Watering Can"
    if me.inventory[me.currentToolIndex].waterLeft == 0 then
      refillWater me.position.x, me.position.y, me.facing
    end if
    me.useTool
  end if
end function

tendGarden = function
  xrange = range(50, 70)
  yrange = range(21, 27)
  for y in yrange
    goTo xrange[0] - 1, y
    faceLoc xrange[0], y
    for x in xrange
      tendAhead
      me.forward
    end for
  end for
  me.forward
  faceDir 2
end function

tendGarden