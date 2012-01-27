local E, L, DF = unpack(select(2, ...)); --Engine
local TT = E:GetModule('Tooltip')


E.Options.args.tooltip = {
	type = "group",
	name = L["Tooltip"],
	childGroups = "select",
	get = function(info) return E.db.tooltip[ info[#info] ] end,
	set = function(info, value) E.db.tooltip[ info[#info] ] = value; end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["TOOLTIP_DESC"],
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Enable"],
			set = function(info, value) E.db.tooltip[ info[#info] ] = value; StaticPopup_Show("CONFIG_RL") end
		},
		anchor = {
			order = 3,
			type = 'select',
			name = L['Anchor Mode'],
			desc = L['Set the type of anchor mode the tooltip should use.'],
			values = {
				['SMART'] = L['Smart'],
				['CURSOR'] = L['Cursor'],
				['ANCHOR'] = L['Anchor'],
			},
		},
		ufhide = {
			order = 4,
			type = 'toggle',
			name = L['UF Hide'],
			desc = L["Don't display the tooltip when mousing over a unitframe."],
		},
		whostarget = {
			order = 5,
			type = 'toggle',
			name = L["Who's targetting who?"],
			desc = L["When in a raid group display if anyone in your raid is targetting the current tooltip unit."],
		},
		combathide = {
			order = 6,
			type = 'toggle',
			name = L["Combat Hide"],
			desc = L["Hide tooltip while in combat."],
		},
	},
}