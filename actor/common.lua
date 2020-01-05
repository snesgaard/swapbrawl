local common = {}

function common.declare_chant(name, help)
    return {
        name=name,
        help=help,
        target={type="self"},
        animation = function(root, epic, user)
            local sprite = get_sprite(root, user)
            if not sprite.chant then
                sprite.chant = sprite:child(require "sfx.chant")
            end
            sprite:queue("idle2chant", "chant")
            event:sleep(0.5)
        end
    }
end

function common.declare_cast_animation(casting_func)
    return function(root, epic, user, ...)
        local sprite = get_sprite(root, user)
        sprite:queue({"chant2cast", loop=false})
        event:wait(sprite, "finish")
        sprite:queue("cast")

        if casting_func then
            casting_func(root, epic, user, ...)
        else
            root:broadcast(unpack(epic))
            event:sleep(0.7)
        end

        if sprite.chant then
            sprite.chant:halt()
            sprite.chant = nil
        end
        sprite:queue("cast2idle", "idle")
    end
end

return common
