function x_coord = get_X_data_by_Y(G, y_coord)
    % input：
    %   G       - digraph object（zone scale）
    %   y_coord - y coordinate of each node (fixed)
    % output：
    %   x_coord - x coordinate of each node

    num_nodes = numnodes(G);    %23
    x_coord = zeros(num_nodes, 1);  %[0, 0...0] 

    % 
    unique_y = sort(unique(y_coord), 'descend');    %[-1,..,-10]
    num_layers = length(unique_y);  %10

    % 
    layer_of_node = zeros(num_nodes, 1);
    for i = 1:num_layers
        layer_of_node(y_coord == unique_y(i)) = i;
    end

    % 
    for i = 2:num_layers
        curr_nodes = find(layer_of_node == i);
        barycenters = zeros(length(curr_nodes), 1);

        for j = 1:length(curr_nodes)
            node = curr_nodes(j);
            preds = predecessors(G, node);  % 
            if ~isempty(preds)
                barycenters(j) = mean(x_coord(preds));
            else
                barycenters(j) = j; % 
            end
        end

        % 
        [~, sort_idx] = sort(barycenters);
        spacing = 10; 
        num_curr = length(curr_nodes);
        center = (num_curr + 1) / 2;
        for k = 1:num_curr
            x_coord(curr_nodes(sort_idx(k))) = (k - center) * spacing;
        end
    end

    % 
    top_nodes = find(layer_of_node == 1);
    spacing = 10;
    num_top = length(top_nodes);
    center = (num_top + 1) / 2;
    for k = 1:num_top
        x_coord(top_nodes(k)) = (k - center) * spacing;
    end
end