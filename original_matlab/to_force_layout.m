function p = to_force_layout(G, TopPilotnode, cell_zone, CaseName, varargin)


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

define_constants;

% color
if isempty(user_color)
    level_opvolt = unique(G.Nodes.OpVolt);
    num_level_opvolt = length(level_opvolt);
    color = color_colorbrewer(num_level_opvolt);
else
    color = user_color;
end

% width of each edge
table_zonescale = G.Edges;
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

num_node_eachzone = G.Nodes.num_node;
marker_min = 7;
level_size_node = ceil(log10(num_node_eachzone + 1));
size_node_zonescale = marker_min + (level_size_node - 1)*5;

[~,idx_color_eachzone] = ismember(G.Nodes.OpVolt, level_opvolt);

figure
p = plot(G, Layout='force');
p.LineWidth = 1.0;
p.EdgeColor = 'black';
p.MarkerSize = size_node_zonescale;
p.NodeLabel = cellstr(string(G.Nodes.num_node));
%p.EdgeColor = color_edge;
color_used = [];
for thiszone = 1:size(G.Nodes,1)
    color_used = [color_used; color(idx_color_eachzone(thiszone), :)];
end
p.NodeColor = color_used;
% add a title
title(['Inter-Zonal Power Transfer - ', CaseName], 'Interpreter', 'none');

if info ~= 0
    % add a legend
    hold on;
    h = gobjects(num_level_opvolt,1);
    for k = 1:num_level_opvolt
        h(k) = scatter(NaN, NaN, 60, color(k,:), 'filled', ...
            'DisplayName', sprintf('%d kV', level_opvolt(k)));
    end
    hold off;
    legend(h, 'Location', 'best');
    
    Gz = G;   % easy to read
    ax = gca;
    
    % 1 scale
    Z   = size(Gz.Nodes, 1);                          % num of zones
    E   = size(Gz.Edges, 1);                          % num of zonal edges
    if ismember('num_node', Gz.Nodes.Properties.VariableNames)
        Nbus = sum(Gz.Nodes.num_node);          % num of total nodes
    else
        Nbus = NaN;
    end
    if ismember('OpVolt', Gz.Nodes.Properties.VariableNames)
        L = numel(unique(Gz.Nodes.OpVolt(~isnan(Gz.Nodes.OpVolt))));  % num of voltage level
    else
        L = NaN;
    end
    
    % 2 indegree/outdegree
    d_out = outdegree(Gz);
    d_in  = indegree(Gz);
    [~, k_out_deg] = max(d_out);
    [~, k_in_deg ] = max(d_in);
    
    
    % 3 text
    info_lines = {
        sprintf('Number of zones (Z):         %d', Z)
        sprintf('Number of inter-zone edges:  %d', E)
        sprintf('Total number of nodes (N):   %s', ternum(Nbus))
        sprintf('Number of voltage levels:    %s', ternum(L))
        sprintf('Max out-degree:              Zone %d (%d edges)', k_out_deg, d_out(k_out_deg))
        sprintf('Max in-degree:               Zone %d (%d edges)', k_in_deg,  d_in(k_in_deg))
    };
    info_text = strjoin(info_lines, newline);
    
    % 4 output onto picture
    text(ax, 0.02, 0.98, info_text, 'Units','normalized', ...
        'VerticalAlignment','top', 'FontName','Consolas', 'FontSize',10, ...
        'BackgroundColor',[1 1 1 0.75], 'Margin',6, 'EdgeColor',[0.2 0.2 0.2]);
end

% mark TopPilotnode 
% top_zone = -1;
% for i = 1:size(cell_zone, 1)
%     if ismember(TopPilotnode, cell_zone{i, 1})
%         top_zone = i;
%         break;
%     end
% end
% highlight(p, [top_zone], 'Marker','s');
% 
end

function s = ternum(val)
    if isnan(val)
        s = '-';
    else
        s = num2str(val);
    end
end

