addpath("FileIO\")
% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
pth = "datasets\21";
params = LoadBrukerData(pth);