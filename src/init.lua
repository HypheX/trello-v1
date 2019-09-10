--[[
    Name: init.lua
    From roblox-trello v2

    Description: Front-Ends for Trello Entity management


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

-- Module Global Version
local VERSION = "2.0.0-dev.7"
local HTTP = require(script.TrelloHttp)
local CLASS = require(script.TrelloClass)

-- TrelloEntity Metatable
local META_TrelloEntity = {
    __tostring = "TrelloEntity",

    __metatable = "TrelloEntity",

    -- Hopefully this will not throw false positives. Functions that will eventually work with this should be aware.
    __index = function(_, index)
        error("[TrelloEntity]: Attempted to index non-existant property "..tostring(index)..".", 0)
    end,

    -- This can be bypassed using rawset, but at that point it's not on us
    __newindex = function(_, index, _)
        error("[TrelloEntity]: Attempted to set non-existant property "..tostring(index)..".", 0)
    end
}

local TrelloEntity = {}
local function toURL(value)
    local returns = ""

    if type(value) == "table" then
        for i = 1, #value - 1 do
            returns = returns .. tostring(value[i]) .. ","
        end
        return returns .. tostring(value[#value])
    else
        return tostring(value)
    end
end

--[[**
    Creates a new TrelloEntity, that represents a Trello account.

    @param [t:String] key Your developer key. Cannot be empty or nil.
    @param [t:Variant<String,nil>] token Your developer token. Optional if you're only READING from a PUBLIC board.
    @param [t:Boolean] pedantic_assert Whether an error should be thrown (instead of a warning) if key validation fails.

    @returns [t:Variant<TrelloEntity,nil>] A new TrelloEntity, representing your account. Returns nil if key validation fails (with pedantic_assert disabled).
**--]]
function TrelloEntity.new(key, token, pedantic_assert)
    if not key or key == "" then
        error("[TrelloEntity.new]: You need a key to authenticate yourself!", 0)
    end

    local AUTH_STR = "key="..key..((token and token ~= "") and "&token="..token or "")

    -- Perform authentication validation and assertation
    print("https://api.trello.com/1/members/me?" .. AUTH_STR)
    local dummyRequest
    if token and token ~= "" then
        dummyRequest = HTTP.Request("https://api.trello.com/1/members/me?" .. AUTH_STR, HTTP.HttpMethod.GET)
    else
        -- We don't have a particular user authenticated, so we'll resort to this - a public board.
        dummyRequest = HTTP.Request("https://api.trello.com/1/boards/5d6f8ec6764c2112a27e3d12?" .. AUTH_STR, HTTP.HttpMethod.GET)
    end

    if not dummyRequest.LuaSuccess then
        error("[TrelloEntity.new]: Fatal Error has been thrown by HttpService (" .. dummyRequest.SystemResponse .. ").", 0)
    else
        print("[TrelloEntity.new]: Measured Latency: " .. tostring(math.ceil(dummyRequest.Latency*1000)) .. "ms.")
        for _,l in pairs ({5, 3, 2, 1, 0.5}) do
            if dummyRequest.Latency >= l then
                warn("[TrelloEntity.new]: API Latency is higher than " .. tostring(l*1000) .. "ms!")
                break
            end
        end

        if dummyRequest.StatusCode == 200 then
            print("[TrelloEntity.new]: All OK.")
        elseif dummyRequest.StatusCode >= 500 then
            warn("[TrelloEntity.new]: Bad Server Response - " .. tostring(dummyRequest.StatusCode) .. ". Service might be experiencing issues.")
        elseif dummyRequest.StatusCode >= 400 then
            if pedantic_assert then
                error("[TrelloEntity.new]: Bad Client Request - " .. tostring(dummyRequest.StatusCode) .. ". Check your authentication keys!", 0)
            end
            warn("[TrelloEntity.new]: Bad Client Request - " .. tostring(dummyRequest.StatusCode) .. ". Check your authentication keys!")
            return nil
        end
    end

    -- All tests passed, we can make the TrelloEntity.
    local TrelloEntity = {}
    TrelloEntity.Auth = AUTH_STR
    TrelloEntity.User = dummyRequest.Body.fullName

    --[[**
        Creates a syntactically correct URL for use within the module. Authentication is automatically appended.

        @param [t:String] page The page that you wish to request to. Base URL is https://api.trello.com/1/ (page cannot be empty).
        @param [t:Variant<Dictionary,nil>] query_fields A dictionary (indexes must to be strings) with any extra fields you want to query the API with.
        
        @returns [t:String] A URL string you can make requests to.
    **--]]
    function TrelloEntity:MakeURL(page, query_fields)
        if not page or page == "" then
            error("[TrelloEntity.MakeURL]: Page argument is empty!", 0)
        end

        local newURL = "https://api.trello.com/1/"

        -- It's likely that we're going to mix '/page' with 'page' so better handle both cases
        if page:sub(1, 1) == "/" then
            newURL = newURL .. page:sub(2, -1)
        else
            newURL = newURL .. page
        end

        -- Tie the knot with the authentication and return
        if not query_fields then
            return newURL .. "?" .. self.Auth
        end

        -- Add query parameters and return
        local queryURL = "?"
        for field, value in pairs (query_fields) do
            if type(field) ~= "string" then
                error("[TrelloEntity.MakeURL]: query_fields must to be a dictionary and all indexes must to be strings!", 0)
            end

            if type(value) == "table" and not value[0] then
                -- This is a dictionary
                for i, v in pairs(value) do
                    queryURL = queryURL .. field .. "/" .. i .. "=" .. toURL(v) .. "&"
                end
            else
                queryURL = queryURL .. field .. "=" .. toURL(value) .. "&"
            end
        end

        return newURL .. queryURL .. self.Auth
    end

    if token and token ~= "" then
        print("[TrelloEntity.new]: Successfully authenticated as " .. TrelloEntity.User .. ". Welcome!")
    else
        print("[TrelloEntity.new]: Added new userless entity.")
        warn("[TrelloEntity.new]: This entity can only read public boards.")
    end
    return setmetatable(TrelloEntity, META_TrelloEntity)
end

warn("Using Roblox-Trello, VERSION " .. VERSION .. ".")

CLASS.TrelloEntity = TrelloEntity
return CLASS