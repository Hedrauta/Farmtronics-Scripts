// Will show the pressed key on screen

while true
  if key.available then
    yield
    print "Key: |" + key.get + "| Code: " + key.get.code
  end if
  yield
end while

// KILL IT WITH CTRL+C