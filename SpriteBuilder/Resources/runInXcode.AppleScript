tell application "Xcode"
	ignoring application responses
		activate
		# open "/Users/nickyweber/dev/Apportable/SBProjects/update.spritebuilder/update.xcodeproj"
		open "ABSOLUTE_PATH_TO_PROJECT"
	end ignoring
end tell

tell application "System Events"
	tell application process "Xcode"
		click menu item "Run" of menu 1 of menu bar item "Product" of menu bar 1
	end tell
end tell
