% ====================== for paper ======================

% ===============================================================

%% load .mat
clear;
clc;

S = load('sampleOctober 03 2025 1218.mat');   % 读取你的 .mat 文件
G = S.digraph_zonescale_wheel;
cell_zone = S.cell_zone;
CaseName = S.CaseName;

%% parameter
define_constants;
info = 0;                % 是否显示信息框（0 = 不显示）
cof_marksize = 0.5;      % 节点尺寸系数（根据实际情况可微调）
height = 5.5;            % 图窗高度（可调）
width = 8.89;            % 图窗宽度（固定）
scale = 1;             % 整体缩放比例
linewidth_base = 0.8;    % 基础线宽

%% 
% === 电压等级着色 ===
level_opvolt = unique(G.Nodes.OpVolt);
num_level_opvolt = length(level_opvolt);
color = color_colorbrewer(num_level_opvolt);

% === 边宽 ===
% table_zonescale = G.Edges;
% P_edge_zonescale = table_zonescale.SendingMW';
% P_log = log10(P_edge_zonescale + 0.1);
% width_max = 3;
% width_min = 1;
% P_log_norm = (P_log - min(P_log)) / (max(P_log) - min(P_log));
% width_edge_zonescale = width_min + (width_max - width_min) * P_log_norm;

% === 边颜色 ===
% color_edge_1 = [55,126,184]/255;    % 蓝色
% color_edge_2 = [228,26,28]/255;     % 红色
% color_edge = [];
% for i = 1:size(table_zonescale,1)
%     color_edge = [color_edge;
%         color_edge_1 + (color_edge_2 - color_edge_1) * P_log_norm(i)];
% end

%color_edge = repmat([55,126,184]/255, size(G.Edges,1), 1);  % 全部蓝色
color_edge = repmat([0,0,0]/255, size(G.Edges,1), 1);  % 全部黑色
% === 节点尺寸 ===
num_node_eachzone = G.Nodes.num_node;
marker_min = 7;
level_size_node = ceil(log10(num_node_eachzone + 1));
size_node_zonescale = marker_min + (level_size_node - 1) * 5;

% === 节点颜色 ===
[~, idx_color_eachzone] = ismember(G.Nodes.OpVolt, level_opvolt);
color_used = [];
for thiszone = 1:size(G.Nodes,1)
    color_used = [color_used; color(idx_color_eachzone(thiszone), :)];
end

%% 绘图区
figure
p = plot(G, Layout='force');
p.LineWidth = linewidth_base;
p.MarkerSize = size_node_zonescale * cof_marksize;
%p.NodeLabel = cellstr(string(G.Nodes.num_node));
%p.NodeLabel = {};
p.NodeFontName = 'Times New Roman';
p.NodeFontSize = 8;
p.NodeLabelColor = [0 0 0];
p.EdgeColor = color_edge;
p.NodeColor = color_used;

% === 去除单向边，仅保留环流结构 ===
idx_nonwheel = find_single_edge(table2array(G.Edges), [1 2]);
if ~isempty(idx_nonwheel)
    highlight(p, 'Edges', idx_nonwheel, 'LineWidth', 0.001);
    highlight(p, 'Edges', idx_nonwheel, 'EdgeColor', [255 255 255]/255);
end

% === 无 legend，无标题，无 info 框 ===
box off;
axis off;

%% 格式与尺寸控制
height = height * scale;
width = width * scale;

set(gcf,'Units','centimeters');
set(gcf,'Position',[7 7 width height]);
set(gcf,'PaperUnits','centimeters','PaperPosition',[7 7 width height]);
set(gcf,'Color','w');
movegui(gcf,'center');

set(gca,'Units','centimeters','Position',[0 0 width height]);
set(gca,'FontName','Times New Roman','FontSize',8);

%% 导出
exportgraphics(gcf, ['PowerWheel_', CaseName, '.png'], 'Resolution', 600);

%% ================================================================
%  附加功能：输出环流边对及其来回功率
%  ---------------------------------------------------------------
%  思路：
%  1. 在 G.Edges 中查找既有 i->j 又有 j->i 的边；
%  2. 记录 FromZone、ToZone 以及两个方向的功率；
%  3. 输出一个简单的 CSV 文件。
% ================================================================

disp('=== Extracting PowerWheel bidirectional edges ===');

EndNodes = G.Edges.EndNodes;
P = G.Edges.SendingMW;

pairs = [];   % 用于存储结果

for i = 1:size(EndNodes,1)
    from_i = EndNodes(i,1);
    to_i   = EndNodes(i,2);
    % 找是否存在反向边
    j = find(EndNodes(:,1)==to_i & EndNodes(:,2)==from_i, 1);
    if ~isempty(j) && j > i  % 避免重复
        pairs = [pairs; from_i, to_i, P(i), P(j)];
    end
end

if isempty(pairs)
    disp('No bidirectional (wheel) edges found.');
else
    disp(['Detected ', num2str(size(pairs,1)), ' bidirectional pairs.']);
    csv_filename = ['PowerWheel_edges_', CaseName, '.csv'];
    writematrix(pairs, csv_filename);
    disp(['Saved to ', csv_filename]);
end



%% local function =====================================================
function idx_nonwheel = find_single_edge(E, idx_col)
    if isempty(E)
        idx_nonwheel = [];
        return;
    end
    pairs = E(:, idx_col);
    idx_nonwheel = [];
    for i = 1:size(pairs, 1)
        if ~any(ismember(pairs, flip(pairs(i,:)), 'rows'))
            idx_nonwheel = [idx_nonwheel; i];
        end
    end
end
