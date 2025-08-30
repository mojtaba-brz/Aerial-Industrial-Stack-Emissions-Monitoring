function unit_vec = direction(vec)
    mag = norm(vec);
    if mag > 0
        unit_vec = vec/mag;
    else
        unit_vec = vec;
    end
end