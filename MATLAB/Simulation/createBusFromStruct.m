function createBusFromStruct(structVar, busName)
    % Create a Simulink.Bus object from a MATLAB structure
    % structVar: structure variable
    % busName: name of the bus object to be created

    % Validate input
    if ~isstruct(structVar)
        error('Input must be a structure.');
    end

    % Create BusElements
    fields = fieldnames(structVar);
    elems = Simulink.BusElement.empty;

    for i = 1:numel(fields)
        elem = Simulink.BusElement;
        elem.Name = fields{i};

        value = structVar.(fields{i});
        if isnumeric(value)
            elem.Dimensions = size(value);
            elem.DataType = class(value);
        elseif islogical(value)
            elem.Dimensions = 1;
            elem.DataType = 'boolean';
        elseif ischar(value) || isstring(value)
            elem.Dimensions = 1;
            elem.DataType = 'string';
        else
            error('Unsupported field type for field: %s', fields{i});
        end

        elems(end+1) = elem;
    end

    % Create Bus object
    busObj = Simulink.Bus;
    busObj.Elements = elems;
    assignin('base', busName, busObj);
    % fprintf('Bus object "%s" created in base workspace.\n', busName);
end