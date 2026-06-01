function SubspaceOpTest()
    %SUBSPACEOPTEST This function performs a test of the sub-space operator to
    % make sure dimensions are as expected

    % First 2D+t time test
    Nx = 128;
    Ny = 128;
    Nt = 50;

    K = 10; % Number of sub-space coefficients

    im = rand([Nx Ny,Nt]);

    % Generate fake sub-space
    phi = rand([Nt,K]); % Generate random sub-space coefficients

    % Generate sub-space operator
    subSpaceOp = SubpaceOp(phi);
    tmp = (subSpaceOp' * im);
    disp("Size after compression: ")
    disp(size(tmp))
    tmp = subSpaceOp * tmp;
    disp("Size after back-projection: ")
    disp(size(tmp))

end