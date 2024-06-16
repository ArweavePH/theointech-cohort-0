--[[
    HELPERS
--]]

-- It would be good to have this in the APM, but for now, we'll put it here
local enum = function(keys)
    local Enum = {}
    for _, value in ipairs(keys) do
        Enum[value] = {}
    end
    return Enum
end

--[[
    GLOBAL VARIABLES
--]]
local GameModeEnum = enum { "NotStarted", "Waiting", "Playing" }
local MoveEnum = enum { "Rock", "Paper", "Scissors" }
GameMode = GameMode or GameModeEnum.NotStarted
StateChangeTime = StateChangeTime or undefined

-- State durations (in milliseconds)
WaitTime = WaitTime or 1 * 60 * 1000 -- 1 minute
GameTime = GameTime or 1 * 60 * 1000 -- 1 minute
Now = Now or undefined               -- Current time, updated on every message.

-- Players waiting to join the next game and their payment status.
Waiting = Waiting or {}
-- Active players and their game states.
Players = Players or {}
-- Active teams
Teams = Teams or {}
-- Processes subscribed to game announcements.
Listeners = Listeners or {}
-- Minimum number of players required to start a game. 6 because it's 3v3
MinimumPlayers = MinimumPlayers or 4
-- Maximum number of players required to start a game. 6 because it's 3v3
MaximumPlayers = MaximumPlayers or 4

-- Default player state initialization.
PlayerInitState = PlayerInitState or {}

--[[
    FUNCTIONS
--]]

-- Starts the waiting period for players to become ready to play.
function startWaitingPeriod()
    GameMode = GameModeEnum.Waiting
    StateChangeTime = Now + WaitTime
    announce("Started-Waiting-Period", "The game is about to begin!")
    print('Starting Waiting Period')
end

-- Initialize player state.
function playerInitState()
    return {
        move = undefined,
        score = 0,
    }
end

-- Starts the game if there are enough players.
function startGamePeriod()
    local registeredPlayers = 0
    for player, hasRegistered in pairs(Waiting) do
        if hasRegistered then
            registeredPlayers = registeredPlayers + 1
        end
    end

    if registeredPlayers < MinimumPlayers then
        announce("Not-Enough-Players", "Not enough players registered! Restarting...")
        for player, hasRegistered in pairs(Waiting) do
            if hasRegistered then
                Waiting[player] = false
            end
        end
        startWaitingPeriod()
        return
    end

    GameMode = GameModeEnum.Playing
    StateChangeTime = Now + GameTime
    for player, hasRegistered in pairs(Waiting) do
        Players[player] = playerInitState()
    end

    -- Divide players into two teams and put them on the Teams table
    local team1 = {}
    local team2 = {}
    local team1Count = 0
    for player, _ in pairs(Players) do
        if team1Count < MinimumPlayers / 2 then
            table.insert(team1, player)
            team1Count = team1Count + 1
            ao.send({
                Target = player,
                Action = "Team-Formation",
                Data = "The game is starting! You belong to Team 1"
            })
        else
            table.insert(team2, player)
            ao.send({
                Target = player,
                Action = "Team-Formation",
                Data = "The game is starting! You belong to Team 2"
            })
        end
    end
    -- add the teams to the Teams table
    table.insert(Teams, team1)
    table.insert(Teams, team2)

    announce("Started-Game", "The game has started. Good luck!")
    print("Game Started....")
end

-- Determine the winners, ends the current game and starts a new one.
function determineWinners()
    print("Game Over")

    -- Determine the winners by comparing moves of players in each team with the same index
    local team1 = Teams[1]
    local team2 = Teams[2]
    local team1Score = 0
    local team2Score = 0
    for i = 1, #team1 do
        local player1 = team1[i]
        local player2 = team2[i]
        local move1 = Players[player1].move
        local move2 = Players[player2].move
        if move1 == MoveEnum.Rock and move2 == MoveEnum.Scissors then
            team1Score = team1Score + 1
        elseif move1 == MoveEnum.Scissors and move2 == MoveEnum.Paper then
            team1Score = team1Score + 1
        elseif move1 == MoveEnum.Paper and move2 == MoveEnum.Rock then
            team1Score = team1Score + 1
        elseif move2 == MoveEnum.Rock and move1 == MoveEnum.Scissors then
            team2Score = team2Score + 1
        elseif move2 == MoveEnum.Scissors and move1 == MoveEnum.Paper then
            team2Score = team2Score + 1
        elseif move2 == MoveEnum.Paper and move1 == MoveEnum.Rock then
            team2Score = team2Score + 1
        end
    end

    Players = {}
    Teams = {}

    local winningTeam = 1
    if team1Score == team2Score then
        announce("Game-Ended", "The game has ended in a draw.")
        startWaitingPeriod()
        return
    elseif team1Score < team2Score then
        winningTeam = 2
    end

    announce("Game-Ended", "The game has ended. Congratulations! Winning team is Team " .. winningTeam .. "!")
    startWaitingPeriod()
end

--[[
    HANDLERS
--]]

-- Handler for cron messages, manages game state transitions.
Handlers.add(
    "Game-State-Timers",
    function(Msg)
        return "continue"
    end,
    function(Msg)
        Now = Msg.Timestamp
        if GameMode == GameModeEnum.NotStarted then
            startWaitingPeriod()
        elseif GameMode == GameModeEnum.Waiting then
            if Now > StateChangeTime then
                startGamePeriod()
            end
        elseif GameMode == GameModeEnum.Playing then
            if Now > StateChangeTime then
                determineWinners()
            end
        end
    end
)

-- Registers new players for the next game and subscribes them for event info.
Handlers.add(
    "Register",
    Handlers.utils.hasMatchingTag("Action", "Register"),
    function(Msg)
        if #Players == MaximumPlayers then
            ao.send({
                Target = Msg.From,
                Action = "Error",
                Data = "Maximum number of players reached."
            })
            return
        end
        if Msg.Mode ~= "Listen" and Waiting[Msg.From] == undefined then
            Waiting[Msg.From] = false
        end
        removeListener(Msg.From)
        table.insert(Listeners, Msg.From)
        ao.send({
            Target = Msg.From,
            Action = "Registered"
        })
        announce("New Player Registered", Msg.From .. " has joined in waiting.")
    end
)

-- Handle move of the players and update the player state
Handlers.add(
    "Move",
    Handlers.utils.hasMatchingTag("Action", "Move"),
    function(Msg)
        Players[Msg.From].move = Msg.Move
        ao.send({
            Target = Msg.From,
            Action = "Move-Received"
        })
        announce("Player ", Msg.From .. " has made a move.")
    end
)

-- Unregisters players and stops sending them event info.
Handlers.add(
    "Unregister",
    Handlers.utils.hasMatchingTag("Action", "Unregister"),
    function(Msg)
        removeListener(Msg.From)
        ao.send({
            Target = Msg.From,
            Action = "Unregistered"
        })
    end
)

-- Retrieves the current game state.
Handlers.add(
    "GetGameState",
    Handlers.utils.hasMatchingTag("Action", "GetGameState"),
    function(Msg)
        local json = require("json")
        local TimeRemaining = StateChangeTime - Now
        local GameState = json.encode({
            GameMode = GameMode,
            TimeRemaining = TimeRemaining,
            Players = Players,
        })
        ao.send({
            Target = Msg.From,
            Action = "GameState",
            Data = GameState
        })
    end
)

-- Alerts users regarding the time remaining in each game state.
Handlers.add(
    "AnnounceTick",
    Handlers.utils.hasMatchingTag("Action", "Tick"),
    function(Msg)
        local TimeRemaining = StateChangeTime - Now
        if GameMode == "Waiting" then
            announce("Tick", "The game will start in " .. (TimeRemaining / 1000) .. " seconds.")
        elseif GameMode == "Playing" then
            announce("Tick", "The game will end in " .. (TimeRemaining / 1000) .. " seconds.")
        end
    end
)
