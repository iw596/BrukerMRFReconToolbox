%%% Function to read siemens PTA RF pulse structure. 
%%% a PTA RF file is an ASCII strucure. So we read it in
%%% and then parse out the header information we need 
function res = ReadSiemensPulseFile(filepath)
 
    opt = {'CollectOutput',true};
    hdr = {};
    out = {};
    [fid,msg] = fopen(filepath,'rt');
    assert(fid>=3,msg) % ensure the file opened correctly.
    while ~feof(fid)
        hdr{end+1} = fgetl(fid);
        out(end+1) = textscan(fid,'%f%f',opt{:});
    end
    fclose(fid);
    res.hdr = hdr;
    out = out(~cellfun('isempty',out));
    out = cell2mat(out);
    amp = out(1:2:end);
    phs = out(2:2:end);
    res.out = amp.*exp(-1j.*phs);
end

function txt = get_char_in_block(fid, size)
block  = char(fread(fid, size, 'char')');
endpos = strfind(block,sprintf('\n'));
txt    = block(1:endpos(1)-1); % stop at first nullchar
end % fcn
function txt = get_comment_block(fid, size)
block  = char(fread(fid, size, 'char')');
endpos = strfind(block,sprintf('\n'));
txt    = block(1:endpos(end)-1); % stop at last nullchar in the block
end % fcn