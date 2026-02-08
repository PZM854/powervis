function edge_new = edge_combination(T, idx_weight, node_key)

% take in a table that about to form a digraph, or a matrix that to form a
% table

% T: table or matrix
% idx_weight: the index of column represents the weight
% node_key: the index of column represents fromnodes and tonodes

% combine those edge have the same from/to nodes by adding up the weights

    p = inputParser;
    addRequired(p, 'T', @(x) istable(x) || isnumeric(x));
    addRequired(p, 'idx_weight', @(x) isnumeric(x) || ischar(x) || isstring(x));
    addRequired(p, 'node_key', @(x) iscell(x)&&numel(x)==2 || isnumeric(x)&&numel(x)==2 ...
        || ischar(x) || isstring(x));
    parse(p, T, idx_weight, node_key);

    if istable(p.Results.T)
        T_new = p.Results.T{:,:};
    else
        T_new = p.Results.T;
    end
  %  T = p.Results.T;
    idx_weight = p.Results.idx_weight;
    node_key = p.Results.node_key;

    if ischar(idx_weight) || isstring(idx_weight)
        idx_weight = get_field_col_range(idx_weight, T);
    end

    if iscell(node_key)
        from = node_key{1};
        to = node_key{2};
        from = get_field_col_range(from, T);
        to = get_field_col_range(to, T);
    elseif ischar(node_key) || isstring(node_key)
        from_to = get_field_col_range(node_key, T);
        from = from_to(1);
        to = from_to(2);
    else
        from = node_key(1);
        to = node_key(2);
    end

    T_new = sortrows(T_new, [from to]);

    num_edges = size(T_new,1);
    edge_new = [];
    p_l = 1;
    p_r = 1;

    while(1)
        if p_r == num_edges
            if T_new(p_r,from)==T_new(p_l,from) && T_new(p_r,to)==T_new(p_l,to)
                edge_new = [edge_new; [T_new(p_l,from) T_new(p_l,to) sum(T_new(p_l:p_r,idx_weight))]];
            else
                edge_new = [edge_new; [T_new(p_r,from) T_new(p_r,to) T_new(p_r,idx_weight)]];
            end
            
            break;
        elseif T_new(p_r,from)==T_new(p_l,from) && T_new(p_r,to)==T_new(p_l,to)
            p_r = p_r + 1;
        else
            edge_new = [edge_new; [T_new(p_l,from) T_new(p_l,to) sum(T_new(p_l:p_r-1,idx_weight))]];
            p_l = p_r;
        end
    end
    
    % if istable(T)  % T is a table 
    %     while(1)
    %         if p_r == num_edges
    %             edge_new = [edge_new; [T.(from)(p_l) T.(to)(p_l) sum(T.(idx_weight)(p_l:p_r))]];
    %             break;
    %         elseif T.(from)(p_r)==T.(from)(p_l) && T.(to)(p_r)==T.(to)(p_l)
    %             p_r = p_r + 1;
    %         else
    %             edge_new = [edge_new; [T.(from)(p_l) T.(to)(p_l) sum(T.(idx_weight)(p_l:p_r-1))]];
    %             p_l = p_r;
    %         end
    %     end
    % else % T is a matrix
    %     while(1)
    %         if p_r == num_edges
    %             edge_new = [edge_new; [T(p_l,from) T(p_l,to) sum(T(p_l:p_r,idx_weight))]];
    %             break;
    %         elseif T(p_r,from)==T(p_l,from) && T(p_r,to)==T(p_l,to)
    %             p_r = p_r + 1;
    %         else
    %             edge_new = [edge_new; [T(p_l,from) T(p_l,to) sum(T(p_l:p_r-1,idx_weight))]];
    %             p_l = p_r;
    %         end
    %     end
    % end

    %edge_new(:,4) = [1:size(edge_new,1)]';

end

