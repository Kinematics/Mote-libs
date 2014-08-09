-------------------------------------------------------------------------------------------------------------------
-- This include library allows use of specially-designed tables for tracking
-- certain types of modes and state.
--
-- Construction syntax:
--
-- 1) Create a new list of mode values (the first value will always be the default):
-- MeleeMode = M{'Normal', 'Acc', 'Att'} -- Pass in a table, using braces
-- MeleeMode = M('Normal', 'Acc', 'Att') -- Pass in a list of strings, using parentheses
-- MeleeMode = M(anotherTable) -- Pass in a reference to another table, using parentheses
--
-- 2) Create a boolean toggle mode with a default value of false (note parentheses):
-- UseLuzafRing = M()
-- UseLuzafRing = M(false)
-- Create a boolean toggle mode with a default value of true:
-- UseLuzafRing = M(true)
--
--
-- Public functions:
--
-- Assuming a Mode variable 'm':
--
-- 1) m:cycle() -- Cycles through the list going forwards.  Acts as a toggle on boolean mode vars.
-- 2) m:cycleback() -- Cycles through the list going backwards.  Acts as a toggle on boolean mode vars.
-- 3) m:toggle() -- Toggles a boolean Mode between true and false.
-- 4) m:set(n) -- Sets the current mode value to n.
-- 5) m:reset() -- Returns the mode var to its default state.
-- 6) m.current, m.value -- Gets the current mode value (current/value field is case-insensitive).
--
-- All functions return the current value after completion.
-------------------------------------------------------------------------------------------------------------------

_meta = _meta or {}
_meta.M = {}

-- Default constructor for mode tables
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
	if type(t) == 'table' and #t > 0 then
		m._track._type = 'list'
		
		-- Only copy numerically indexed values
	    for ind, val in ipairs(t) do
	        m[ind] = val
	    end

	    m._track._invert = {}
	    m._track._count = 0
	    for key,val in ipairs(m) do
			m._track._invert[val] = key
		    m._track._count = key
	    end

		m._track._default = 1
	elseif type(t) == 'boolean' or t == nil or #t == 0 then
		m._track._type = 'boolean'
		
		if t then
			m._track._default = true
		else
			m._track._default = false
		end
	else
		-- Construction failure
		return nil
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
				return m._track._current
			else
				return m[m._track._current]
			end
		else
			return _meta.M.__methods[k]
		end
	end
end

-- Tostring handler for printing out the table and its current state.
_meta.M.__tostring = function(m)
    local res = ''
	if m._track._type == 'list' then
	    res = '{'
	    for k,v in ipairs(m) do
	        res = res..tostring(v)
	        if m[k+1] ~= nil then
	            res = res..', '
	        end
	    end
	    res = res..'}' 
	else
		res = 'Boolean'
	end
	
    res = res .. ' ('..tostring(m.Current).. ')'
    
    -- Debug addition
    res = res .. ' [' .. m._track._type .. '/' .. tostring(m._track._current) .. ']'

    return res
end



-- Public methods
-- Functions that will be used as public methods for the class

_meta.M.__methods = {}

_meta.M.__methods['cycle'] = function(m)
	if m._track._type == 'list' then
		m._track._current = (m._track._current % m._track._count) + 1
	else
		m:toggle()
	end
	
	return m.Current
end

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

_meta.M.__methods['toggle'] = function(m)
	if m._track._type == 'boolean' then
		m._track._current = not m._track._current
	else
		error("Cannot toggle a list mode.")
	end

	return m.Current
end

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
				error("Unrecognized value: "..val)
			end
		else
			error("Unrecognized value type: "..type(val))
		end
	else
	end

	return m.Current
end

_meta.M.__methods['reset'] = function(m)
    m._track._current = m._track._default

	return m.Current
end


