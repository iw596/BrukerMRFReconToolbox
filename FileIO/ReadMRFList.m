
%% Function to read FA and TR list stored in IW's FA text files, first entry in text file is
%% header information
function [FAList,TRList] = ReadMRFList(pth)
    fileID = fopen(pth,'r');
    % Read first line
    tline = fgetl(fileID);
    newStr = extractAfter(tline,'#');
    NFA = str2num(newStr);
    FAList = zeros(NFA,1);
    TRList = zeros(NFA,1);
    counter = 1;
    while ischar(tline)
        tline = fgetl(fileID);
        if (ischar(tline))
            newStr = split(tline,',');
            FAList(counter) = str2double(newStr(1));
            TRList(counter) = str2double(newStr(2));
            counter = counter + 1;

        end
    end
    fclose(fileID);
end