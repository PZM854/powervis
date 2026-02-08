function T_sorted = sort_table(T, key, varargin)


    p = inputParser;
    addRequired(p, 'T', @(x) istable(x));
    addRequired(p, 'key', @(x) iscell(x) || isnumeric(x));
    addParameter(p, 'directions', [], @(x) isempty(x) || isstring(x) || ischar(x));
    parse(p, T, varargin{:});
    
    T = p.Results.T;
    key = p.Results.key;
    directions = p.Results.directions;
    
    if isempty(key)
        error('必须指定排序字段名或列号(key)');
    end
    if isempty(directions)
        directions = 'ascend'; %默认升序
    end
    
    if iscell(key) || isnumeric(key)
        T_sorted = sortrows(T, key, directions);
    else
        error('key类型错误');
    end
end


