utils = {}

utils.extract_headers = function (email_text)
    local headers = {}
    local current_header = nil
    local body_start = 1

    -- Iterate through each line of the email
    for line in email_text:gmatch("([^\r\n]*)[\r\n]?") do
        -- Check if we've reached the end of headers (blank line)
        if line == "" then
            body_start = body_start + #line + 1
            break
        end

        -- Check if this line is a continuation of the previous header
        if line:match("^%s") and current_header then
            headers[current_header] = headers[current_header] .. " " .. line:match("^%s*(.*)")
        else
            -- This is a new header
            local name, value = line:match("^([^:]+):%s*(.*)")
            if name and value then
                name = name:lower() -- Convert header name to lowercase for consistency
                headers[name] = value
                current_header = name
            end
        end

        body_start = body_start + #line + 1
    end

    -- Extract the body
    local body = email_text:sub(body_start)

    return headers, body
end

return utils