local gamelist = require("backends.gamelist")

local function fixture(path)
  local file = assert(io.open("tests/fixtures/" .. path, "rb"))
  local contents = file:read("*a")
  file:close()
  return contents
end

describe("gamelist.parse", function()
  local games = gamelist.parse(fixture("roms/snes/gamelist.xml"), "snes", "/userdata/roms/snes")

  it("skips hidden games and folders", function()
    assert.equal(2, #games)
  end)

  it("reads metadata and numeric stats", function()
    local game = games[1]
    assert.equal("snes:./Super Metroid (USA).sfc", game.id)
    assert.equal("Super Metroid", game.name)
    assert.equal("0.95", game.rating)
    assert.equal(3, game.playcount)
    assert.equal(5400, game.gametime)
    assert.equal("en", game.lang)
    assert.equal("us", game.region)
    assert.equal(1446, game.cheevosId)
    assert.equal("a8d29e1b1f6bc5b38d9c3a5b7c3a9f10", game.cheevosHash)
  end)

  it("reads the game id only when ScreenScraper filled the entry", function()
    assert.equal(1, games[1].screenscraperId)
    local other = gamelist.parse('<gameList><game id="7"><path>./a.sfc</path><scrap name="TheGamesDB" /></game></gameList>',
      "snes", "/userdata/roms/snes")
    assert.is_nil(other[1].screenscraperId)
  end)

  it("decodes named and numeric entities", function()
    assert.equal("Samus & the baby Metroid é❤", games[1].desc)
  end)

  it("resolves relative rom and media paths against the system folder", function()
    assert.equal("/userdata/roms/snes/Super Metroid (USA).sfc", games[1].rom)
    assert.equal("/userdata/roms/snes/images/Super Metroid (USA)-image.png", games[1].image)
    assert.equal("/userdata/roms/snes/media/thumb.png", games[1].thumbnail)
  end)

  it("falls back to the file name and zero stats", function()
    assert.equal("No Metadata.sfc", games[2].name)
    assert.equal(0, games[2].playcount)
    assert.equal(0, games[2].gametime)
  end)
end)

describe("gamelist favorites", function()
  it("reads EmulationStation's favorite flag", function()
    local games = gamelist.parse([[<gameList>
      <game><path>./a.sfc</path><name>A</name><favorite>true</favorite></game>
      <game><path>./b.sfc</path><name>B</name><favorite>false</favorite></game>
      <game><path>./c.sfc</path><name>C</name></game>
    </gameList>]], "snes", "/roms/snes")
    assert.same({ true }, { games[1].favorite })
    assert.is_nil(games[2].favorite)
    assert.is_nil(games[3].favorite)
  end)
end)
