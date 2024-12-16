function WriteMRFPowerList(fileName,powerList)
    fileID = fopen(fileName,'w');
    fwrite(fileID,powerList,'float32')
    fclose(fileID);
end

