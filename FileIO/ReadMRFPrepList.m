
% Function to read MRF preplist containing indicator of the prep
function prepList = ReadMRFPrepList(filePth)
    fileID = fopen(filePth,'r');
    % Read first line
    tline = fgetl(fileID);
    newStr = extractAfter(tline,'#');
    NPrep = int32(str2num(newStr));
    disp(['The number of prep modules is: ', num2str(NPrep)])
    
    % Empty array to store prep module and times
    prepList = zeros(NPrep,2);
    
    % Read prep modules file line by line
    counter = 1;
    while ischar(tline)
        tline = fgetl(fileID);
        if (tline ~= -1)
            vals = split(tline);
            if (~isempty(vals))
                prepList(counter,1) = int32(str2double(cell2mat(vals(1))));
                prepList(counter,2) = str2double(cell2mat(vals(2)));
                counter = counter + 1;
            end
        end
    end
    
    fclose(fileID);
end

