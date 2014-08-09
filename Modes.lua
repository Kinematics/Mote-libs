-------------------------------------------------------------------------------------------------------------------
-- This include library allows use of specially-designed tables for tracking
-- certain types of modes and state.
--
-- Usage: include('Modes.lua')
--
-- Construction syntax:
--
-- 1) Create a new list of mode values. The first value will always be the default.
-- MeleeMode = M{'Normal', 'Acc', 'Att'} -- Pass in a basic table, using braces.
-- MeleeMode = M('Normal', 'Acc', 'Att') -- Pass in a list of strings, using parentheses.
-- MeleeMode = M(anotherTable) -- Pass in a reference to another table, using parentheses.
--    Note: The table must have standard numeric indexing.  It cannot use string indexing.
--
-- Optional: If a table is passed in, and it contains a key value of 'description', that
-- description will be saved for future reference.
-- If a series of strings is passed in, no description will be set.
--
-- 2) Create a boolean mode with a default value of false (note parentheses).
-- UseLuzafRing = M()
-- UseLuzafRing = M(false)
-- Create a boolean mode with a default value of true:
-- UseLuzafRing = M(true)
--
-- Optional: A string may be provided that will be used as the mode description:
-- UseLuzafRing = M('description') -- default value of false
-- UseLuzafRing = M(false, 'description')
-- UseLuzafRing = M(true, 'description')
--
--
-- Public information fields (all are case-insensitive):
--
-- 1) m.description -- Get a text description of the mode table, if it's been set.
-- 2) m.current -- Gets the current mode value.  Booleans will return the boolean values of true or false.
-- 3) m.value -- Gets the current mode value.  Booleans will return the strings "on" or "off".
--
--
-- Public information functions:
--
-- 1) m:describe(str) -- Sets the description for the mode table to the provided string value.
--
--
-- Public mode manipulation functions:
--
-- Assuming a Mode variable 'm':
--
-- 1) m:cycle() -- Cycles through the list going forwards.  Acts as a toggle on boolean mode vars.
-- 2) m:cycleback() -- Cycles through the list going backwards.  Acts as a toggle on boolean mode vars.
-- 3) m:toggle() -- Toggles a boolean Mode between true and false.
-- 4) m:set(n) -- Sets the current mode value to n.
--    Note: If m is boolean, n can be boolean true/false, or strings of on/off/true/false.
-- 5) m:reset() -- Returns the mode var to its default state.
--
-- All public functions return the current value after completion.
--
--
-- Example usage:
--
-- sets.MeleeMode.Normal = {}
-- sets.MeleeMode.Acc = {}
-- sets.MeleeMode.Att = {}
--
-- MeleeMode = M{'Normal', 'Acc', 'Att', ['description']='Melee Mode'}
-- MeleeMode:cycle()
-- equip(sets.engaged[MeleeMode.current])
--
--
-- sets.LuzafRing.on = {ring2="Luzaf's Ring"}
-- sets.LuzafRing.off = {}
--
-- UseLuzafRing = M(false)
-- UseLuzafRing:toggle()
-- equip(sets.precast['Phantom Roll'], sets.LuzafRing[UseLuzafRing.value])
-------------------------------------------------------------------------------------------------------------------


_meta = _meta or {}
_meta.M = {}

-- Default constructor for mode tables
-- M{'a', 'b', etc, ['description']='a'} -- defines a mode list, description 'a'
-- M('a', 'b', etc) -- defines a mode list, no description
-- M() -- defines a mode boolean, default false, no description
-- M(false) -- defines a mode boolean, default false, no description
-- M(true) -- defines a mode boolean, default true, no description
-- M('a') -- defines a mode boolean, default false, description 'a'
-- M(false, 'a') -- defines a mode boolean, default false, description 'a'
-- M(true, 'a') -- defines a mode boolean, default true, description 'a'
function M(t, ...)
    local m = {}
    m._track = {}

	-- If we're passed a list of strings, convert them to a table
	local args = {...}
	if type(t) == 'string' and #args > 0 then
		t = {[1] = t}
		
	    for ind, val in ipairs(args) do
	        t[ind+1] = val
	    end
	end

	-- Construct the table that we'll be added the metadata to
	if type(t) == 'table' and #t > 1 then
		m._track._type = 'list'
		
		-- Only copy numerically indexed values
	    for ind, val in ipairs(t) do
	        m[ind] = val
	    end
	    
	    if t['description'] then
	    	m._track._description = t['description']
	    end

	    m._track._invert = {}
	    m._track._count = 0
	    for key,val in ipairs(m) do
			m._track._invert[val] = key
		    m._track._count = key
	    end

		m._track._default = 1
	elseif type(t) == 'boolean' or t == nil then
		m._track._type = 'boolean'
		m._track._default = t or false
    	m._track._description = args[1]
	elseif type(t)=='string' and #args == 0 then
		m._track._type = 'boolean'
		m._track._default = false
    	m._track._description = t
	else
		-- Construction failure
		error("Unable to construct a mode table with the provided parameters.", 2)
	end

    m._track._current = m._track._default

    return setmetatable(m, _meta.M)
end


-- Metamethods
-- Functions that will be used as metamethods for the class

-- Handler for __index when trying to access the current mode value.
-- Handles indexing 'current' or 'value' keys.
_meta.M.__index = function(m, k)
	if type(k) == 'string' then
		local lk = k:lower()
		if lk == 'current' or lk == 'value' then
			if m._track._type == 'boolean' then
				if lk == 'value' then
					return m._track._current and 'on' or 'off'
				else
					return m._track._current
				end
			else
				return m[m._track._current]
			end
		elseif lk == 'description' then
			return m._track._description
		else
			return _meta.M.__methods[lk]
		end
	end
end

-- Tostring handler for printing out the table and its current state.
_meta.M.__tostring = function(m)
    local res = ''
    if m._track._description then
    	res = res .. m._track._description .. ': '
    end

	if m._track._type == 'list' then
	    res = res .. '{'
	    for k,v in ipairs(m) do
	        res = res..tostring(v)
	        if m[k+1] ~= nil then
	            res = res..', '
	        end
	    end
	    res = res..'}' 
	else
		res = res .. 'Boolean'
	end
	
    res = res .. ' ('..tostring(m.Current).. ')'
    
    -- Debug addition
    --res = res .. ' [' .. m._track._type .. '/' .. tostring(m._track._current) .. ']'

    return res
end


-- Public methods
-- Functions that will be used as public methods for the class

_meta.M.__methods = {}

-- Cycle forwards through the list
_meta.M.__methods['cycle'] = function(m)
	if m._track._type == 'list' then
		m._track._current = (m._track._current % m._track._count) + 1
	else
		m:toggle()
	end
	
	return m.Current
end

-- Cycle backwards through the list
_meta.M.__methods['cycleback'] = function(m)
	if m._track._type == 'list' then
		m._track._current = m._track._current - 1
		if  m._track._current < 1 then
			m._track._current = m._track._count
		end
	else
		m:toggle()
	end

	return m.Current
end

-- Toggle a boolean value
_meta.M.__methods['toggle'] = function(m)
	if m._track._type == 'boolean' then
		m._track._current = not m._track._current
	else
		error("Cannot toggle a list mode.", 2)
	end

	return m.Current
end

-- Set the current value
_meta.M.__methods['set'] = function(m, val)
	if m._track._type == 'boolean' then
		if type(val) == 'boolean' then
			m._track._current = val
		elseif type(val) == 'string' then
			val = val:lower()
			if val == 'on' or val == 'true' then
				m._track._current = true
			elseif val == 'off' or val == 'false' then
				m._track._current = false
			else
				error("Unrecognized value: "..val, 2)
			end
		else
			error("Unrecognized value type: "..type(val), 2)
		end
	else
		if m._track._invert[val] then
			m._track._current = m._track._invert[val]
		else
			local found = false
		    for v, ind in pairs(m._track._invert) do
		    	if val:lower() == v:lower() then
					m._track._current = ind
					found = true
					break
		    	end
		    end
		    
		    if not found then
		    	error("Unknown mode value: " .. tostring(val), 2)
		    end
		end
	end

	return m.Current
end

-- Reset to the default value
_meta.M.__methods['reset'] = function(m)
    m._track._current = m._track._default

	return m.Current
end

-- Function to set the table's description.
_meta.M.__methods['describe'] = function(m, str)
	if type(str) == 'string' then
    	m._track._description = str
    else
    	error("Invalid argument type: " .. type(str), 2)
	end
end

