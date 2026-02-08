function p = to_picture(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, layout, varargin)
    
% to make aggregated graph

% the most classic graph showing the big picture of power transmission
% among zones

if isempty(layout)
        layout = 'force';
    end
    layout = char(layout);  

define_constants;

% ===== Parse optional parameters =====
p = inputParser;
addParameter(p, 'NodeColor', []);  % optional node color
addParameter(p, 'info', []);  % optional node color
parse(p, varargin{:});
user_color = p.Results.NodeColor;
info = p.Results.info;
if isempty(info)
    info = 1;
end

% color
if isempty(user_color)
    level_opvolt = unique(digraph_zonescale_offset.Nodes.OpVolt);
    num_level_opvolt = length(level_opvolt);
    color = color_colorbrewer(num_level_opvolt);
else
    color = user_color;
end

% width of each edge
table_zonescale = digraph_zonescale_offset.Edges;
P_edge_zonescale = table_zonescale.SendingMW';
P_log = log10(P_edge_zonescale + 0.1);
width_max = 3;
width_min = 1;
P_log_norm = (P_log - min(P_log))/(max(P_log) - min(P_log));
width_edge_zonescale = width_min + (width_max - width_min)*P_log_norm;

% color of each edge
color_edge_1 = [55,126,184]/255;
color_edge_2 = [228,26,28]/255;%from blue to red
color_edge = [];
for i = 1:size(table_zonescale,1)
    color_edge = [color_edge; color_edge_1 + (color_edge_2 - color_edge_1) * P_log_norm(i)];
end

%size of each supernode
% num_node_eachzone = digraph_zonescale_offset.Nodes.num_node;
% num_log = log10(num_node_eachzone + 1);
% marker_min = 5;
% marker_max = 20;
% num_log_norm = (num_log - min(num_log))/(max(num_log) - min(num_log));
% size_node_zonescale = marker_min + (marker_max - marker_min)*num_log_norm;

num_node_eachzone = digraph_zonescale_offset.Nodes.num_node;
marker_min = 7;
level_size_node = ceil(log10(num_node_eachzone + 1));
size_node_zonescale = marker_min + (level_size_node - 1)*5;

%[~,idx_color_eachzone] = ismember(digraph_zonescale_offset.Nodes.OpVolt, level_opvolt);

if strcmp(layout, 'force')

    p = to_force_layout(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, 'info', info);

else % layout is 'layered'
    
    p = to_layered_layout(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName, 'info', info);

end

end


function s = ternum(val)
    if isnan(val)
        s = '-';
    else
        s = num2str(val);
    end
end
