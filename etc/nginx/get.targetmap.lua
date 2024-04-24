
-- jwt_token MUST be set ngx.var.jwt_token
-- set $jwt_token          $2;     # jwt contains the encrypted ip address
local jwt_token = ngx.var.jwt_token


-- from: https://github.com/openresty/lua-nginx-module/issues/60
-- According to ngx_lua's documentation here
-- (http://wiki.nginx.org/HttpLuaModule#ngx.exit ),
-- When status >= 200 (ngx.HTTP_OK), 
-- it will interrupt the execution of the current Lua thread and returns status code to nginx.
-- When status == 0 (ngx.OK), it will quits the current phase handler
-- (or content handler if content_by_lua directives are used). "
-- 
-- So the following should work and quit the whole request, though quite
-- unintuitive:
-- 
--       ngx.status = 410
--       ngx.say("hello, world")
--       ngx.exit(ngx.HTTP_OK)
--
--
-- Nginx log level constants
--   ngx.STDERR
--   ngx.EMERG
--   ngx.ALERT
--   ngx.CRIT
--   ngx.ERR
--   ngx.WARN
--   ngx.NOTICE
--   ngx.INFO
--   ngx.DEBUG


function ngxexitresponse( status, msg )
    ngx.status = status
    ngx.log( ngx.ERR, msg )
    ngx.say(msg)
    ngx.exit(ngx.HTTP_OK)
end


function readfile(filename)
    local f = assert(io.open(filename, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

local function decrypt(msg, private_key )
    local rsa = require "resty.rsa"
    local priv, err = rsa:new({ private_key = private_key })
    if priv == nil then	
	ngxexitresponse( ngx.HTTP_SERVICE_UNAVAILABLE, err )
    end 
    local crypto = ngx.decode_base64(msg)
    if crypto == nil then
	ngxexitresponse( ngx.HTTP_UNAUTHORIZED, 'decode_base64 bad format' )
    end
    local decrypted, err = priv:decrypt( crypto )
    if decrypted == nil then
	ngxexitresponse( ngx.HTTP_UNAUTHORIZED, err )
    end
    return decrypted
end

local function no_bearer( mystring )
   pattern = 'Bearer '
   len_pattern = 7
   --- 7 = len(pattern) 
   header = string.sub(mystring, 1, len_pattern)
   --- ngx.log(ngx.ALERT, 'header is :' .. header .. ':' )
   if header == pattern then
        --- remove the 'Bearer '
        mystring = string.sub(mystring, len_pattern + 1 )
   end
   return mystring
end


-- Check if jwt_token exists
if not jwt_token then
	ngxexitresponse( ngx.HTTP_UNAUTHORIZED, 'jwt_token is nil')
end

--- if the jwt_token start with 'Bearer '
--- Authorization: Bearer <token>
--- remove the 'Bearer '
jwt_token = no_bearer( jwt_token )

-- Get the cached valued if exists
local target 	        = ngx.shared.targetmap:get( jwt_token )

-- if cached value does not exist
if target == nil then
	-- cached value does not exist
	local jwt 		= require "resty.jwt"

	local jwt_secret = ngx.shared.rsakeymap:get( 'jwt_desktop_signing_public_key' )
	if jwt_secret == nil then
		jwt_secret = readfile( os.getenv("JWT_DESKTOP_SIGNING_PUBLIC_KEY") )
		ngx.shared.rsakeymap:set( 'jwt_desktop_signing_public_key', jwt_secret )
	end

	local jwt_obj = jwt:verify( jwt_secret, jwt_token)

	if not jwt_obj["verified"] then
		ngx.log( ngx.ERR, 'jwt_token=' .. jwt_token )
		ngxexitresponse( ngx.HTTP_UNAUTHORIZED, jwt_obj.reason )
	end

	local payload = jwt_obj.payload

	if payload == nil then
		ngxexitresponse( ngx.HTTP_UNAUTHORIZED,  'missing payload in jwt')
	end

	if not payload.hash then
		ngxexitresponse( ngx.HTTP_UNAUTHORIZED, 'missing payload.hash in jwt')
	end

	--- ngx.log(ngx.ALERT, 'payload.has is' .. payload.hash )
        local private_key = ngx.shared.rsakeymap:get( 'jwt_desktop_payload_private_key' )
        if private_key == nil then
		private_key = readfile( os.getenv("JWT_DESKTOP_PAYLOAD_PRIVATE_KEY") )
		-- store the private key
		ngx.shared.rsakeymap:set( 'jwt_desktop_payload_private_key', private_key )
	end

	targetres = decrypt( payload.hash, private_key)
	  	
	if targetres == nil then
		ngxexitresponse( ngx.HTTP_UNAUTHORIZED, 'payload can not be decrypted' )
	else
		target = targetres
		-- set the key to value target and exprire in exp value from jwt
		-- The optional exptime argument specifies expiration time (in seconds) for the inserted key-value pair.  
		local currenttime = ngx.time()
		local expire_value = payload.exp - currenttime

                -- fixe data expire max value to 10 min = 600 s
		-- protect cache against unlimited or dummy value
                if expire_value > 600 then
                   expire_value = 600
		end

		-- do not add bad expired value 
		-- if data expire is less than 1 s or nagative value
                -- do not cache it
		if expire_value > 1 then
			-- to read notice log 
			-- add notive keyworks to nginx.conf
			-- error_log /var/log/nginx/error.log notice;
			-- example in error.log 
			-- 2020/05/14 08:24:33 [notice] 154#154: *2780 [lua] get.targetmap.lua:148: 
			-- cached for: 58s target: 5bf1433b-7e9a-47f7-8c3a-4bf18e5a9418.desktop.abcdesktop.svc.cluster.local, 
			-- client: 192.168.65.3, server: _, 
			-- request: "POST /spawner/getproclist HTTP/1.1", host: "localhost:30443", referrer: "http://localhost:30443/"
			ngx.log( ngx.NOTICE, 'cached for: ' .. expire_value .. 's target: ' .. targetres )  
			ngx.shared.targetmap:set( jwt_token, target, expire_value )
		end
        end
end

ngx.var.target 		= target

