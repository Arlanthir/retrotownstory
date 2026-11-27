local retroachievements = require("services.retroachievements")
local save = require("core.save")

describe("retroachievements.parseConfig", function()
  it("reads key=value lines", function()
    assert.same({ username = "Player", apikey = "abc123" },
      retroachievements.parseConfig("username = Player\r\napikey=abc123\n"))
  end)

  it("accepts a file with only the API key", function()
    assert.same({ apikey = "abc123" }, retroachievements.parseConfig("  abc123  \n"))
  end)
end)

describe("retroachievements.queue", function()
  it("queues owned games that have achievements", function()
    local state = save.defaults()
    local owned = { id = "gb:tetris", cheevosId = 508 }
    state.owned[owned.id] = true
    retroachievements.queue(state, { owned, { id = "gb:other", cheevosId = 9 }, { id = "gb:none" } })
    assert.same({ ["508"] = true }, state.pendingAchievementGames)
  end)

  it("queues the ROM hash of owned games with no id, to look it up", function()
    local state = save.defaults()
    local owned = { id = "gamegear:psychic", cheevosHash = "52cfddc12af6a3a64030f62ccf6aca83" }
    state.owned[owned.id] = true
    retroachievements.queue(state, { owned })
    assert.same({}, state.pendingAchievementGames)
    assert.same({ ["52cfddc12af6a3a64030f62ccf6aca83"] = true }, state.pendingAchievementHashes)
  end)

  it("keeps the last session of owned games with neither id nor hash, on consoles with achievements", function()
    local state = save.defaults()
    local playlist = { id = "psx:./gt2.m3u", system = "psx" }
    local computer = { id = "dos:./doom", system = "dos" }
    local unlaunched = { id = "psx:./ff7.m3u", system = "psx" }
    for _, game in ipairs({ playlist, computer, unlaunched }) do state.owned[game.id] = true end
    local sessions = { [playlist.id] = { start = 1000, seconds = 600 }, [computer.id] = { start = 2000, seconds = 60 } }
    retroachievements.queue(state, { playlist, computer, unlaunched }, nil, sessions)
    assert.same({ [playlist.id] = { from = 1000, to = 1600, console = 12 } }, state.pendingAchievementPlays)
    assert.same({}, state.pendingAchievementHashes)
  end)

  it("queues games the caller says were playable, such as an ended GotX loan launched from here", function()
    local state = save.defaults()
    local loaned = { id = "gbc:shantae", cheevosId = 4141 }
    local launched = { [loaned.id] = true }
    retroachievements.queue(state, { loaned, { id = "gb:other", cheevosId = 9 } },
      function(game) return launched[game.id] or state.owned[game.id] end)
    assert.same({ ["4141"] = true }, state.pendingAchievementGames)
  end)
end)

describe("retroachievements.trackingSince", function()
  local now = os.time({ year = 2026, month = 11, day = 5, hour = 12 })
  local first = os.time({ year = 2026, month = 10, day = 1, hour = 12 })

  it("starts at the first game session", function()
    assert.equal(os.date("!%Y-%m-%d %H:%M:%S", first), retroachievements.trackingSince("", first, now))
  end)

  it("starts now without sessions", function()
    assert.equal(os.date("!%Y-%m-%d %H:%M:%S", now), retroachievements.trackingSince("", nil, now))
  end)

  it("moves an existing start back to the first session, never forward", function()
    assert.equal(os.date("!%Y-%m-%d %H:%M:%S", first), retroachievements.trackingSince("2026-11-05 10:00:00", first, now))
    assert.equal("2026-09-01 00:00:00", retroachievements.trackingSince("2026-09-01 00:00:00", first, now))
  end)
end)
