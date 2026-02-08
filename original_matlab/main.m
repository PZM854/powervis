clear;  
clc;
define_constants;       

rng(0);
% ========================= 1. load a case =========================
%CaseName = 'pglib_opf_case73_ieee_rts';
%CaseName = 'case2869pegase';
%CaseName = 'case9241pegase';
CaseName = 'pglib_opf_case162_ieee_dtc';
%CaseName = 'case300';
%CaseName = 'pglib_opf_case300_ieee';
%CaseName = 'pglib_opf_case179_goc';  % unique volt_level
%CaseName = 'pglib_opf_case118_ieee';

CasePath = ['E:\MATLAB\R2018b\bin\matpower6.0\' CaseName '.m'];
% ========================= 2. waterfall technique =========================

[TopPilotnode, case_WT] = waterfall(CaseName);
% ========================= 3. zone defination =========================

[table_islands, graph_nominal, digraph_nominal,...
    index_edge_withtrans, index_nodes_oftrans] = zonelabeller(case_WT);

% ========================= 4. zone aggregation and visualization =========================

[digraph_zonescale_offset, digraph_zonescale_wheel, table_edge_withtrans_temp] = zonal_aggregation(table_islands, digraph_nominal, index_edge_withtrans);

% ========================= 5. current work =========================

% record each zone's nodes and edges
table_zone = digraph_zonescale_offset.Nodes;
cell_zone = table_islands;

for thiszone = 1:size(table_zone,1)
    table_zone.nodelist{thiszone} = cell_zone{thiszone,1};
    table_zone.edgelist{thiszone} = cell_zone{thiszone,2};
end


[volt_branch_ope, bool_branch_trans, table_branch_ope] = powerflow_to_table(case_WT);

table_oriedge_raw = table_branch_ope;

digraph_ori_raw = digraph_nominal;

table_oriedge_combined = edge_combination(table_oriedge_raw, 'SendingMW', 'EndNodes');

%table_oriedge_offsetted = sortrows(edge_offset(table_oriedge_combined, 3, [1 2]), [1 2]);
table_oriedge_offsetted = sortrows(table_oriedge_combined, [1 2]);
table_oriedge_offsetted = [table_oriedge_offsetted [1:size(table_oriedge_offsetted,1)]'];


table_ori_offsetted = table([table_oriedge_offsetted(:,1) table_oriedge_offsetted(:,2)], table_oriedge_offsetted(:,3), table_oriedge_offsetted(:,4), ...
    'VariableNames',["EndNodes", "SendingMW", "ori_index"]);

digraph_ori_offsetted = table_to_graph(table_ori_offsetted, case_WT, 'digraph');

% multi-graph
digraph_zonescale_multi = table_to_multigraph(table_edge_withtrans_temp, table_zone, digraph_nominal);

% wheel

 % to_picture_raw(digraph_ori_raw, CaseName);
  to_picture_raw(digraph_ori_offsetted, CaseName);
 % to_picture(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, 'layered', 'info', 0);
 to_picture(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, 'force', 'info', 0);

tic
digraph_zonescale_offset = digraph_ori_offsetted;
dir_edge = min_sNs(digraph_zonescale_offset);
toc


A = adjacency(digraph_zonescale_offset);
A = A | A.';    
A = double(A); 
n = numnodes(digraph_zonescale_offset);
[i,j] = find(triu(A,1));
E = [i,j];
m = size(E,1);
DG_zonescale_offset_temp = digraph_zonescale_offset;
edges_new = DG_zonescale_offset_temp.Edges;
for e = 1:size(dir_edge, 1)
    u = E(e, 1);
    v = E(e, 2);
    if dir_edge(e) == 0
        edges_new.EndNodes(e, :) = [u, v];
    else
        edges_new.EndNodes(e, :) = [v, u];
    end

end
DG_zonescale_offset_temp = digraph(edges_new);
DG_zonescale_offset_temp.Nodes = digraph_zonescale_offset.Nodes;

%to_picture(DG_zonescale_offset_temp, TopPilotnode, cell_zone, CaseName, 'layered', 'info', 0);
to_picture_raw(DG_zonescale_offset_temp, CaseName);
% filename = ['sample',CaseName, datestr(now,'mmmm dd yyyy hhMM'), '.mat']; %Descriptive name timestamp
% save(filename);
% to_picture(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, 'layered');
% to_picture(digraph_zonescale_multi, TopPilotnode, cell_zone, CaseName, 'layered');

% merge_steps
%plot_zone_merge_steps(digraph_ori_offsetted, digraph_zonescale_offset, TopPilotnode, table_islands, CaseName);
% draw_zone_merge_page(digraph_ori_offsetted, digraph_zonescale_offset, TopPilotnode, table_islands, 2, CaseName);
% draw_zone_merge_page(digraph_ori_offsetted, digraph_zonescale_offset, TopPilotnode, table_islands, 5, CaseName);
% draw_zone_merge_page(digraph_ori_offsetted, digraph_zonescale_offset, TopPilotnode, table_islands, 6, CaseName);
% draw_zone_merge_page(digraph_ori_offsetted, digraph_zonescale_offset, TopPilotnode, table_islands, 0, CaseName);

% zonal_power_flow
%draw_zone_power_flow(digraph_zonescale_offset, 2, CaseName);
%draw_zone_power_flow(digraph_zonescale_offset, 1, CaseName);

% to_picture(digraph_zonescale_wheel, TopPilotnode, cell_zone, CaseName)
 to_picture_wheel(digraph_zonescale_wheel, TopPilotnode, cell_zone, CaseName);
