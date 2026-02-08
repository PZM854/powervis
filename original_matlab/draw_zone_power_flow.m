function draw_zone_power_flow(digraph_zonescale_offset, zone_id, CaseName)
% to draw graph of one zone's input/output power
% input：
% - digraph_zonescale_offset：zonal graph（含边功率、节点 zone ID 等）
% - zone_id：要绘制的目标 zone（例如 3）
% - CaseName：案例名称（用于图标题）

% parameter settings
radius = 1.2;        % arrow start point radius
arrow_len = 1.05;     % length of arrow
label_radius = 1.3;  % 

circle_r = 0.15;

% 
edge_table = digraph_zonescale_offset.Edges;
endnodes = edge_table.EndNodes;

% in edge
in_mask = (endnodes(:,2) == zone_id);
in_flows = edge_table(in_mask, :);
in_sources = endnodes(in_mask, 1);

% out egdge
out_mask = (endnodes(:,1) == zone_id);
out_flows = edge_table(out_mask, :);
out_targets = endnodes(out_mask, 2);

% aggregate all the power flow
all_flows = [ ...
    repmat({'in'}, height(in_flows), 1), num2cell(in_sources), num2cell(in_flows.SendingMW); ...
    repmat({'out'}, height(out_flows), 1), num2cell(out_targets), num2cell(out_flows.SendingMW)];

num_arrows = size(all_flows,1);
theta = linspace(0, 2*pi, num_arrows + 1); theta(end) = [];

% start to figure
figure('Name', ['Zone ', num2str(zone_id), ' Power Flow'], 'Color', 'w');
hold on; axis equal; axis off;

% center of the picture should be the zone
plot(0, 0, 'o', 'MarkerSize', 30, 'MarkerFaceColor', [0.6 0.8 1], 'MarkerEdgeColor', 'k');
text(0, 0, ['Zone ', num2str(zone_id)], 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 8, 'FontWeight', 'bold');

% 
for i = 1:num_arrows
    dir = all_flows{i,1};
    z_other = all_flows{i,2};
    mw = all_flows{i,3};

    angle = theta(i);

    if strcmp(dir, 'in')
        x = radius * cos(angle);
        y = radius * sin(angle);
        dx = -arrow_len * cos(angle);
        dy = -arrow_len * sin(angle);
    else
        x = circle_r * cos(angle);  % 
        y = circle_r * sin(angle);
        dx = arrow_len * cos(angle);
        dy = arrow_len * sin(angle);
    end

    quiver(x, y, dx, dy, 0, 'Color', [0.3 0.3 0.3], 'MaxHeadSize', 0.6, 'LineWidth', 1.3);

    % label
    lx = label_radius * cos(angle);
    ly = label_radius * sin(angle);
    if strcmp(dir, 'in')
        text_str = sprintf('%.1f MW\nfrom zone %d', mw, z_other);
    else
        text_str = sprintf('%.1f MW\nto zone %d', mw, z_other);
    end
    text(lx, ly, text_str, 'HorizontalAlignment', 'center', 'FontSize', 10);
end

% title
% if exist('CaseName', 'var') && ~isempty(CaseName)
%     title(['Power Flows of Zone ', num2str(zone_id), ' — ', CaseName], 'FontSize', 12);
% else
%     title(['Power Flows of Zone ', num2str(zone_id)], 'FontSize', 12);
% end

end