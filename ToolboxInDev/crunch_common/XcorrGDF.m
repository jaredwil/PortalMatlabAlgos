function xarray = XcorrGDF(gdf, rate)
xarray = [];
IDs = unique(gdf(:,1));

xarray.rate = rate;
ybins = ceil(2*rate*0.05+1);    % 0.05 makes it 50ms
xbindivisor = rate*60*1;       % 10 makes it 10 minutes
sz = floor(ybins/2);
k = 0;

for i = 1:(length(IDs)-1)
    for j = (i+1):length(IDs)
        % make bins first: let's make them 10 minutes, by 50ms
        
        k = k+1;
        xarray(k).x = IDs(i);
        xarray(k).y = IDs(j);
        xarray(k).array = zeros(ceil(gdf(end,2)/xbindivisor), ybins);
        xarray(k).First = gdf(find(gdf(:,1) == IDs(i)),2);
        xarray(k).Second = gdf(find(gdf(:,1) == IDs(j)),2);
        for ii = 1:length(xarray(k).First)
            
            % find the xcorr values for this instance
            temp = xarray(k).Second(find(xarray(k).Second > xarray(k).First(ii)-sz & xarray(k).Second < xarray(k).First(ii)+sz));
            temp = temp - xarray(k).First(ii); % correct time
            temp = temp + sz+1;    % add offset to make all positive
            
            % find the time of its instance
            indx = ceil(xarray(k).First(ii)/xbindivisor);     % bins are not centered: bin 1 goes from 0-1
            
            % add this result to the total
            xarray(k).array(indx,temp) = xarray(k).array(indx,temp) + 1;
            
        end
    end
end
