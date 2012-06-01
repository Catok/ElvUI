local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule('NamePlates')

local selectedFilter
local filters
local selectedSpellName
local spellLists
local spellIDs = {}

function deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
			return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

local function UpdateFilterGroup()
	if not selectedFilter or not E.global['nameplate']['filter'][selectedFilter] then
		E.Options.args.nameplate.args.filters.args.filterGroup = nil
		return
	end
	
	E.Options.args.nameplate.args.filters.args.filterGroup = {
		type = 'group',
		name = selectedFilter,
		guiInline = true,
		order = -10,
		get = function(info) return E.global["nameplate"]['filter'][selectedFilter][ info[#info] ] end,
		set = function(info, value) E.global["nameplate"]['filter'][selectedFilter][ info[#info] ] = value; NP:UpdateAllPlates(); UpdateFilterGroup() end,		
		args = {
			enable = {
				type = 'toggle',
				order = 1,
				name = L['Enable'],
				desc = L['Use this filter.'],
			},
			hide = {
				type = 'toggle',
				order = 2,
				name = L['Hide'],
				desc = L['Prevent any nameplate with this unit name from showing.'],
			},
			customColor = {
				type = 'toggle',
				order = 3,
				name = L['Custom Color'],
				desc = L['Disable threat coloring for this plate and use the custom color.'],			
			},
			color = {
				type = 'color',
				order = 4,
				name = L['Color'],
				get = function(info)
					local t = E.global["nameplate"]['filter'][selectedFilter][ info[#info] ]
					if t then
						return t.r, t.g, t.b, t.a
					end
				end,
				set = function(info, r, g, b)
					E.global["nameplate"]['filter'][selectedFilter][ info[#info] ] = {}
					local t = E.global["nameplate"]['filter'][selectedFilter][ info[#info] ]
					if t then
						t.r, t.g, t.b = r, g, b
						UpdateFilterGroup()
					end
				end,
			},
			customScale = {
				type = 'range',
				name = L['Custom Scale'],
				desc = L['Set the scale of the nameplate.'],
				min = 0.3, max = 2, step = 0.01,
				get = function(info) return E.global["nameplate"]['filter'][selectedFilter][ info[#info] ] end,
				set = function(info, value) E.global["nameplate"]['filter'][selectedFilter][ info[#info] ] = value; UpdateFilterGroup() end,						
			},
		},	
	}
end

local function UpdateSpellGroup()
	if not selectedSpellName or not E.global['nameplate']['spellList'][selectedSpellName] then
		E.Options.args.nameplate.args.auras.args.specificSpells.args.spellGroup = nil
		return
	end
	
	E.Options.args.nameplate.args.auras.args.specificSpells.args.spellGroup = {
		type = 'group',
		name = selectedSpellName,
		guiInline = true,
		order = -10,
		get = function(info) return E.global["nameplate"]['spellList'][selectedSpellName][ info[#info] ] end,
		set = function(info, value) E.global["nameplate"]['spellList'][selectedSpellName][ info[#info] ] = value; NP:UpdateAllPlates(); UpdateSpellGroup() end,		
		args = {
			visibility = {
				type = 'select',
				order = 1,
				name = L['Visibility'],
				desc = L['Set when this aura is visble.'],
				values = {[1]="Always",[2]="Never",[3]="Only Mine"},
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["visibility"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["visibility"] = value
				end,
			},
			width = {
				type = 'range',
				order = 2,
				name = L['Icon Width'],
				desc = L['Set the width of this spells icon.'],
				min = 10,
				max = 100,
				step = 2,
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["width"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["width"] = value
					if E.global['nameplate']['spellList'][selectedSpellName]["lockAspect"] then
						E.global['nameplate']['spellList'][selectedSpellName]["height"] = value
					end
				end,
			},
			height = {
				type = 'range',
				order = 3,
				name = L['Icon Height'],
				desc = L['Set the height of this spells icon.'],
				disabled = function() return E.global['nameplate']['spellList'][selectedSpellName]["lockAspect"] end,
				min = 10,
				max = 100,
				step = 2,
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["height"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["height"] = value
				end,
			},
			lockAspect = {
				type = 'toggle',
				order = 4,
				name = L['Lock Aspect Ratio'],
				desc = L['Set if height and width are locked to the same value.'],
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["lockAspect"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["lockAspect"] = value
					if value then
						E.global['nameplate']['spellList'][selectedSpellName]["height"] = E.global['nameplate']['spellList'][selectedSpellName]["width"]
					end
				end,
			},
			flashTime = {
				type = 'range',
				order = 5,
				name = L['Flash Duration'],
				desc = L['Set the time in seconds that the icon will begin flashing.'],
				min = 0,
				max = 10,
				step = 1,
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["flashTime"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["flashTime"] = value
				end,
			},
			text = {
				type = 'range',
				order = 7,
				name = L['Text Size'],
				desc = L['Size of the timer text.'],
				min = 6,
				max = 24,
				step = 1,
				get = function(info)
					return E.global['nameplate']['spellList'][selectedSpellName]["text"]
				end,
				set = function(info, value)
					E.global['nameplate']['spellList'][selectedSpellName]["text"] = value
				end,
			},
		},	
	}
end

E.Options.args.nameplate = {
	type = "group",
	name = L["NamePlates"],
	childGroups = "tree",
	get = function(info) return E.db.nameplate[ info[#info] ] end,
	set = function(info, value) E.db.nameplate[ info[#info] ] = value; NP:UpdateAllPlates() end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["NAMEPLATE_DESC"],
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.nameplate[ info[#info] ] end,
			set = function(info, value) E.private.nameplate[ info[#info] ] = value; StaticPopup_Show("PRIVATE_RL") end
		},
		general = {
			order = 3,
			type = "group",
			name = L["General"],
			guiInline = true,
			disabled = function() return not E.NamePlates; end,
			args = {
				width = {
					type = "range",
					order = 1,
					name = L["Width"],
					desc = L["Controls the width of the nameplate"],
					type = "range",
					min = 50, max = 125, step = 1,		
				},	
				height = {
					type = "range",
					order = 2,
					name = L["Height"],
					desc = L["Controls the height of the nameplate"],
					type = "range",
					min = 4, max = 30, step = 1,					
				},
				cbheight = {
					type = "range",
					order = 3,
					name = L["Castbar Height"],
					desc = L["Controls the height of the nameplate's castbar"],
					type = "range",
					min = 4, max = 30, step = 1,						
				},
				showhealth = {
					type = "toggle",
					order = 4,
					name = L["Health Text"],
					desc = L["Toggles health text display"],
				},	
				showlevel = {
					type = "toggle",
					order = 5,
					name = LEVEL,
					desc = L["Display level text on nameplate for nameplates that belong to units that aren't your level."],	
				},		
				combat = {
					type = "toggle",
					order = 6,
					name = L["Combat Toggle"],
					desc = L["Toggles the nameplates off when not in combat."],							
				},	
				markBGHealers = {
					type = 'toggle',
					order = 7,
					name = L['Healer Icon'],
					desc = L['Display a healer icon over known healers inside battlegrounds.'],
					set = function(info, value) E.db.nameplate[ info[#info] ] = value; NP:PLAYER_ENTERING_WORLD(); NP:UpdateAllPlates() end,
				},
				reactions = {
					order = 8,
					type = "group",
					name = L["Reactions"],
					guiInline = true,
					get = function(info)
						local t = E.db.nameplate[ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.nameplate[ info[#info] ] = {}
						local t = E.db.nameplate[ info[#info] ]
						t.r, t.g, t.b = r, g, b
						NP:UpdateAllPlates()
					end,				
					args = {
						friendlynpc = {
							type = "color",
							order = 1,
							name = L["Friendly NPC"],
							hasAlpha = false,
						},
						friendlyplayer = {
							type = "color",
							order = 2,
							name = L["Friendly Player"],
							hasAlpha = false,
						},
						neutral = {
							type = "color",
							order = 3,
							name = L["Neutral"],
							hasAlpha = false,
						},
						enemy = {
							type = "color",
							order = 4,
							name = L["Enemy"],
							hasAlpha = false,
						},						
					},		
				},				
				threat = {
					order = 9,
					type = "group",
					name = L["Threat"],
					guiInline = true,
					args = {
						enhancethreat = {
							type = "toggle",
							order = 1,
							name = L["Enhance Threat"],
							desc = L["Color the nameplate's healthbar by your current threat, Example: good threat color is used if your a tank when you have threat, opposite for DPS."],
						},
						goodscale = {
							type = 'range',
							order = 2,
							name = L['Good Scale'],
							desc = L['Set the scale of the nameplate.'],
							min = 0.67, max = 2, step = 0.01,					
						},	
						badscale = {
							type = 'range',
							order = 3,
							name = L['Bad Scale'],
							desc = L['Set the scale of the nameplate.'],
							min = 0.67, max = 2, step = 0.01,					
						},							
						goodcolor = {
							type = "color",
							order = 4,
							name = L["Good Color"],
							desc = L["This is displayed when you have threat as a tank, if you don't have threat it is displayed as a DPS/Healer"],
							hasAlpha = false,
							get = function(info)
								local t = E.db.nameplate[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.nameplate[ info[#info] ] = {}
								local t = E.db.nameplate[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								NP:UpdateAllPlates()
							end,								
						},		
						badcolor = {
							type = "color",
							order = 5,
							name = L["Bad Color"],
							desc = L["This is displayed when you don't have threat as a tank, if you do have threat it is displayed as a DPS/Healer"],
							hasAlpha = false,
							get = function(info)
								local t = E.db.nameplate[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.nameplate[ info[#info] ] = {}
								local t = E.db.nameplate[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								NP:UpdateAllPlates()
							end,							
						},
						goodtransitioncolor = {
							type = "color",
							order = 6,
							name = L["Good Transition Color"],
							desc = L["This color is displayed when gaining/losing threat, for a tank it would be displayed when gaining threat, for a dps/healer it would be displayed when losing threat"],
							hasAlpha = false,	
							get = function(info)
								local t = E.db.nameplate[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.nameplate[ info[#info] ] = {}
								local t = E.db.nameplate[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								NP:UpdateAllPlates()
							end,							
						},
						badtransitioncolor = {
							type = "color",
							order = 7,
							name = L["Bad Transition Color"],
							desc = L["This color is displayed when gaining/losing threat, for a tank it would be displayed when losing threat, for a dps/healer it would be displayed when gaining threat"],
							hasAlpha = false,	
							get = function(info)
								local t = E.db.nameplate[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.nameplate[ info[#info] ] = {}
								local t = E.db.nameplate[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								NP:UpdateAllPlates()
							end,							
						},						
					},
				},				
			},
		},
		auras = {
			order = 5,
			type = "group",
			name = L["Auras"],
			disabled = function() return not E.NamePlates; end,
			args = {
				preciseTimer = {
					type = "toggle",
					order = 1,
					name = L["Precise Timer"],
					desc = L["Displays the time to one decimal point."],
				},
				colorByTime = {
					type = "toggle",
					order = 2,
					name = L["Color Timer Text By Time"],
					desc = L["Changes the color of the timer text by time remaining."],
					get = function(info)
						if E.db.nameplate['colorByTime'] == nil then
							E.db.nameplate['colorByTime'] = true
						end
						return E.db.nameplate['colorByTime']
					end,
					set = function(info, value)
						E.db.nameplate['colorByTime'] = value
					end,
				},
				timerColor = {
					type = "color",
					order = 3,
					name = L["Color of Timer Text"],
					desc = L["Sets the color of the timer text when not using the color by time left option."],
					disabled = function() return E.db.nameplate['colorByTime'] end,
					get = function(info)
						local color = E.db.nameplate['timerColor']
						if not color then
							color = {r = 1, g = 1, b = 1}
							E.db.nameplate['timerColor'] = color
						end
						return color.r, color.g, color.b, 1
					end,
					set = function(info, r, g, b)
						E.db.nameplate['timerColor'].r = r
						E.db.nameplate['timerColor'].g = g
						E.db.nameplate['timerColor'].b = b
					end,
				},
				maxAuras = {
					type = 'range',
					order = 4,
					name = L['Maximum Auras'],
					desc = L['Set the maximum number of auras per nameplate.'],
					min = 1,
					max = 10,
					step = 1,
					get = function(info)
						if E.db.nameplate['maxAuras'] == nil then
							E.db.nameplate['maxAuras'] = 5
						end
						return E.db.nameplate['maxAuras']
					end,
					set = function(info, value)
						E.db.nameplate['maxAuras'] = value
						StaticPopup_Show("GLOBAL_RL")
					end,
				},
				auraAnchor = {
					type = 'select',
					order = 5,
					name = L['Anchor'],
					desc = L['Set how icons are anchored to the nameplate.'],
					values = {[0]="Left",[1]="Right",[2]="Center"},
					get = function(info)
						if E.db.nameplate['auraAnchor'] == nil then
							E.db.nameplate['auraAnchor'] = 1
						end
						return E.db.nameplate['auraAnchor']
					end,
					set = function(info, value)
						E.db.nameplate['auraAnchor'] = value
						StaticPopup_Show("GLOBAL_RL")
					end,
				},
				sortDirection = {
					type = 'select',
					order = 5,
					name = L['Sorting'],
					desc = L['Set how icons are sorted based on time left.'],
					values = {[0]="Lowest",[1]="Highest"},
					get = function(info)
						if E.db.nameplate['sortDirection'] == nil then
							E.db.nameplate['sortDirection'] = 1
						end
						return E.db.nameplate['sortDirection']
					end,
					set = function(info, value)
						E.db.nameplate['sortDirection'] = value
					end,
				},
				clearSpellList = {
					order = 6,
					type = 'execute',
					name = L['Clear Spell List'],
					desc = L['Empties the list of specific spells and their configurations'],
					func = function()
						E.global["nameplate"]["spellList"] = { }
						UpdateSpellGroup()
					end
				},
				resetSpellList = {
					order = 7,
					type = 'execute',
					name = L['Restore Spell List'],
					desc = L['Restores the default list of specific spells and their configurations'],
					func = function()
						E.global["nameplate"]["spellList"] = deepcopy(E.global["nameplate"]["spellListDefault"]["defaultSpellList"])
						UpdateSpellGroup()
					end
				},
				specificSpells = {
					order = 1,
					type = "group",
					name = L["Specific Auras"],
					args = {
						addSpell = {
							type = "input",
							order = 1,
							name = L["Spell Name"],
							desc = L["Input a spell name or spell ID."],
							get = function(info) return "" end,
							set = function(info, value) 
								local spellName = ""
								
								if not tonumber(value) then
									value = tostring(value)
								end
								
								if not tonumber(value) and strlower(value) == "school lockout" then
									spellName = "School Lockout"
								elseif not GetSpellInfo(value) then
									if #(spellIDs) == 0 then
										for i = 100000, 1,-1  do --Ugly but works
											local name = GetSpellInfo(i)
											if name and not spellIDs[name] then
												spellIDs[name] = i
											end
										end
									end
									if spellIDs[value] then
										spellName = value
									end
								else
									spellName = GetSpellInfo(value)
								end
								
								if spellName ~= "" then
									if not E.global['nameplate']['spellList'][spellName] then
										E.global['nameplate']['spellList'][spellName] = {
											['visibility'] = E.global['nameplate']['spellListDefault']['visibility'],
											['width'] = E.global['nameplate']['spellListDefault']['width'],
											['height'] = E.global['nameplate']['spellListDefault']['height'],
											['lockAspect'] = E.global['nameplate']['spellListDefault']['lockAspect'],
											['text'] = E.global['nameplate']['spellListDefault']['text'],
											['flashTime'] = E.global['nameplate']['spellListDefault']['flashTime'],
										}
									end
									selectedSpellName = spellName
									UpdateSpellGroup()
								else
									E:Print(L["Not valid spell name or spell ID"])
								end
							end,	
						},
						spellList = {
							order = 2,
							type = 'select',
							name = L['Spell List'],
							get = function(info) return selectedSpellName end,
							set = function(info, value) selectedSpellName = value; UpdateSpellGroup() end,							
							values = function()
								spellLists = {}
								for spell in pairs(E.global['nameplate']['spellList']) do
									local color = "|cffff0000"
									local visibility = E.global['nameplate']['spellList'][spell]['visibility']
									if visibility == 1 then
										color = "|cff00ff00"
									elseif visibility == 3 then
										color = "|cff00ffff"
									end
									spellLists[spell] = color..spell.."|r"
								end
								return spellLists
							end,
						},
						removeSpell = {
							order = 3,
							type = 'execute',
							name = L['Remove Spell'],
							func = function()
								if E.global['nameplate']['spellList'][selectedSpellName] then
									E.global['nameplate']['spellList'][selectedSpellName] = nil
									selectedSpellName = ""
									UpdateSpellGroup()
								end
							end
						},
					},
				},
				otherSpells = {
					order = 2,
					type = "group",
					name = L["Other Auras"],
					args = {
						intro = {
							order = 1,
							type = "description",
							name = L["These are the settings for all spells not explicitly specified."],
						},
						visibility = {
							type = 'select',
							order = 2,
							name = L['Visibility'],
							desc = L['Set when this aura is visble.'],
							values = {[1]="Always",[2]="Never",[3]="Only Mine"},
							get = function(info)
								return E.global['nameplate']['spellListDefault']["visibility"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["visibility"] = value
							end,
						},
						width = {
							type = 'range',
							order = 3,
							name = L['Icon Width'],
							desc = L['Set the width of this spells icon.'],
							min = 10,
							max = 100,
							step = 2,
							get = function(info)
								return E.global['nameplate']['spellListDefault']["width"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["width"] = value
								if E.global['nameplate']['spellListDefault']["lockAspect"] then
									E.global['nameplate']['spellListDefault']["height"] = value
								end
							end,
						},
						height = {
							type = 'range',
							order = 4,
							name = L['Icon Height'],
							desc = L['Set the height of this spells icon.'],
							disabled = function() return E.global['nameplate']['spellListDefault']["lockAspect"] end,
							min = 10,
							max = 100,
							step = 2,
							get = function(info)
								return E.global['nameplate']['spellListDefault']["height"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["height"] = value
							end,
						},
						lockAspect = {
							type = 'toggle',
							order = 5,
							name = L['Lock Aspect Ratio'],
							desc = L['Set if height and width are locked to the same value.'],
							get = function(info)
								return E.global['nameplate']['spellListDefault']["lockAspect"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["lockAspect"] = value
								if value then
									E.global['nameplate']['spellListDefault']["height"] = E.global['nameplate']['spellListDefault']["width"]
								end
							end,
						},
						flashTime = {
							type = 'range',
							order = 6,
							name = L['Flash Duration'],
							desc = L['Set the time in seconds that the icon will begin flashing.'],
							min = 0,
							max = 10,
							step = 1,
							get = function(info)
								return E.global['nameplate']['spellListDefault']["flashTime"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["flashTime"] = value
							end,
						},
						text = {
							type = 'range',
							order = 7,
							name = L['Text Size'],
							desc = L['Size of the timer text.'],
							min = 6,
							max = 24,
							step = 1,
							get = function(info)
								return E.global['nameplate']['spellListDefault']["text"]
							end,
							set = function(info, value)
								E.global['nameplate']['spellListDefault']["text"] = value
							end,
						},
					},
				},
			},
		},
		filters = {
			type = "group",
			order = 6,
			name = L["Filters"],
			disabled = function() return not E.NamePlates; end,
			args = {
				addname = {
					type = 'input',
					order = 1,
					name = L['Add Name'],
					get = function(info) return "" end,
					set = function(info, value) 
						if E.global['nameplate']['filter'][value] then
							E:Print(L['Filter already exists!'])
							return
						end
						
						E.global['nameplate']['filter'][value] = {
							['enable'] = true,
							['hide'] = false,
							['customColor'] = false,
							['customScale'] = 1,
							['color'] = {r = 104/255, g = 138/255, b = 217/255},
						}
						UpdateFilterGroup()
						NP:UpdateAllPlates() 
					end,
				},
				deletename = {
					type = 'input',
					order = 2,
					name = L['Remove Name'],
					get = function(info) return "" end,
					set = function(info, value) 
						if G['nameplate']['filter'][value] then
							E.global['nameplate']['filter'][value].enable = false;
							E:Print(L["You can't remove a default name from the filter, disabling the name."])
						else
							E.global['nameplate']['filter'][value] = nil;
							E.Options.args.nameplate.args.filters.args.filterGroup = nil;
						end
						UpdateFilterGroup()
						NP:UpdateAllPlates();
					end,				
				},
				selectFilter = {
					order = 3,
					type = 'select',
					name = L['Select Filter'],
					get = function(info) return selectedFilter end,
					set = function(info, value) selectedFilter = value; UpdateFilterGroup() end,							
					values = function()
						filters = {}
						for filter in pairs(E.global['nameplate']['filter']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
			},
		},
	},
}

G["nameplate"]["spellListDefault"] = {
	['visibility'] = 1,
	['width'] = 20,
	['height'] = 20,
	['lockaspect'] = true,
	['text'] = 7,
	['flashTime'] = 0,
	['firstLoad'] = true,
	['defaultSpellList'] = {
		["Shockwave"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Cloak of Shadows"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Deterrence"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Death Coil"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Polymorph"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Netherstorm Flag"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 50,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 50,
		},
		["Hammer of Justice"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Ring of Frost"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Silence"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Bad Manner"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Hibernate"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Concussion Blow"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Divine Protection"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Blind"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Turn Evil"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Throwdown"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Banish"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Strangulate"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Seduction"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Anti-Magic Shell"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Sprint"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Ice Block"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Silencing Shot"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Gnaw"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Hungering Cold"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Freezing Trap"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Cyclone"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Divine Shield"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Intimidating Shout"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Hand of Protection"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Silenced - Gag Order"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Disarm"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Shield Wall"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Master's Call"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Scatter Shot"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Horde Flag"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 50,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 50,
		},
		["Sap"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Guardian Spirit"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Deep Freeze"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Hand of Freedom"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Psychic Horror"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Pain Suppression"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Dispersion"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Hex"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Lichborne"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Howl of Terror"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Dismantle"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Wyvern Sting"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Nature's Grasp"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Icebound Fortitude"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Barkskin"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Evasion"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Mind Control"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Alliance Flag"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 50,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 50,
		},
		["Enraged Regeneration"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Dash"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Innervate"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Fear"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Repentance"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["School Lockout"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
-------------------------------------------------
		["Arcane Power"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Aura Mastery"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Avenging Wrath"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Bash"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Beacon of Light"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Berserk"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Berserker Rage"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Bestial Wrath"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Bind Elemental"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Bladestorm"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Bloodlust"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Charge Stun"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Cheap Shot"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Cheat Death"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Combat Insight"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Deadly Calm"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Death Wish"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Demon Leap"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Demon Soul: Felhunter"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Divine Plea"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Dragon's Breath"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Entangling Roots"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Entrapment"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Fear Ward"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Feral Charge"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Freeze"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Frost Nova"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Garrote - Silence"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Gouge"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Hand of Sacrifice"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Heroism"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Icy Veins"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Impact"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Improved Cone of Cold"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Improved Hamstring"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Intimidation"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Kidney Shot"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Lifebloom"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Maim"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Monstrous Blow"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Pillar of Frost"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Pounce"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Power Infusion"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Predator's Swiftness"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Psychic Scream"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Rapid Fire"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Recklessness"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Scare Beast"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Shackle Undead"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Shadow Dance"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Shadow Fury"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Shadow Infusion"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Shambling Rush"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Silenced - Improved Counterspell"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Silenced - Improved Kick"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Spell Lock"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Spell Reflection"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Strength of Soul"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Tiger's Fury"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Time Warp"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["Unholy Frenzy"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		["War Stomp"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 36,
			["text"] = 16,
			["visibility"] = 1,
			["width"] = 36,
		},
		["Zealotry"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 1,
			["width"] = 28,
		},
		---------Class specific--------
		["Living Bomb"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Hunter's Mark"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Serpent Sting"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Flame Shock"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Faerie Fire"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Moonfire"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Sunfire"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Insect Swarm"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Unstable Affliction"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Corruption"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Haunt"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Bane of Agony"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
		["Bane of Doom"] = {
			["lockAspect"] = true,
			["flashTime"] = 0,
			["height"] = 28,
			["text"] = 14,
			["visibility"] = 3,
			["width"] = 20,
		},
	}
}

G["nameplate"]["spellList"] = { }