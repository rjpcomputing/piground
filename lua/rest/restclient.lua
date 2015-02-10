----------------------------------------------------------------------
-- RestClient:
-- A library that simplifies interaction with REST APIs.
----------------------------------------------------------------------

-- Deps:
local socket	= require( "socket" )
local http		= require( "socket.http" )
local json		= require( "json" )
local class		= require( "pl.class" )
local utils		= require( "pl.utils" )
local pretty	= require( "pl.pretty" )

local function UrlEncode( urlParameters )
	urlParameters = tostring( urlParameters )
	return urlParameters:gsub( "([^A-Za-z0-9.%-~_ ])", function( c ) return ("%%%02X"):format( string.byte( c ) ) end ):gsub( " ", "+" )
end

local function FormEncode( form )
	if form and next( form ) then
		local result = {}
		if form[1] then -- Array of ordered { { name = "name1", value = "value1" }, { name = "name2", value = "value2" } }
			for _, field in ipairs( form ) do
				result[1 + #result] = ("%s=%s"):format( UrlEncode( field.name ), UrlEncode( field.value ) )
			end
		else -- Unordered map of name -> value { field1 = "value1", field2 = "value2", ... }
			for name, value in pairs( form ) do
				result[1 + #result] = ("%s=%s"):format( UrlEncode( name ), UrlEncode( value ) )
			end
		end

		return table.concat( result, "&" )
	end
end

local RestClient = class()

function RestClient:_init( host )
	utils.assert_string( 1, host )
	self.host = host
end

---
function RestClient:Get( pathPart, args )
	utils.assert_string( 1, pathPart )
	args = args or {}

	local url = ("%s/%s"):format( self.host, pathPart )
	local query = args.query
	local format = args.format or "raw" -- or "json"

	local response, code, header, status = http.request( self:FormatUrl( url, query ) )
	if response then
		-- Encode into given format
		if header["content-type"] == "application/json" or format == "json" then
			local ok, res = pcall( json.decode, response )
			if ok then response = res end
		end
	else
		error( ("Error occured when calling GET on '%s'. Details: %s"):format( self:FormatUrl( url, query ), code ) )
	end

	-- WARNING: Only for old style errors that pass them through status code messages
	if code > 299 then
		if not response then response = status:match( "HTTP/1%.1%s%d%d%d%s(.-)$" ) end
	end

	--return { body = response, code = code, status = status, header = header }
	return response, code
end

function RestClient:Post( pathPart, args )
	utils.assert_string( 1, pathPart )
	args = args or {}

	local url = ("%s/%s"):format( self.host, pathPart )
	local form = FormEncode( args.data ) or ""
	local format = args.format or "raw"  -- or "json"
	local response, code, header, status = http.request( url, form )
	if response then
		-- Encode into given format
		if header["content-type"] == "application/json" or format == "json" then
			local ok, res = pcall( json.decode, response )
			if ok then response = res end
		end
	else
		error( ("Error occured when calling POST on '%s' with form data '%s'. Details: %s"):format( url, FormEncode( form ), code ) )
	end

	-- WARNING: Only for old style errors that pass them through status code messages
	if code > 299 then
		if not response then response = status:match( "HTTP/1%.1%s%d%d%d%s(.-)$" ) end
	end

	--return { body = response, code = code, status = status, header = header }
	return response, code
end

function RestClient:Delete( pathPart, args )
	utils.assert_string( 1, pathPart )
	args = args or {}

	local url = ("%s/%s"):format( self.host, pathPart )
	local form = FormEncode( args.data ) or ""
	local format = args.format or "raw"  -- or "json"

	local payload = form
	local response = {}
	local ok, code, header, status = http.request
	{
		url = url,
		method = "DELETE",
		source = ltn12.source.string( payload ),
		sink = ltn12.sink.table( response ),
		headers =
		{
			["content-Type"] = "application/x-www-form-urlencoded",
			["content-length"] = #payload,
		}
	}

	if ok then
		response = table.concat( response )
		-- Encode into given format
		if header["content-type"] == "application/json" or format == "json" then
			response = json.decode( response )
		end
	else
		error( ("Error occured when calling DELETE on '%s' with form data '%s'. Details: %s"):format( url, payload, code ) )
	end

	-- WARNING: Only for old style errors that pass them through status code messages
	if code > 299 then
		if not response then response = status:match( "HTTP/1%.1%s%d%d%d%s(.-)$" ) end
	end

	--return { body = response, code = code, status = status, header = header }
	return response, code
end

function RestClient:FormatUrl( url, options )
	local query = FormEncode( options )

	-- Create full URL
	if query then url = url .. "?" .. query end

	return url
end

return RestClient
