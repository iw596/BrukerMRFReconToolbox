function FAList = ReadFAList(pth)
    fileID = fopen(pth,'r');
    formatSpec = '%f';
    FAList = fscanf(fileID,formatSpec);
    fclose(fileID);
end

