function orientation = min_sNs(G)

A = adjacency(G);
A = A | A.';    
A = double(A); 
n = numnodes(G);
[i,j] = find(triu(A,1));
E = [i,j];
m = size(E,1);

yalmip('clear');
x_dir_edge = binvar(m, 1); % i < j; x(e)=0: i->j,  x(e)=1: j->i
x_in_node  = binvar(n,1);
x_out_node = binvar(n,1);
x_sos = binvar(n,1);   % z(i)=1: source or sink

C = [];
for e = 1:m
    u = E(e,1);
    v = E(e,2);

    % x(e)=0 : u -> v
    % x(e)=1 : v -> u

    % ---- u ----
    % node u has an outgoing edge if x(e)=0
    C = [C, x_out_node(u) >= 1 - x_dir_edge(e)];

    % node u has an incoming edge if x(e)=1
    C = [C, x_in_node(u) >= x_dir_edge(e)];

    % ---- v ----
    % node v has an incoming edge if x(e)=0
    C = [C, x_in_node(v)  >= 1 - x_dir_edge(e)];

    % node v has an incoming edge if x(e)=1
    C = [C, x_out_node(v) >= x_dir_edge(e)];
end

for i = 1:n
    in_expr  = [];
    out_expr = [];

    for e = 1:m
        u = E(e,1);
        v = E(e,2);

        if i == u
            % u is smaller index
            in_expr  = [in_expr, x_dir_edge(e)];        % x=1 -> v->u
            out_expr = [out_expr, 1 - x_dir_edge(e)];   % x=0 -> u->v
        elseif i == v
            % v is larger index
            in_expr  = [in_expr, 1 - x_dir_edge(e)];    % x=0 -> u->v
            out_expr = [out_expr, x_dir_edge(e)];       % x=1 -> v->u
        end
    end

    % upper bounds: node flags must be supported by real edges
    C = [C, x_in_node(i)  <= sum(in_expr)];
    C = [C, x_out_node(i) <= sum(out_expr)];
end


for i = 1:n
    C = [C, x_sos(i) >= 1 - x_in_node(i)];
    C = [C, x_sos(i) >= 1 - x_out_node(i)];
end

obj = sum(x_sos);
ops = sdpsettings('solver','cplex','verbose',0);
sol = optimize(C, obj, ops);
orientation = value(x_dir_edge);

out_node = value(x_out_node);
in_node = value(x_in_node);
SoS = value(x_sos);


end

