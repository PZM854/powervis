function plot_zone_merge_steps(digraph_nominal, digraph_zonescale_offset, TopPilotnode, table_islands, CaseName)
    % get num of zones
    num_zone = size(table_islands, 1);    
    % page 0, graph of intact network
    draw_zone_merge_page(digraph_nominal, digraph_zonescale_offset, TopPilotnode, table_islands, 0, CaseName);

    % page 1~n：page 1-n, merge step for zone n
    for zone_id = 1:num_zone
        draw_zone_merge_page(digraph_nominal, digraph_zonescale_offset, TopPilotnode, table_islands, zone_id, CaseName);
    end
end