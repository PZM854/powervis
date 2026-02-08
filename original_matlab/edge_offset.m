function T_new = edge_offset(T, idx_weight, node_key)

% offset the weights of branches of reverse directions

% assume that branches have been combined. Each from/to pair have no
% more than one branch.
% T: table or matrix
% idx_weight: the index of column represents the weight
% node_key: the index of column represents fromnodes and tonodes

    p = inputParser;
    addRequired(p, 'T', @(x) istable(x) || isnumeric(x));
    addRequired(p, 'idx_weight', @(x) isnumeric(x) || ischar(x) || isstring(x));
    addRequired(p, 'node_key', @(x) iscell(x)&&numel(x)==2 || isnumeric(x)&&numel(x)==2);
    parse(p, T, idx_weight, node_key);
    
    if istable(p.Results.T)
        T_new = p.Results.T{:,:};
    else
        T_new = p.Results.T;
    end
    %T_new = p.Results.T;
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

    point = 1;

    while(point <= size(T_new,1))
            rev_edge = (T_new(:, from)==T_new(point, to)) &...
                     (T_new(:, to)==T_new(point, from));
            idx_rev = find(rev_edge);
            if ~isempty(idx_rev)
                T_new(point, idx_weight) = T_new(point, idx_weight) - T_new(idx_rev, idx_weight);
                T_new(idx_rev,:) = [];
            end
            point = point + 1;
    end
    for i = 1:size(T_new,1)
        if T_new(i, idx_weight) < 0
            temp = T_new(i,from);
            T_new(i,from) = T_new(i,to);
            T_new(i,to) = temp;
            T_new(i,idx_weight) = -T_new(i,idx_weight);
        end
    end

    % if istable(T_new)  % T is a table 
    %     while(point <= size(T_new,1))
    %         rev_edge = (T_new(:, from)==T_new(point, to)) &...
    %                  (T_new(:, to)==T_new(point, from));
    %         idx_rev = find(rev_edge);
    %         if ~isempty(idx_rev)
    %             T_new(point, idx_weight) = T_new(point, idx_weight) - T_new(idx_rev, idx_weight);
    %             T_new(idx_rev,:) = [];
    %         end
    %         point = point + 1;
    %     end
    %     for i = 1:size(T_new,1)
    %         if T_new(i, idx_weight) < 0
    %             temp = T_new(i,from);
    %             T_new(i,from) = T_new(i,to);
    %             T_new(i,to) = temp;
    %             T_new(i,idx_weight) = -T_new(i,idx_weight);
    %         end
    %     end
    % 
    % 
    % else % T is a matrix
    %     while(point <= size(T_new,1))
    %         rev_edge = (T_new(:, from)==T_new(point, to)) &...
    %                  (T_new(:, to)==T_new(point, from));
    %         idx_rev = find(rev_edge);
    %         if ~isempty(idx_rev)
    %             T_new(point, idx_weight) = T_new(point, idx_weight) - T_new(idx_rev, idx_weight);
    %             T_new(idx_rev,:) = [];
    %         end
    %         point = point + 1;
    %     end
    %     for i = 1:size(T_new,1)
    %         if T_new(i, idx_weight) < 0
    %             temp = T_new(i,from);
    %             T_new(i,from) = T_new(i,to);
    %             T_new(i,to) = temp;
    %             T_new(i,idx_weight) = -T_new(i,idx_weight);
    %         end
    %     end
    % end
end



