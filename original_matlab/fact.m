function res = fact(n)

if n <= 1
    res = 1;
else
    res = n * fact(n-1);
end

end

