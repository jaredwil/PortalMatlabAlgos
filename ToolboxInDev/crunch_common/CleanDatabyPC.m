function [out, weights] = CleanDatabyPC(action, tdata);
%
% to use call:
%
% cleaned = CleanDatabyPC(rawdata);     % to clean the data without plotting
% cleaned = CleanDatabyPC(rawdata,0);   % to clean the data without plotting
% cleaned = CleanDatabyPC(rawdata,1);   % to clean the data with plotting
%
% rawdata is the original data of channels and time, in a 2-D matlab array.
% cleaned is a 2-D array, [time,channels+2] of cleaned data. The last
% two columns returned are the first and second principal component vectors.
% NOTE: (1) a minimum of 3 channels is required
%       (2) the longer dimension of rawdata will be treated as time.
global ptitle;
global showData;			% internal use only
global analogDisplayOffset;   % number of analog units by which to displace each trace

if ischar(action)
    switch(action)


        case('PlotData')
            % makes a figure with the title using tdata
            % offsets each col by -100;

            figure ('Name', ptitle, 'NumberTitle', 'off');

            [m,n] = size(tdata);

            for i = 1:n
                tdata(:,i) = tdata(:,i) -(i-1)*analogDisplayOffset;
            end
            plot(tdata);
            drawnow
            zoom on





        case('GetCleanedData')

            %%%%%%%%%%%%%%%%%% step 1: get the tdata %%%%%%%%%%%%%%%%%%%%%%
            % check the tdata

            if isempty(tdata)
                out = [];
                fprintf('Empty rawdata. Aborting.\n');
                return
            end;

            [m,n] = size(tdata);

            if n < 3
                out = [];
                fprintf('Rawdata must have at least 3 channels. Aborting.\n');
                return
            end

            if showData
                ptitle = 'raw';
                CleanDatabyPC('PlotData',tdata);
            end;


           [out, weights] = CleanDatabyPC('pca2',tdata);		% get 1st cleaned estimate
           if showData
                ptitle = 'cleaned';
                CleanDatabyPC('PlotData',out);
            end;

            



        case('pca2')
            % tdata is in columns
            % subtract the mean from the tdata
            ch=size(tdata,2);    % number of channels
            Mn=mean(tdata);
            for i=1:ch
                tdata(:,i)=tdata(:,i)-Mn(i);
            end
            

            warning off
            C=cov(tdata);                   % get the covariance matrix
            for i=1:ch                      % for each channel
                j=logical(ones(1,ch));      % a row vector of ones
                j(i)=0;                     % set the current channel to 0
                noti=tdata(:,j);            % subset of tdata not in channel i
                Cnoti=C(j,j);               % cov for those channels
                
                [v,d]=eig(Cnoti);
                [junk,k]=sort(diag(d));   % sorts according to eigenvalues
                v=v(:,k);d=d(:,k);        % rearrange v and d in ascending order
                v=v(:,[end end-1 end-2]); % take principle components 1 through 3
                pc=noti*v;                % project tdata onto v
                pc=[pc,tdata(:,i)];       % matrix of 3 pc's and ch of interest
                %pc is the rotated matrix, sans the ith value: it has been added on the end 
                Cpc=cov(pc);              % the cov of this matrix
                a1(i)=Cpc(1,4)/Cpc(1,1);
                a2(i)=Cpc(2,4)/Cpc(2,2);
                a3(i)=Cpc(3,4)/Cpc(3,3);

                if i==1
                    art=[a1(i)*pc(:,1), a2(i)*pc(:,2), a3(i)*pc(:,3)];
                else
                    % building up the pc's
                    art=art+[a1(i)*pc(:,1), a2(i)*pc(:,2), a3(i)*pc(:,3)];
                end
                
                % now subtract off the common signal
                out(:,i)=tdata(:,i) -a1(i)*pc(:,1) -a2(i)*pc(:,2) -a3(i)*pc(:,3);
                
            end
            art=art/ch;
            out=[out,art];
            a1 % channel weights for first pc
            a2 % channel weights for second pc
            a3 % channel weights for third pc
            weights = [a1(1);a2(1);a3(1)];
            %sum(abs(a1))
            %sum(abs(a2))
            %sum(abs(a3))
            
            
    end






else

    if exist('tdata')
        showData = tdata;
    else
        showData = 0;		 		%don't plot data
    end
    analogDisplayOffset = mean(mean(abs(action)))*10;		% number of analog units by which to displace each trace
    out = [];

    data = action;
    [m,n] = size(data);

    % assume there are fewer data channels than there are time points!
    if n > m
        data = data';
        [m,n] = size(data);
    end

    [out, weights] = CleanDatabyPC('GetCleanedData',data);

end