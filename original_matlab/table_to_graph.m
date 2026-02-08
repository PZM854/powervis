function G = table_to_graph(T, case_WT, type)

    % case_WT:outcome of powerflow analysis
    % T is the table that indicate the imformation of edges

    % type is 'graph': make non-direction graph
    % type is 'diagraph': make non-direction graph

    % case to graph, only produce raw graph

    define_constants;

    p = inputParser;
    addRequired(p, 'T', @(x) istable(x));
    addRequired(p, 'case_WT', @(x) 1);
    addRequired(p, 'type', @(x) ischar(x) || isstring(x));
    parse(p, T, case_WT, type);

    type = string(lower(type));

    if strcmp(type,'graph') || strcmpi(type,"graph")
        G = graph(T);
        
    elseif strcmp(type,'digraph') || strcmpi(type,"digraph")
        G = digraph(T);

    else
        error('type must be "graph" or "digraph", got: %s', type);
    end
        G.Nodes.Volt = case_WT.bus(:, BASE_KV);
        G.Nodes.uni_index = [1:size(case_WT.bus,1)]';
        G.Nodes.matpower_index = case_WT.bus(:, BUS_I); %uni_index
        G.Nodes.angle = case_WT.bus(:, VA);


end

