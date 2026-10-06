% pn_lidar.m
clear;

% constants
Nlfsr = 10;     % length of LFSR
M = 2;          % ADC oversampling factor
Nave = 2500;    % number of correlations averaged
Kpad = 5;       % length of zero padding

Gn = 100.0;     % noise gain
Gs1 = 1.0;      % sequence gain
Gs2 = 0.83;     % sequence gain
Gs3 = 0.71;     % sequence gain

sh1 = 0;        % delay in ADC samples
sh2 = 2000*M;   % delay in meters*M = ADC samples
sh3 = 4000*M;
Rstart = 20000; % starting range

% generate sequence and convert (0,1) to (+1,-1)
seq = (1+-2*m_sequence(Nlfsr));

Lseq = length(seq); % length of PN sequence
Lrep = Lseq*M;      % length of sequence after oversampling by M
Lpad = Lrep*Kpad;   % length of sequence after padding to make room for differing ranges in returns

s_rep = repelems(seq, [(1:Lseq); M*ones(1,Lseq)]);  % repeat each sample M times
s_pad = [s_rep zeros(1,Lpad)];                      % pad out with zeros because the ADC record has to be much longer than the transmit sequence.

% delay the returns and apply gains
s1 = Gs1*circshift(s_pad,sh1);
s2 = Gs2*circshift(s_pad,sh2);
s3 = Gs3*circshift(s_pad,sh3);

% compute once just to get correlation size
noise = Gn*randn(1,Lrep+Lpad);
s_noise = s1 + s2 + s3 + noise;
c = fftconv(fliplr(s_rep), s_noise);
Lcorr = length(c);

% average a bunch of correlations
c_ave = zeros(1,Lcorr);
for i=1:Nave

    noise = Gn*randn(1,Lrep+Lpad);      % make noise
    s_noise = s1 + s2 + s3 + noise;     % add returns to noise
##    s_quant = round(s_noise);           % quantize the signal
    s_quant = sign(s_noise);            % 1-bit quantizer
    c = fftconv(fliplr(s_rep), s_quant);% correlate against the transmit sequence
    c_ave = c_ave + c;                  % average correlations

endfor

% plot
figure(1);
plot(Rstart+(1:length(c_ave))/M,c_ave, 'r.-');
title_str = sprintf("PN Lidar Simulation\n");
title_str = strvcat(title_str, sprintf("Lseq = %d number of chips in sequence",Lseq));
title_str = strvcat(title_str, sprintf("M = %d ADC samples per chip", M));
title_str = strvcat(title_str, sprintf("Nave = %d averages", Nave));
title_str = strvcat(title_str, sprintf("Gn = %d noise standard deviation", Gn));
title_str = strvcat(title_str, sprintf("Gs1 = %d amplitude of nearest return", Gs1));
title(title_str);
xlabel("Range Offset in Meters");
ylabel("Response in Counts");

##figure(2);
##stem(seq(40:60), 'r*');
##title("Portion of PN Sequence");
##
##figure(3);
##stem(s_noise(1:100))
##title("s_noise = s1 + s2 + s3 + noise (unquantized)");
##
##figure(4);
##stem(s_quant(1:100))
##title("s_quant 1-bit quantized to (+1,-1)");







