pth = "datasets/64/pdata/1/2dseq";
parans = LoadBrukerData("datasets/64");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 31]);
fclose(fid)