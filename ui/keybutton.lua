local keybutton = {}

local function graph_from_frame(frame)
    local g = graph.create()
        :branch("base_color", gfx_nodes.color.dot, 1, 1, 1)
        :branch("texture", gfx_nodes.sprite, frame)

    for name, slice in pairs(frame.slices) do
        g:back("texture")
        g:branch(
            join("slice", name), gfx_nodes.spatial.set,
            slice:scale(2, 2):unpack()
        )
    end

    return g
end

function keybutton:create()
    local prop_atlas = get_atlas("art/props")

    self.draw_graph = graph_from_frame(
        prop_atlas:get_animation("button"):head()
    )
    self.draw_graph
        :back("slice/textbox")
        :branch("text_color", gfx_nodes.color.dot, 0, 0, 0)
        :leaf(gfx_nodes.draw_rect, "line")
end

function keybutton:__draw()
    self.draw_graph:traverse()
end

function keybutton:test(settings)
    --settings.origin = true
end

return keybutton
