function ifcorrect = zone_viewer_ui(digraph_ori_offsetted, digraph_zonescale_offset, digraph_zonescale_multi, ...
    TopPilotnode, cell_zone, CaseName)

G1 = digraph_zonescale_offset;   
G2 = digraph_zonescale_multi;    
G3 = digraph_ori_offsetted;   

% ====== 1) 轻量 GUI 框架 ======

f  = uifigure('Name','Zone Views','Position',[100 100 720 480]);
ax = uiaxes(f,'Position',[140 20 560 440]);  % 右侧画布，留出左侧放按钮

% ====== 2) 三个按钮（互斥），回调统一走 show(k) ======

uibutton(f,'Text','① zonal_aggregation','Position',[20 420 100 28],...
    'ButtonPushedFcn',@(~,~) show(1));
uibutton(f,'Text','② zonal_Multigraph','Position',[20 380 100 28],...
    'ButtonPushedFcn',@(~,~) show(2));
uibutton(f,'Text','③ original_aggregation','Position',[20 340 100 28],...
    'ButtonPushedFcn',@(~,~) show(3));

% ====== 3) 先跑一次布局拿 X/Y（保证三图位置一致） ======
% 说明：plot(digraph, 'Layout','force') 每次都会重算坐标。
% 我们先画G1拿到坐标，记录下 X/Y，后续三图都用同一套 X/Y。

p0 = plot(ax, G1, 'Layout',"force");
X = p0.XData;  Y = p0.YData;  delete(p0);   % 删除临时图，只保留坐标

% ====== 4) 预绘三张图，默认只显示第一张 ======
h1 = plot(ax, G1, 'XData',X, 'YData',Y);
title(ax,'zonal_aggregation');
h2 = plot(ax, G2, 'XData',X, 'YData',Y);  h2.Visible = 'off';
h3 = plot(ax, G3, 'XData',X, 'YData',Y);  h3.Visible = 'off';

% p1 = topicture(digraph_zonescale_offset, TopPilotnode, cell_zone, CaseName);
% title(ax, 'zonal_aggregation');
% p2 = topicture(digraph_zonescale_multi, TopPilotnode, cell_zone, CaseName); p2.Visible = 'off';

function show(k)
    % 可见性
    h1.Visible = iff(k==1,'on','off');
    h2.Visible = iff(k==2,'on','off');
    h3.Visible = iff(k==3,'on','off');
    % 标题
    switch k
        case 1, title(ax,'① 合并未抵消');
        case 2, title(ax,'② Multigraph');
        case 3, title(ax,'③ 净流(抵消)');
    end
    % 信息框
    update_infobox(k);
end

function key_switch(e)
    switch e.Key
        case {'1','numpad1'}, show(1);
        case {'2','numpad2'}, show(2);
        case {'3','numpad3'}, show(3);
    end
end
ifcorrect = 1;

end