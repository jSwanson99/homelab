local domain = ssl.server_name()
if not domain or domain == "" then
	ngx.log(ngx.WARN, "No SNI provided")
	return
end

-- Sanitize domain name
domain = domain:gsub("[^%w%-%.]", "_")

local cert_path = "/etc/pki/nginx/certs/" .. domain .. ".crt"
local key_path = "/etc/pki/nginx/certs/" .. domain .. ".key"

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function file_age(path)
	local handle = io.popen("stat -c %Y " .. path .. " 2>/dev/null")
	local result = handle:read("*a")
	handle:close()
	return tonumber(result) or 0
end

-- Check if cert exists and is not too old (30 days)
local need_regenerate = false
if not file_exists(cert_path) or not file_exists(key_path) then
	need_regenerate = true
else
	local age = os.time() - file_age(cert_path)
	if age > 30 * 24 * 60 * 60 then
		need_regenerate = true
		ngx.log(ngx.INFO, "Certificate for " .. domain .. " is older than 30 days, regenerating")
	end
end

if need_regenerate then
	-- Lock to prevent concurrent generation
	local lock_key = "certgen:" .. domain
	local locked = cache:add(lock_key, true, 60)

	if locked then
		ngx.log(ngx.INFO, "Generating certificate for " .. domain)
		local ret = os.execute("/etc/pki/nginx/sign.sh " .. domain .. " 2>&1")
		cache:delete(lock_key)

		if ret ~= 0 then
			ngx.log(ngx.ERR, "Certificate generation failed for " .. domain)
			return
		end
	else
		-- Wait for other worker to generate
		ngx.sleep(0.1)
		local attempts = 0
		while not file_exists(cert_path) and attempts < 50 do
			ngx.sleep(0.1)
			attempts = attempts + 1
		end
	end
end

-- Read certificate and key
local f = io.open(cert_path, "r")
if not f then
	ngx.log(ngx.ERR, "Failed to open cert file: " .. cert_path)
	return
end
local cert_data = f:read("*a")
f:close()

f = io.open(key_path, "r")
if not f then
	ngx.log(ngx.ERR, "Failed to open key file: " .. key_path)
	return
end
local key_data = f:read("*a")
f:close()

-- Parse and set certificate
local cert_der, err = ssl.parse_pem_cert(cert_data)
if not cert_der then
	ngx.log(ngx.ERR, "Failed to parse cert: " .. (err or "unknown error"))
	return
end

local key_der, err = ssl.parse_pem_priv_key(key_data)
if not key_der then
	ngx.log(ngx.ERR, "Failed to parse key: " .. (err or "unknown error"))
	return
end

-- Clear existing certs and set new ones
ssl.clear_certs()

local ok, err = ssl.set_cert(cert_der)
if not ok then
	ngx.log(ngx.ERR, "Failed to set cert: " .. err)
	return
end

ok, err = ssl.set_priv_key(key_der)
if not ok then
	ngx.log(ngx.ERR, "Failed to set key: " .. err)
	return
end

ngx.log(ngx.INFO, "Successfully loaded certificate for " .. domain)

