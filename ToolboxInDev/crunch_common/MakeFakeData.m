function out = MakeFakeData(data1, data2, data3);
% call first passing outfilename, rate, and number of channels, ie
%   MakeFakeData('c:\MyData.eeg', 250, 2);
% then repeatedly call passing data (time by channels), ie,
%   MakeFakeData(datahunk);
% when done call passing empty array this will close the file
%   MakeFakeData([]);



if ischar(data1)
    labels = [];
    for i = 1:data3
        labels = [labels; sprintf('%03d',i)];
    end
    jwrite2bni([],data1(1:end-4),data2,[0 0 0 0],[0 0 0],labels, 1, []);
else
    jwrite2bni(data1');
end
    