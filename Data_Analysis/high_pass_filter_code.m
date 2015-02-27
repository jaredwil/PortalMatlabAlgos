function y = high_pass_code(x)
%HIGH-PASS-CODE Filters input x and returns output y.

% MATLAB Code
% Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
% Generated on: 26-Feb-2015 13:22:37

%#codegen

% To generate C/C++ code from this function use the codegen command.
% Type 'help codegen' for more information.

persistent Hd;

if isempty(Hd)
  
  % The following code was used to design the filter coefficients:
  %
  % Fstop = 0.1;   % Stopband Frequency
  % Fpass = 2;     % Passband Frequency
  % Astop = 50;    % Stopband Attenuation (dB)
  % Apass = 1;     % Passband Ripple (dB)
  % Fs    = 2000;  % Sampling Frequency
  %
  % h = fdesign.highpass('fst,fp,ast,ap', Fstop, Fpass, Astop, Apass, Fs);
  %
  % Hd = design(h, 'butter', ...
  %     'MatchExactly', 'stopband', ...
  %     'SystemObject', true);
  
  Hd = dsp.BiquadFilter( ...
    'Structure', 'Direct form II', ...
    'SOSMatrix', [1 -2 1 1 -1.99785737576574 0.997861951912608; 1 -1 0 1 ...
    -0.9978619494666 0], ...
    'ScaleValues', [0.998929831919586; 0.9989309747333; 1]);
end

y = step(Hd,x);


