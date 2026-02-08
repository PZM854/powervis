function G_new = my_flipedge(G, PowerFieldName)

%   if the power transmition < 0, then flip the from/to nodes

%   G: original digraph/graph
%   PowerFieldName: name of str of power transmition（like 'SendingMW'）
%   G_new: new digraph/graph



    EdgeTable = G.Edges;
    EndNodes = EdgeTable.EndNodes;
    PowerVal = EdgeTable.(PowerFieldName);

    idx_flip = PowerVal < 0;

    % 翻转方向
    EndNodes_flipped = EndNodes;
    EndNodes_flipped(idx_flip,1) = EndNodes(idx_flip,2);
    EndNodes_flipped(idx_flip,2) = EndNodes(idx_flip,1);

    % 功率全取正
    PowerVal_flipped = abs(PowerVal);

    % 构建新EdgeTable
    EdgeTable_new = EdgeTable;
    EdgeTable_new.EndNodes = EndNodes_flipped;
    EdgeTable_new.(PowerFieldName) = PowerVal_flipped;

    % 用原有节点表和新边表重建图
    G_new = digraph(EdgeTable_new, G.Nodes);
end
