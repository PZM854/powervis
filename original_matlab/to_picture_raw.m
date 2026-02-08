function p = to_picture_raw(digraph, CaseName, varargin)
    
% to make raw graph

% A raw graph is made from raw data which exists before combination

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

G = digraph;

if ismember('Volt', G.Nodes.Properties.VariableNames)
    num_color = length(unique(digraph.Nodes.Volt));
    num_level_opvolt = num_color;
    level_volt = unique(digraph.Nodes.Volt);
    char_volt = 'Volt';
else
    num_color = length(unique(digraph.Nodes.OpVolt));
    num_level_opvolt = num_color;
    level_volt = unique(digraph.Nodes.OpVolt);
    char_volt = 'OpVolt';
end

if isempty(user_color)
    color = color_colorbrewer(num_color);
else
    color = user_color;
end

%% parameters

marksize = 5;
   
figure
p = plot(G, Layout="layered");
% p.LineWidth = width_edge_zonescale;
p.LineWidth = 1.0;
p.EdgeColor = 'black';
p.MarkerSize = marksize;

color_to_use = [];
[~,idx_color_eachnode] = ismember(G.Nodes.(char_volt), level_volt);
for i = 1:size(G.Nodes,1)
    color_to_use = [color_to_use; color(idx_color_eachnode(i), :)];
end
p.NodeColor = color_to_use;
% add a title
title(['original distribution network - ', CaseName], 'Interpreter', 'none');

if info ~= 0

    % add a legend
    hold on;
    h = gobjects(num_level_opvolt,1);
    for k = 1:num_level_opvolt
        h(k) = scatter(NaN, NaN, 60, color(k,:), 'filled', ...
            'DisplayName', sprintf('%d kV', level_volt(k)));
    end
    hold off;
    legend(h, 'Location', 'best');
    
    edge_trans = [];
    for i = 1:size(G.Edges, 1)
        if G.Nodes.Volt(G.Edges.EndNodes(i, 1)) ~= G.Nodes.Volt(G.Edges.EndNodes(i, 2))
            edge_trans = [edge_trans i];
        end
    end
    highlight(p, 'Edges', edge_trans, 'LineWidth', 1.5, 'LineStyle','-.');
    
    Gz = digraph;   % easy to read
    ax = gca;
    
    % 1 scale
    Z   = size(Gz.Nodes, 1);                          % number of nodes
    E   = size(Gz.Edges, 1);                          % number of edges
    L = numel(unique(Gz.Nodes.Volt));
    
    % 2 indegree/outdegree
    d_out = outdegree(Gz);
    d_in  = indegree(Gz);
    [~, k_out_deg] = max(d_out);
    [~, k_in_deg ] = max(d_in);
    
    
    % 3 text
    info_lines = {
        sprintf('Number of nodes:             %d', Z)
        sprintf('Number of edges:             %d', E)
        sprintf('Number of voltage levels:    %s', ternum(L))
        sprintf('Max out-degree:              node %d (%d edges)', k_out_deg, d_out(k_out_deg))
        sprintf('Max in-degree:               node %d (%d edges)', k_in_deg,  d_in(k_in_deg))
    };
    info_text = strjoin(info_lines, newline);
    
    % 4 output onto picture）
    text(ax, 0.02, 0.98, info_text, 'Units','normalized', ...
        'VerticalAlignment','top', 'FontName','Consolas', 'FontSize',10, ...
        'BackgroundColor',[1 1 1 0.75], 'Margin',6, 'EdgeColor',[0.2 0.2 0.2]);
end


end

function s = ternum(val)
    if isnan(val)
        s = '-';
    else
        s = num2str(val);
    end
end


