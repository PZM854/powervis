function plot_all_plow_flow(digraph_zonescale_offset, TopPilotnode)

num_zone = size(digraph_zonescale_offset.Nodes, 1);
for i = 1:num_zone
    draw_zone_power_flow(digraph_zonescale_offset, i, CaseName);
end

end

