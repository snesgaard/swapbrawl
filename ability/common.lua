local common = {}

function common.wait_for_hitbox(handle, topic, name, timeout)
    local pre = love.timer.getTime()
    local event_args = handle:wait(topic, timeout)
    if event_args.event == "timeout" then
        log.warn("Animation waiting timed out")
        return
    end
    local hitboxes = event_args[1]
    local dt = love.timer.getTime() - pre
    if not hitboxes[name] then
        return common.wait_for_hitbox(handle, topic, name, timeout - dt)
    else
        return hitboxes[name], hitboxes
    end
end


return common
