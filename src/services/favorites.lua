local json = require("lib.json")
local esplay = require("services.esplay")

-- Favorites are EmulationStation's own (`favorite` in gamelist.xml), so marking one here shows in
-- ES too: it goes through ES's web API (esplay.setFavorite), and ES writes the gamelist a few
-- minutes later. Until it has, the change is also kept in favorites.json in the save folder and
-- applied over the gamelist at startup; an entry is dropped once the gamelist agrees (or the game is
-- gone). That also keeps favorites on backends without ES, like the desktop's mock one.
local favorites = {}

favorites.FILE = "favorites.json"
favorites.fs = love and love.filesystem -- read and write; tests swap in their own

local pending -- game id -> true (a favorite) or false (not one)

local function load()
  if not pending then
    local ok, data = pcall(json.decode, favorites.fs.read(favorites.FILE) or "")
    pending = ok and type(data) == "table" and data or {}
  end
  return pending
end

local function save()
  favorites.fs.write(favorites.FILE, json.encode(pending))
end

-- Forgets what was read, for tests.
function favorites.reset()
  pending = nil
end

-- At startup: applies the changes ES may not have saved yet to `games` (every game in the library),
-- and forgets the ones the gamelists already have.
function favorites.apply(games)
  local changes, seen = load(), {}
  for _, game in ipairs(games) do
    local on = changes[game.id]
    if on ~= nil then
      seen[game.id] = true
      if (game.favorite == true) == on then changes[game.id] = nil else game.favorite = on or nil end
    end
  end
  for id in pairs(changes) do
    if not seen[id] then changes[id] = nil end
  end
  save()
end

-- The hint for X on a game: marking it, or unmarking it.
function favorites.hint(game)
  return game.favorite and "X: unfavorite   " or "X: favorite   "
end

-- Marks `game` as a favorite, or unmarks it; returns whether it's one now.
function favorites.toggle(backend, game)
  local on = not game.favorite
  game.favorite = on or nil
  load()[game.id] = on
  save()
  esplay.setFavorite(backend, game, on)
  return on
end

return favorites
