% 专门用于论文出图的脚本，由paper_step3_zonal_multigraph修改而来
% 专门画进行了最终的功率整合步骤的图。主要强调zone6
% 不必考虑函数化、规范化和封装

%% 读取文件
clear;
clc;

S = load('samplepglib_opf_case162_ieee_dtcOctober 04 2025 0215.mat');

digraph_zonescale_offset = S.digraph_zonescale_offset;
cell_zone = S.cell_zone;
TopPilotnode = S.TopPilotnode;
CaseName = S.CaseName;

G = digraph_zonescale_offset;
%% 超参数区
%原本是函数可选参数的，在这里控制。例如info这样的参数，可以在这控制
define_constants;
info = 0;
cof_marksize = 0.8;
cor_arrowsize = 1;%箭头大小
height = 5.5; %图窗高度。要调就在这里调整，不要去文中找参数。
width = 8.89; %图窗宽度。图窗宽度应该满足同类图片一致，且不能超过8.89

active_zone = 6;
scale = 1; %整体缩放比例

%% 计算参数
% color

level_opvolt = unique(G.Nodes.OpVolt);
num_level_opvolt = length(level_opvolt);
color = color_colorbrewer(num_level_opvolt);


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
p.MarkerSize = p.MarkerSize * cof_marksize;

p.NodeLabel = cellstr(string(G.Nodes.num_node));
p.NodeFontName = 'Times New Roman';
p.NodeFontSize = 8;
p.NodeLabelColor = [0 0 0];
%p.EdgeColor = color_edge;
color_used = [];
for thiszone = 1:size(G.Nodes,1)
    color_used = [color_used; color(idx_color_eachzone(thiszone), :)];
end
p.NodeColor = color_used;
% add a title

% add a legend
% hold on;
% h = gobjects(num_level_opvolt,1);
% for k = 1:num_level_opvolt
%     h(k) = scatter(NaN, NaN, 60, color(k,:), 'filled', ...
%         'DisplayName', sprintf('%d kV', level_opvolt(k)));
% end
% hold off;
% legend(h, 'Location', 'best');

%% 特别部分
% 开始控制颜色
num_zone = size(G.Nodes, 1);
gray_color = [0.88 0.88 0.88];
color_raw = p.NodeColor;
if active_zone == 0
    % for i = 1:num_node
    %     color_raw(i, :) = gray_color;
    % end
else
    for i = 1:num_zone
        if i ~= active_zone
            color_raw(i, :) = gray_color;
        end
    end
end
p.NodeColor = color_raw;

if info ~= 0
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
    sprintf('Zones: %d', Z)
    sprintf('Edges: %d', E)
    sprintf('Nodes: %s', ternum(Nbus))
    sprintf('Levels: %s', ternum(L))
    sprintf('Outdeg: Zone %d (%d)', k_out_deg, d_out(k_out_deg))
    sprintf('Indeg: Zone %d (%d)', k_in_deg,  d_in(k_in_deg))
    };
    info_text = strjoin(info_lines, newline);
    hInfo = text(ax, 0.10, 0.95, info_text);   % 先创建
    set(hInfo,'Units','normalized');           % 先把单位设成 normalized
    set(hInfo,'Position',[0.10 0.95 0]);       % 再把位置设回 0.10,0.95（现在按 normalized 解释）    % 4 output onto picture
    % 设置单位和位置
    set(hInfo, 'VerticalAlignment', 'top');
    set(hInfo, 'HorizontalAlignment', 'left');
    
    % 设置字体
    set(hInfo, 'FontName', 'Consolas');
    set(hInfo, 'FontSize', 7);
    
    % 设置背景和边框
    %set(hInfo, 'BackgroundColor', [1 1 1 0.75]);
    %set(hInfo, 'EdgeColor', [0.2 0.2 0.2]);
    
    % 设置内边距
    set(hInfo, 'Margin', 2);
end

%% 格式与尺寸控制

% === 图窗口 ===
set(gcf,'Units','centimeters');                   % 单位：厘米
set(gcf,'Position',[7 7 8.89 height]);                 % 宽度固定 8.89 cm，高度 8 cm
set(gcf,'PaperUnits','centimeters','PaperPosition',[7 7 8.89 height]); % 打印导出也一致
set(gcf,'Color','w');                             % 白色背景
movegui(gcf,'center');   % 自动把窗口移到屏幕正中

% === 坐标轴区域（axis，图像本体所在的矩形）===
% [左边距 下边距 宽度 高度] 单位：厘米
% 这里留 0.7cm 边距，保证标签、legend 不会挤出边框
set(gca,'Units','centimeters','Position',[0 0 width height]); 
% === 字体 ===
set(gca,'FontName','Times New Roman','FontSize',8); % Times New Roman, 8pt

% === 去掉多余边框 ===
box off;    % 去掉外侧边框
axis off;   % 如果你论文图不需要坐标轴（zonal 图通常不要）

% === 图例控制 ===
% 强制放在论文版面合适的位置，比如右下角 inside
% lgd = legend('show');                       % 生成 legend 句柄
% set(lgd,'Location','northwest');     % 固定位置
% set(lgd,'FontName','Times New Roman');      % 字体
% set(lgd,'FontSize',8);                      % 字号
% set(lgd,'Box','off');                       % 去掉边框 

% === 标题（如果需要）===
% title(['Inter-Zonal Power Transfer - ', CaseName], ...
%       'FontName','Times New Roman','FontSize',8,'FontWeight','bold');

% === 导出 ===
if info == 1
    exportgraphics(gcf,['step4_',CaseName,'withinfo','.png'],'Resolution',600); % 高分辨率导出
else
    exportgraphics(gcf,['step4_',CaseName,'.png'],'Resolution',600); % 高分辨率导出
end



function s = ternum(val)
    if isnan(val)
        s = '-';
    else
        s = num2str(val);
    end
end
