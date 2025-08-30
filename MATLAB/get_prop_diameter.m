function d = get_prop_diameter(prop_name)
    for i=1:length(prop_name)
        if double(prop_name(i)) >= 48 && double(prop_name(i)) <= 57
            d = str2double(string(prop_name(i:i+1))) * 0.0254;
            return
        end
    end
end