function out = GetGDFID(ident);
% pass a string and returns the number, pass the number and returns the
% string

if ischar(ident)
    switch(ident)
    case 'seizure'
        out = 990;
    case 'possSZ'
        out = 980;
    case 'betabuzz'
        out = 970;
    case 'spikes'
        out = 960;
    case 'other'
        out = 950;
    otherwise 
        out = [];
            
    end
    
else
    switch(ident)
    case 990
        out = 'seizure';
    case 980
        out = 'possSZ';
    case 970
        out = 'betabuzz';
    case 960
        out = 'spikes';
    case 950
        out = 'other';
    otherwise 
        out = [];
            
    end
    
end