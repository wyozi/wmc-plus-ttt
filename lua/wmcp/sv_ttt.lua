util.AddNetworkString("wmcpttt_play")
util.AddNetworkString("wmcpttt_stop")

local table = table
local pairs = pairs
local ipairs = ipairs

local t = nettable.get("WMCPMedia.Main")

local function GetPlayerSong()
	local alive = util.GetAlivePlayers()
	if #alive == 1 then
		local sid = alive[1]:SteamID()
		local available_links = {}

		for _, media in pairs(t) do
			if media.ttt_opts and media.ttt_opts[sid] then
				table.insert(available_links, {title = media.title, url = media.url})
			end
		end

		if #available_links > 0 then
			return table.Random(available_links)
		end
	end
end

local function GetRoundEndSong(round_result)
	local possibilities = {}

	if round_result == WIN_TIMELIMIT then
		-- Add in innocent-win songs.
		for _, media in pairs(t) do
			if media.ttt_opts and (media.ttt_opts[WIN_TIMELIMIT] or media.ttt_opts[WIN_INNOCENT]) then
				table.insert(possibilities, {title = media.title, url = media.url})
			end
		end
	else
		for _, media in pairs(t) do
			if media.ttt_opts and media.ttt_opts[round_result] then
				table.insert(possibilities, {title = media.title, url = media.url})
			end
		end
	end

	return #possibilities > 0 and table.Random(possibilities) or nil
end

hook.Add("TTTEndRound", "WMCPTTT_PlayRoundEnds", function(result)
	local media = GetPlayerSong() or GetRoundEndSong(result)
	if media then
		wmcp.PlayFor(nil, media.url, {
			meta = {
				title = media.title
			}
		})
	end
end)

hook.Add("TTTPrepareRound", "WMCPTTT_StopRoundEnds", function()
	wmcp.StopFor(nil)
end)

wmcp.AddSecuredConcommand("wmcpttt_setendround", "modify", function(plr, cmd, args, raw)
	local id = tonumber(args[1])
	local round_result = tonumber(args[2])
	local to_remove = args[3] == "1"

	if not id then
		--
		return
	end

	if round_result ~= WIN_TRAITOR and round_result ~= WIN_INNOCENT and
			round_result ~= WIN_TIMELIMIT then
		--
		return
	end

	local media = t[id or -1]

	if not media then
		--
		return
	end

	if to_remove then
		if not media.ttt_opts then return end
		media.ttt_opts[round_result] = nil
		if next(media.ttt_opts) == nil then
			media.ttt_opts = nil
		end
	else
		if not media.ttt_opts then media.ttt_opts = {} end
		-- Exit early so we don't resend the table to users or rewrite the file.
		if media.ttt_opts[round_result] then return end
		media.ttt_opts[round_result] = true
	end

	nettable.commit(t)
	wmcp.Persist()
end)

wmcp.AddSecuredConcommand("wmcpttt_setplayer", "modify", function(plr, cmd, args, raw)
	local id = tonumber(args[1])
	local sid = tostring(args[2])
	local to_remove = args[3] == "1"

	if not id or not sid then
		--
		return
	end

	if not string.match(sid, "^STEAM_%d:%d:%d+$") then
		--
		return
	end

	local media = t[id or -1]

	if not media then
		--
		return
	end

	if to_remove then
		if not media.ttt_opts then return end
		media.ttt_opts[sid] = nil
		if next(media.ttt_opts) == nil then
			media.ttt_opts = nil
		end
	else
		if not media.ttt_opts then media.ttt_opts = {} end
		-- Exit early so we don't resend the table to users or rewrite the file.
		if media.ttt_opts[sid] then return end
		media.ttt_opts[sid] = true
	end

	nettable.commit(t)
	wmcp.Persist()
end)
