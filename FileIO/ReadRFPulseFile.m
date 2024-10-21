%% Function to read bruker RF pulse file and return the shape (abs and phase)
function [shape,phase] = ReadRFPulseFile(filepath)
    fileID = fopen(filepath);
    if (fileID == -1)
        error("Pulse file is not valid!")
    end
    
    % Read exc file line by line
    
    while ~feof(fileID)
        line = fgetl(fileID)
        if (contains(line,"##NPOINTS="))
            nPoints = str2num(extractAfter(line,"##NPOINTS="));
            break;
        end
    end

    
    % Keep reading until marker 
   while ~feof(fileID)
        line = fgetl(fileID);
        if (contains(line,"##XYPOINTS= (XY..XY)"))
            break;
        end
   end
   shape = zeros(nPoints,1);
   phase = zeros(nPoints,1);

   % Now read all the points we need

   for i = 1:nPoints
        line = fgetl(fileID);
        % Split line based on space
        tmp = split(line,' ');
        shape(i) = str2num(tmp{1});
        phase(i) = str2num(tmp{2});
   end



    fclose(fileID);

end

