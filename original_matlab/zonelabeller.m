function [table_islands, graph_nominal,...
    digraph_nominal, index_edge_withtrans, index_nodes_oftrans] = zonelabeller(case_WT)

    define_constants;       

    [volt_branch_ope, bool_branch_trans, table_branch_ope] = powerflow_to_table(case_WT);

    graph_nominal = case_to_graph(case_WT, 'graph');

    digraph_nominal = case_to_graph(case_WT, 'digraph');
    digraph_nominal = my_flipedge(digraph_nominal, 'SendingMW');
    
    
    index_edge_withtrans = find(graph_nominal.Edges.IsTrafo == 1); %index
    index_nodes_oftrans = graph_nominal.Edges.EndNodes(index_edge_withtrans,:);
    
    graph_nominal_notrans = rmedge(graph_nominal, index_edge_withtrans);
    
    
    
    index_comp = conncomp(graph_nominal_notrans); 
    num_comp = max(index_comp); 
    
    table_islands = cell(num_comp,2);
    
    for k = 1:num_comp
        table_islands{k, 1} = [find(index_comp == k)]; %nodes, ori_index
        for thisedge = 1:size(graph_nominal_notrans.Edges,1)
            if ismember(graph_nominal_notrans.Edges.EndNodes(thisedge,1),table_islands{k, 1}) && ...
                    ismember(graph_nominal_notrans.Edges.EndNodes(thisedge,2),table_islands{k, 1})
                table_islands{k, 2} = [table_islands{k, 2} graph_nominal_notrans.Edges.EdgeOrigIndex(thisedge)];% edge,ori_index
            end
        end
    end
    
    
    num_island = max(index_comp);
    
    index_edge_island = cell(num_island,1);
    for k = 1:num_island
        index_edge_island{k} = find(ismember(digraph_nominal.Edges.EdgeOrigIndex, table_islands{k,2}));
    end
    
    orindex_edge_withtrans = graph_nominal.Edges.EdgeOrigIndex(index_edge_withtrans);
    index_edge_withtrans = find(ismember(digraph_nominal.Edges.EdgeOrigIndex, orindex_edge_withtrans));
    
    %% 以下代码标注每个节点和branch的zone。变压器的zone 为0 
    % The following code labels the zone of each node and branch. The zone of transformers is set to 0.
    
    % digraph_nominal.Nodes.matpower_index = case_WT.bus(:, BUS_I);
    % digraph_nominal.Nodes.angle = case_WT.bus(:, VA);
    
    % zone for each node 
    for thiszone = 1:num_island
        digraph_nominal.Nodes.zone(table_islands{thiszone,1}) = thiszone;
    end
    
    %zone for each edge 
    for thiszone = 1:num_island
        index_edge_thiszone = find(ismember(digraph_nominal.Edges.EdgeOrigIndex, table_islands{thiszone, 2})); %index of given zone in digraph 
        digraph_nominal.Edges.zone(index_edge_thiszone) = thiszone;
    end


end

