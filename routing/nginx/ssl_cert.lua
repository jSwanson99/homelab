local domain = ssl.server_name()

if not domain or domain == "" then
	return
end

if not cache:get(domain) then
	os.execute("/etc/pki/nginx/sign.sh " .. domain)
	cache:set(domain, true)
end

local cert_path = "/etc/pki/nginx/certs/" .. domain .. ".crt"
local key_path = "/etc/pki/nginx/certs/" .. domain .. ".key"

local f = io.open(cert_path)
if not f then
	ngx.log(ngx.ERR, domain .. " | Failed to open cert file: ", cert_path)
	return
end
local cert_data = f:read("*a")
f:close()

f = io.open(key_path)
if not f then
	ngx.log(ngx.ERR, domain .. " | Failed to open key file: ", key_path)
	return
end
local key_data = f:read("*a")
f:close()

local cert_der = ssl.parse_pem_cert(cert_data)
if not cert_der then
	ngx.log(ngx.ERR, domain .. " | Failed to parse PEM cert")
	return
end

local key_der = ssl.parse_pem_priv_key(key_data)
if not key_der then
	ngx.log(ngx.ERR, domain .. " | Failed to parse PEM key")
	return
end

ssl.clear_certs()
local ok, err = ssl.set_cert(cert_der)
if not ok then
	ngx.log(ngx.ERR, domain .. " | Failed to set cert: " .. err)
	return
end

ok, err = ssl.set_priv_key(key_der)
if not ok then
	ngx.log(ngx.ERR, domain .. " | Failed to set key: " .. err)
	return
end
