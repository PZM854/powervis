function col_range = get_field_col_range(target_field, T)

    varnames = T.Properties.VariableNames;
    n_fields = numel(varnames);

    % 统计每个字段的列宽
    field_widths = zeros(1, n_fields);
    for i = 1:n_fields
        field_widths(i) = size(T.(varnames{i}), 2);
    end

    % 计算各字段在数组中的起始、终止列号
    start_col = cumsum([1, field_widths(1:end-1)]);
    end_col   = cumsum(field_widths);

    % 找目标字段下标
    idx = find(strcmp(varnames, target_field));
    if isempty(idx)
        error('字段名 "%s" 不存在！', target_field);
    end

    % 输出目标字段在数组中的范围
    start_col = start_col(idx);
    end_col = end_col(idx);

    if start_col == end_col
        col_range = end_col;
    else
        col_range = [start_col end_col];
    end

end
% width = [1 2 4 3];
% start = [1 2 4 8];
% end  = [1 3 7 10];
