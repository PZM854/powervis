function [digraph_zonescale_offset, digraph_zonescale_wheel, table_edge_withtrans_temp] = zonal_aggregation(table_islands, digraph_nominal, ...
    index_edge_withtrans)

num_zone = size(table_islands,1);
cell_zone = table_islands;

num_node_zone = [];
for thiszone = 1:num_zone
    num_node_zone = [num_node_zone length(cell_zone{thiszone,1})];
end

num_edge_zone = [];
for thiszone = 1:num_zone
    num_edge_zone = [num_edge_zone length(cell_zone{thiszone,2})];
end
num_edge_withtrans = length(index_edge_withtrans);

volt_zone = [];
for thiszone = 1:num_zone
    volt_zone = [volt_zone digraph_nominal.Nodes.Volt(cell_zone{thiszone,1}(1))];
end

table_node = sortrows(digraph_nominal.Nodes, "uni_index");  %sorted
table_edge = sortrows(digraph_nominal.Edges, "EdgeOrigIndex");  %sorted

table_edge_withtrans = table_edge(find(table_edge.IsTrafo == 1), :) ;
node_edgewithtrans_from = table_edge_withtrans.EndNodes(:,1);
node_edgewithtrans_to = table_edge_withtrans.EndNodes(:,2);
table_edge_withtrans.fromzone = table_node.zone(node_edgewithtrans_from);
table_edge_withtrans.tozone = table_node.zone(node_edgewithtrans_to);


table_edge_withtrans_temp = sort_table(table_edge_withtrans,'key', {'fromzone', 'tozone'}, 'directions', 'ascend');% multi-graph
edge_forzone_combined = edge_combination(table_edge_withtrans_temp, 'SendingMW', {'fromzone','tozone'});
edge_forzone_combined = sortrows(edge_forzone_combined, [1 2]);

edge_forzone_offsetted = edge_offset(edge_forzone_combined, 3, [1 2]);
edge_forzone_offsetted = sortrows(edge_forzone_offsetted, [1 2]);

edge_forzone = [edge_forzone_offsetted [1:size(edge_forzone_offsetted,1)]'];

table_zonescale = table([edge_forzone(:,1), edge_forzone(:,2)], [edge_forzone(:,3)], edge_forzone(:,4),...
    'VariableNames',["EndNodes", "SendingMW", "ori_index"]);
table_zonescale = sortrows(table_zonescale, "ori_index");
num_trans = size(table_edge_withtrans_temp,1);

digraph_zonescale_offset = digraph(table_zonescale);
digraph_zonescale_offset.Nodes.num_node = num_node_zone';
digraph_zonescale_offset.Nodes.OpVolt = volt_zone';

%wheel_1 after combination before aggregation
edge_forzone_wheel = [edge_forzone_combined [1:size(edge_forzone_combined,1)]'];
table_zonescale_wheel = table([edge_forzone_wheel(:,1), edge_forzone_wheel(:,2)], [edge_forzone_wheel(:,3)], edge_forzone_wheel(:,4),...
    'VariableNames', ["EndNodes", "SendingMW", "ori_index"]);
table_zonescale_wheel = sortrows(table_zonescale_wheel, "ori_index");

digraph_zonescale_wheel = digraph(table_zonescale_wheel);
digraph_zonescale_wheel.Nodes.num_node = num_node_zone';
digraph_zonescale_wheel.Nodes.OpVolt = volt_zone';


end

