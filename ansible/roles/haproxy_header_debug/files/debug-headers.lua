-- /etc/haproxy/lua/debug-headers.lua

core.register_service("debug_headers", "http", function(applet)
    local response = "Request Headers:\n"
    response = response .. "================\n"
    
    -- Get all request headers
    local headers = applet.headers
    for name, values in pairs(headers) do
        for _, value in pairs(values) do
            response = response .. name .. ": " .. value .. "\n"
        end
    end
    
    response = response .. "\nConnection Info:\n"
    response = response .. "================\n"
    response = response .. "Client IP: " .. applet.sf:src() .. "\n"
    response = response .. "Client Port: " .. applet.sf:src_port() .. "\n"
    response = response .. "Server IP: " .. applet.sf:dst() .. "\n"
    response = response .. "Server Port: " .. applet.sf:dst_port() .. "\n"
    response = response .. "Method: " .. applet.method .. "\n"
    response = response .. "Path: " .. applet.path .. "\n"
    response = response .. "Query: " .. (applet.qs or "") .. "\n"
    
    applet:set_status(200)
    applet:add_header("Content-Type", "text/plain")
    applet:add_header("Content-Length", string.len(response))
    applet:start_response()
    applet:send(response)
end)
