GetEEGData;
chans = 1:5;
GetEEGData('limitchannels', chans);
hunk = 10*60;
GetEEGData('resetindex', 0);
GetEEGData('sethunksize', hunk);
d= GetEEGData('getnext');
hunks= 6*24;
[f,c]= jpwelch(d(:,1), 250);
for i = 1:length(chans)
    iplt{i}.p = zeros(length(f)-1,hunks);
    hundays{i}.p = zeros(length(f)-1, 100);
end
for j = 1:100
    for ii = 1:hunks
        d = GetEEGData('getnext');
        for jj = 1:length(chans)
            [f,c]= jpwelch(d(:,jj), 250);
            f(1) = [];
            iplt{jj}.p(:,ii)= real(f);
        end
    end

    for jj = 1:length(chans)
        hundays{jj}.p(:,j) = mean(iplt{jj}.p');
        subplot(length(chans), 1, jj);
%        im = hundays{jj}.p*64/max(max(hundays{jj}.p));
        im = hundays{jj}.p;
        im(60,:) = 0;
        for i = 1:size(im, 1);
            im(i,:) = im(i,:)*i;
           
        end
        im = im*70/max(max(im));
        image(im)
        drawnow
    end
end