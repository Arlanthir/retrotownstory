local favorites = require("services.favorites")
local json = require("lib.json")

describe("favorites", function()
  local files
  before_each(function()
    files = {}
    favorites.fs = { read = function(path) return files[path] end, write = function(path, text) files[path] = text end }
    favorites.reset()
  end)

  local backend = {} -- no EmulationStation to tell

  it("marks and unmarks a game, keeping the change until the gamelist has it", function()
    local game = { id = "nes:smb" }
    assert.is_true(favorites.toggle(backend, game))
    assert.is_true(game.favorite)
    assert.same({ ["nes:smb"] = true }, json.decode(files[favorites.FILE]))
    assert.is_false(favorites.toggle(backend, game))
    assert.is_nil(game.favorite)
  end)

  it("applies changes the gamelist doesn't have yet, after a restart", function()
    files[favorites.FILE] = json.encode({ ["nes:smb"] = true, ["snes:zelda"] = false })
    local smb, zelda = { id = "nes:smb" }, { id = "snes:zelda", favorite = true }
    favorites.apply({ smb, zelda })
    assert.is_true(smb.favorite)
    assert.is_nil(zelda.favorite)
    assert.same({ ["nes:smb"] = true, ["snes:zelda"] = false }, json.decode(files[favorites.FILE]))
  end)

  it("forgets changes the gamelist already has, or for games no longer there", function()
    files[favorites.FILE] = json.encode({ ["nes:smb"] = true, ["gb:gone"] = true })
    favorites.apply({ { id = "nes:smb", favorite = true } })
    assert.same({}, json.decode(files[favorites.FILE]))
  end)

  it("hints at what X will do", function()
    assert.equal("X: favorite   ", favorites.hint({}))
    assert.equal("X: unfavorite   ", favorites.hint({ favorite = true }))
  end)
end)
