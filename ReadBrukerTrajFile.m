%% Functio to read bruker traj file and return the trajectory

function traj = ReadBrukerTrajFile(pth)
    % Data is store as uint32
    fileName = strcat(pth,'\','traj');
    fid = fopen(fileName,'r','native');
    fseek(fid,0,'bof');
    rawdata = fread(fid,'float64');
    fclose(fid);
    traj = complex(rawdata(1:2:end),rawdata(2:2:end));

end