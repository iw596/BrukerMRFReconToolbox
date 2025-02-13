function params = LoadBrukerData(path)
    % Find directory
    methodFileName = strcat(path,'\','method'); 
    result = isfile(methodFileName);
    if (result ==0)
        error("Method file is not present");
        return;
    end

    % Open the method file and get some useful values 
    filetext = fileread(methodFileName);
    TextAsCells = regexp(filetext,'##','split');
    params.System = "Bruker";
    % Check trajectory
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$RadialTraj'));
    line = TextAsCells(mask);
    if (isempty(line))
        params.Traj = "Cartesian";
    else
        line = strtrim(extractAfter(cell2mat(line),'='));
        if (strcmp(line, 'Yes') == 1)
            params.Traj = "Radial";
        else
            params.Traj = "Cartesian";
        end
    end
    
    if (params.Traj == "Radial")
        % Extract radial mode if we need it
        mask = ~cellfun(@isempty, strfind(TextAsCells,'$Trajectory'));
          line = TextAsCells(mask);
          line = strtrim(extractAfter(cell2mat(line),'='));  
          line = splitlines(line);
          if (strcmp(line(1),"SegmentedTraj") == 1)
              params.RadialMode = "Segmented";
              % Get shots and segments if needed
              mask = ~cellfun(@isempty, strfind(TextAsCells,'$NShots'));
              line = TextAsCells(mask);
              line = strtrim(extractAfter(cell2mat(line),'='));
              params.NShots = str2num(line);
              mask = ~cellfun(@isempty, strfind(TextAsCells,'$NSegments'));
              line = TextAsCells(mask);
              line = strtrim(extractAfter(cell2mat(line),'='));
              params.NSegments = str2num(line);

          elseif(strcmp(line(1),"LinearTraj") == 1) 
                params.RadialMode = "Linear";
          else
              params.RadialMode = "GoldenAngle";
          end
    end
    
    % Next check calibration
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PerformCalibration'));
    params.Calibration = false;
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        line = strtrim(extractAfter(cell2mat(line),'='));
        if (strcmp(line, 'Yes') == 1)
            params.Calibration = true;
            mask = ~cellfun(@isempty, strfind(TextAsCells,'$NumberCalibrationLines'));
            line = TextAsCells(mask);
            line = strtrim(extractAfter(cell2mat(line),'='));
            params.NCalibLin = str2num(line);

        else
            params.Calibration = false;
        end
    end
    % Get number of read points
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_EncMatrix'));
    line = TextAsCells(mask);
    line = strtrim(extractAfter(cell2mat(line),'='));
    line = splitlines(line);
    line = split(line(2),' ');
    params.NCol = str2num(cell2mat(line(1))); % NCol is Siemens language for number of points in a PE line/radial spoke
    params.NLin = str2num(cell2mat(line(2))); % NLin is Siemens language for number of lines
    if (length(line) > 2)
        params.NPar = str2num(cell2mat(line(3))); % NLin is Siemens language for Phase encoding in 3d dimension
    end

    % Extract the FOV
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_Fov'));
    line = TextAsCells(mask);
    line = strtrim(extractAfter(cell2mat(line),'='));
    line = splitlines(line);
    line = split(line(2),' ');
    params.FOV = [str2num(cell2mat(line(1))) str2num(cell2mat(line(2)))];


    % Extract number of repetitions
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_NRepetitions'));
    line = TextAsCells(mask);
    line = strtrim(extractAfter(cell2mat(line),'='));
    line = splitlines(line);
    params.NRep = str2num(cell2mat(line(1)));

    % Extract inversion times
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_FairTIR_Arr'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        params.NInv = str2num(cell2mat(regexp(line, '(?<=\()[^)]*(?=\))', 'match', 'once')));
        line = split(line,')');
        params.InvTimes = str2double(split(line(2),' '));
    end

    % Extract inversion times
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$EffectiveTE'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        params.NEcho = str2num(cell2mat(regexp(line, '(?<=\()[^)]*(?=\))', 'match', 'once')));
        line = split(line,')');
        params.MSMETimes = str2double(split(line(2),' '));
    end

    mask = ~cellfun(@isempty, strfind(TextAsCells,'$EPIC_FlipAngleList'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        params.NEPICFA = str2num(cell2mat(regexp(line, '(?<=\()[^)]*(?=\))', 'match', 'once')));
        line = split(line,')');
        params.EPICFA = str2double(split(line(2),' '));
    end

    % Extract information about slice spoiler
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$SliceSpoiler'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        tmp = cell2mat(regexp(line, '(?<=\()[^)]*(?=\))', 'match', 'once'));
        tmp = strsplit(tmp,',');
        % Split comma separated values
        sliceSpoiler.duration = str2num(tmp{3}); % Spoiler duration in ms
        sliceSpoiler.NCycles = str2num(tmp{2});
        params.sliceSpoiler = sliceSpoiler;
    end
    
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_RefPowCh1'));
    line = TextAsCells(mask);
    line = strtrim(extractAfter(cell2mat(line),'='));
    line = splitlines(line);
    params.RefPow = str2num(cell2mat(line(1)));
        
    
    % Extract Bloch Siegert frequency offset in Hz
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$BSFreqOffset'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        line = TextAsCells(mask);
        line = strtrim(extractAfter(cell2mat(line),'='));
        line = splitlines(line);
        params.BSFreqOffset = str2num(cell2mat(line(1)));
    end
   
    % Extract Bloch Siegert pulse power (watts)
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$BSPulsePower'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        line = TextAsCells(mask);
        line = strtrim(extractAfter(cell2mat(line),'='));
        line = splitlines(line);
        params.BSPulsePower = str2num(cell2mat(line(1)));
    end

    % Extract AFI ratio if available
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$AFITRRatio'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        line = TextAsCells(mask);
        line = strtrim(extractAfter(cell2mat(line),'='));
        line = splitlines(line);
        params.AFIRatio = str2num(cell2mat(line(1)));
    end

    % Extract repetition time and convert to seconds if available
    mask = ~cellfun(@isempty, strfind(TextAsCells,'$PVM_RepetitionTime'));
    line = TextAsCells(mask);
    if (isempty(line) ~=1)
        line = TextAsCells(mask);
        line = strtrim(extractAfter(cell2mat(line),'='));
        line = splitlines(line);
        params.TR = str2num(cell2mat(line(1)))/1000;
    end
    matches = regexp(TextAsCells,'^$ExcPulse1Shape\d+$','match');
    B = [matches{:}];

    % Find number of read dephasing points
   % params.NCha

%    params.data

 %   params.calibData

    %% Load imaging data
    fileName = strcat(path,'\','rawdata.job0');
    fid = fopen(fileName,'r','native');
    if (fid == -1)
        fileName = strcat(path,'\','fid');
        fid = fopen(fileName,'r','native');
    end
    if (fid ~= -1)
        fseek(fid,0,'bof');
        rawdata = fread(fid,'int32');
        fclose(fid);
        rawdata = complex(rawdata(1:2:end),rawdata(2:2:end));
        params.data =rawdata;
        clear("rawdata");
    
        %% Load calibration data if present
        if (params.Calibration == true)
            fileName = strcat(path,'\','rawdata.job1');
            fid = fopen(fileName,'r','native');
            fseek(fid,0,'bof');
            rawdata = fread(fid,'int32');
            fclose(fid);
            rawdata = complex(rawdata(1:2:end),rawdata(2:2:end));
            % Reshape the data using extracted parameters
            rawdata = reshape(rawdata,[params.NCol params.NCalibLin * 2]);
            params.calibData =rawdata;
            clear("rawdata");
        end
    end
    
end