-- CfxLua preprocessor plugin for lua-language-server (LuaLS).
--
-- LuaLS's parser does not understand CitizenFX / GRIT Lua syntax, so it emits
-- spurious syntax errors. This OnSetText hook rewrites that syntax to standard
-- Lua *before* LuaLS parses it (diagnostics-only; the real cfx runtime is
-- unaffected). Wired up by the extension via `Lua.runtime.plugin`.
--
-- Safe-navigation and manifest/meta handling are ported from
-- overextended/fivem-lls-addon (MIT, Copyright (c) 2022 Overextended).
-- tabinit and localin rewrites are added for CfxLua.

local str_find = string.find
local str_sub = string.sub
local str_gmatch = string.gmatch

---@param uri string # The uri of file
---@param text string # The content of file
---@return { start: integer, finish: integer, text: string }[] | string | nil
function OnSetText(uri, text)
	-- ignore .vscode dir, extension files (i.e. natives), and other meta files
	if str_find(uri, '[\\/]%.vscode[\\/]') or str_sub(text, 1, 8) == '---@meta' then return end

	-- ignore files using fx asset protection
	if str_sub(text, 1, 4) == 'FXAP' then return '' end

	local diffs = {}
	local count = 0

	-- prevent diagnostic errors in fxmanifest.lua and __resource.lua files
	if str_find(uri, 'fxmanifest%.lua$') or str_find(uri, '__resource%.lua$') then
		count = count + 1
		diffs[count] = {
			start = 1,
			finish = 0,
			text = '---@diagnostic disable: undefined-global\n'
		}
	end

	-- prevent diagnostic errors from safe navigation (foo?.bar and foo?[bar])
	for safeNav in str_gmatch(text, '()%?[%.%[]+') do
		count = count + 1
		diffs[count] = {
			start  = safeNav,
			finish = safeNav,
			text   = '',
		}
	end

	-- prevent "need-check-nil" diagnostic when using safe navigation
	-- only works for the first index, and requires dot notation (i.e. mytable.index, not mytable["index"])
	for pre, whitespace, tableStart, tableName, tableEnd in str_gmatch(text, '([=,;%s])([%s]*)()([_%w]+)()%?[%.%[]+') do
		count = count + 1
		diffs[count] = {
			start  = tableStart - 1,
			finish = tableEnd - 1,
			text = ('%s(%s or {})'):format(whitespace == '' and pre or '', tableName)
		}
	end

	-- GRIT_POWER_TABINIT: table set / field shorthand inside a constructor
	--   { .x = 1 }  ->  { x = 1 }      (drop the leading dot)
	--   { .z }      ->  { z = true }   (bare field = set membership)
	for dotPos, name, afterName in str_gmatch(text, '[{,]%s*()%.([_%a][_%w]*)()') do
		local rest = str_sub(text, afterName)
		local isAssign = str_find(rest, '^%s*=') and not str_find(rest, '^%s*==')
		count = count + 1
		if isAssign then
			-- `.x = v` -> `x = v` : remove just the leading dot
			diffs[count] = { start = dotPos, finish = dotPos, text = '' }
		else
			-- bare `.z` -> `z = true` (set membership; avoids undefined-global)
			diffs[count] = { start = dotPos, finish = afterName - 1, text = name .. ' = true' }
		end
	end

	-- GRIT_POWER_LOCALIN: `local a, b in t` -> `local a, b = t.a, t.b`
	for names, inStart, source, srcEnd in str_gmatch(text, 'local%s+([_%a][_%w%s,]-)()%s+in%s+([_%a][_%w%.]*)()') do
		local rhs = {}
		for n in str_gmatch(names, '[_%a][_%w]*') do
			rhs[#rhs + 1] = source .. '.' .. n
		end
		count = count + 1
		diffs[count] = { start = inStart, finish = srcEnd - 1, text = ' = ' .. table.concat(rhs, ', ') }
	end

	-- diffs are produced in groups (safe-nav, then tabinit, then localin) so the
	-- combined list is not globally ordered; LuaLS expects ascending, so sort.
	table.sort(diffs, function(a, b) return a.start < b.start end)

	return diffs
end
