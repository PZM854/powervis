function idx_single = find_single_edge(T, from_to)

    define_constants;       


    from = from_to(1);
    to = from_to(2);

    idx_single = [];

    for k = 1:size(T,1)
        idx_rev = find(T(:,to)==T(k,from)&T(:, from)==T(k,to), 1);
        if isempty(idx_rev)
            idx_single = [idx_single k];
        end

    end

end

