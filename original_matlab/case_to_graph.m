function G = case_to_graph(case_WT, type)

    define_constants;
    % case_WT:outcome of powerflow analysis

    % type is 'graph': make non-direction graph
    % type is 'diagraph': make non-direction graph

    % case to graph, only produce raw graph
    
    p = inputParser;
    addRequired(p, 'case_WT', @(x) 1);
    addRequired(p, 'type', @(x) ischar(x) || isstring(x));
    parse(p, case_WT, type);

    type = string(lower(type));

    [~, ~, table_branch_ope] = powerflow_to_table(case_WT);

    if strcmp(type,'graph') || strcmpi(type,"graph")
        G = graph(table_branch_ope);
        
    elseif strcmp(type,'digraph') || strcmpi(type,"digraph")
        G = digraph(table_branch_ope);

    else
        error('type must be "graph" or "digraph", got: %s', type);
    end
        G.Nodes.Volt = case_WT.bus(:, BASE_KV);
        G.Nodes.uni_index = [1:size(case_WT.bus,1)]';
        G.Nodes.matpower_index = case_WT.bus(:, BUS_I); %uni_index
        G.Nodes.angle = case_WT.bus(:, VA);

end

