function params = ReadBrukerMethodFile(path)
    methodFileName = strcat(path,'\','method'); 
    result = isfile(methodFileName);
    if (result ==0)
        error("Method file is not present");
        return;
    end

    fid = fopen(methodFileName);

    finishedReading = true;
    currentEntry = 0;


    tline = fgetl(fid);
    while ischar(tline)
        tline
        tline = fgetl(fid);
        if (strcmp(tline(1:3),"##$") == 1)
            finishedReading = true;
        end

        if (finishedReading == true)
            s = strtrim(tline);
            if (strcmp(tline(1:3),"##$") == 1)
                currentEntry = currentEntry + 1;
                i = strfind(s,'=');
                key = s(4:i-1);
                val = s(i+1:end);
                if (val(1)~= "(")
                
                else
                    if (val(2)~= " " || val(3)=='<' )
                end
                
            end
        else
        
        end
            
    end
    params = []
    fclose(fid)
end