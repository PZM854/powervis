function multi_graph = table_to_multigraph(T, table_zone, digraph_nominal)

% from table to multigraph

% multigraph: only realize nodal aggregation, have not do edge combination yet. 

table_islands = [table_zone.nodelist table_zone.edgelist];
cell_zone = table_islands;

table_zonescale_multi = table( ...
   [T.fromzone T.tozone], ...
    T.SendingMW, ...
    (1:height(T))', ...
    'VariableNames', ["EndNodes","SendingMW","ori_index"]);

num_node_zone = [];
num_zone = size(table_islands,1);
for thiszone = 1:num_zone
    num_node_zone = [num_node_zone length(cell_zone{thiszone,1})];
end
volt_zone = [];
for thiszone = 1:num_zone
    volt_zone = [volt_zone table_zone.OpVolt(thiszone)];
end

multi_graph = digraph(table_zonescale_multi);
multi_graph.Nodes.num_node = num_node_zone';
multi_graph.Nodes.OpVolt = volt_zone';

end

