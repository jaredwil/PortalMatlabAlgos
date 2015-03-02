function result = feat_DCN(data, rate)

[Ns,Nch] = size(data);
%data = detrend(data,0);   % Make channels zero-mean b/c ratio of DC term to noise affects condition number
   % Reverted until utility proven. Between-channel DCs may also point to anomaly.
result = 1 + (cond(data)-1)/Nch;