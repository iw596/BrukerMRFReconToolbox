addpath("FileIO\")
pth = "datasets\Yasaman_MRF10122024\MRF_IWFISP";
params = LoadBrukerData(pth);
powerList = [params.RefPow' params.MRFPowerList'];
WriteMRFPowerList("C:\\Users\\isaac\\Documents\\dev\\MRFSim\\MRFPatterns\\MRFPower.bin",powerList)