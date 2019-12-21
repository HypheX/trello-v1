--[[
    Name: trello-init.server.lua
    From roblox-trello v2

    Description: Performs some testing on the Trello v2 features.


    Copyright (c) 2019 Luis, David Duque

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
--]]

local Trello = require(game.ServerScriptService.Trello)

wait(2)

-----------------------------------------------------
-- MAKE SURE TO CHANGE THESE WITH YOUR OWN VALUES! --
-- API KEY: https://trello.com/app-key --------------
-- GENERATE API TOKEN: https://trello.com/1/authorize?expiration=never&name=Roblox%20Trello&scope=read,write&response_type=token&key={YourAPIKey}
-----------------------------------------------------
local id = Trello.Client.new("d31703e3e5ea5587ca5800f86e407182", "3d1ca0af245d02941d32acf8c4bc6f1075aada1f459522069d67bb59008982f9", true)

local board1 = Trello.Board.new("My Awesome Private Board", false, id)
print(board1.RemoteId)
local board2 = Trello.Board.new("My Awesome Public Board", true, id)
print(board2.RemoteId)

local myAwesomeBoard = Trello.Board.fromRemote(board1.RemoteId, id)
for i, v in pairs(myAwesomeBoard) do
    print(i .. ": ".. tostring(v))
end

board1:Delete()
board2:Delete()

local boardIWillEdit = Trello.Board.new("This", nil, id)
print("Waiting 3 seconds until starting to edit...")
wait(3)
print("Editing.")
print(boardIWillEdit.RemoteId)

boardIWillEdit.Name = "Maybe this name is cooler!"
boardIWillEdit.Description = "Hey, what about we oof?"
boardIWillEdit.Public = true
print("Changing name and description, making it public.")
boardIWillEdit:Commit()

wait(10)
boardIWillEdit.Public = false
print("Making it private again.")
boardIWillEdit:Commit()

wait(3)
boardIWillEdit.Closed = true
print("Closing the board.")
boardIWillEdit:Commit()

wait(3)
boardIWillEdit.Closed = false
print("Reopening the board.")
boardIWillEdit:Commit()
boardIWillEdit:Commit()
print("Force committing this time.")
boardIWillEdit:Commit(true)

wait(3)
print("Deleting the board.")
boardIWillEdit:Delete()

-- Was also board1, should return a 404.
myAwesomeBoard:Delete()

-- Test fetching all boards
wait(3)

local boards = Trello.Board.fetchAllFrom(id)

for i, v in pairs (boards) do
    warn("Board " .. tostring(i))
    for bin, bval in pairs (v) do
        print(tostring(bin).." = "..tostring(bval))
    end
end

warn("TEST END.")