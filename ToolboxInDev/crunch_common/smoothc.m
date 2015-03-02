function mO = smoothc(mI, Nr, Nc)

% SMOOTHC.M: Smooths matrix data, cosine taper.
%			MO=SMOOTHC(MI,Nr,Nc) smooths the data in MI
%           using a cosine taper over 2*N+1 successive points, Nr, Nc points on 
%           each side of the current point.  
%
%           Inputs: mI - original matrix
%                   Nr - number of points used to smooth rows
%                   Nc - number of points to smooth columns
%           Outputs:mO - smoothed version of original matrix
%
%           

% Determine convolution kernel k
Nr=Nr+1;
Nc=Nc+1;
kr=2*Nr+1;
kc=2*Nc+1;
midr=Nr+1;
midc=Nc+1;
maxD=sqrt(Nr^2+Nc^2);
for irow=1:kr,
    for icol=1:kc,
        D=sqrt((midr-irow)^2+(midc-icol)^2);
        k(irow,icol)=cos(D*pi/2/maxD);
    end;
end;

% Perform convolution
k = k/(sum(sum(k)));
mO=conv2(mI,k,'same');


