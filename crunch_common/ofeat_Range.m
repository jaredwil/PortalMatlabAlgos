function out = ofeat_Range(data,rate)

data = eegfilt(data, 3, 'hp', rate);
ma = max(data);
mn = min(data);
out = ma(1)-mn(1); 
