function draw_zone_merge_page(digraph_nominal, digraph_zonescale_offset, TopPilotnode, table_islands, active_zone, CaseName)
    num_zone = size(table_islands, 1);
    num_node = size(digraph_nominal.Nodes, 1);
    gray_color = [0.88 0.88 0.88];
    num_color = length(unique(digraph_nominal.Nodes.Volt));
    % prepare color for raw graph
    p_raw = to_picture_raw(digraph_nominal, CaseName);
    color_raw = p_raw.NodeColor;
    if active_zone == 0
        % for i = 1:num_node
        %     color_raw(i, :) = gray_color;
        % end
    else
        for i = 1:num_node
            if ~ismember(i, table_islands{active_zone, 1})
                color_raw(i, :) = gray_color;
            end
        end
    end
    close;

    % prepare color for zonal graph
    p_zone = to_picture(digraph_zonescale_offset, TopPilotnode, table_islands, CaseName, 'force');
    color_zone = p_zone.NodeColor;
    if active_zone == 0
        % for i = 1:num_zone
        %     color_zone(i, :) = gray_color;
        % end
    else
        for i = 1:num_zone
            if i ~= active_zone
                color_zone(i, :) = gray_color;
            end
        end
    end
    close;

    % to graph
    % figure('Position', [100 100 1200 600])
    % tiledlayout(1,2,'Padding','compact');

    % left：raw
    % p_raw = to_picture_raw(digraph_nominal, CaseName);
    % [X_data, Y_data] = get_pos_by_p(p_raw);
    % close;

    %nexttile;
    p1 = to_picture_raw(digraph_nominal, CaseName, 'info', 0);
    p1.NodeColor = color_raw;
    title(sprintf('Original Graph (Zone %d)', active_zone));

    % right：zone
    % p_zone = to_picture(digraph_zonescale_offset, TopPilotnode, table_islands, CaseName);
    % [X_data, Y_data] = get_pos_by_p(p_zone);
    % close;

    %nexttile;
    p2 = to_picture(digraph_zonescale_offset, TopPilotnode, table_islands, CaseName, 'force', 'info', 0);
    p2.NodeColor = color_zone;
    title(sprintf('Zonal Graph (Zone %d)', active_zone));

    % save image
    % saveas(gcf, sprintf('merge_step_zone_%d_%s.png', active_zone, CaseName));
end