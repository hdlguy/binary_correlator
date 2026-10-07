% gen_rom_data.m
% Generates one record of synthetic 1-bit rx data for the block ROM in the on-chip
% data source, plus the correlation the hardware should produce from it.
%
% Run from the octave directory:  octave --no-gui -q gen_rom_data.m
%
% The record is noise plus three delayed copies of the transmit sequence, quantized to
% 1 bit. No oversampling (one sample per chip) and no averaging: the noise is set low
% enough that a single record gives clear peaks.
%
% Outputs (in source/datagen/):
%   rx_record.mem       ROM contents for $readmemb, one bit per line, sample 0 first.
%                       Bit 0 = +1, bit 1 = -1.
%   corr_expected.txt   Expected correlator output for each sample of the record, one
%                       signed integer per line. It assumes the ROM is played back to back
%                       in a loop, so after the first pass the correlator window wraps
%                       around the record and every output is well defined:
%                       y[n] = sum_i t[i] * x[mod(n - Lseq + 1 + i, Lrec)].
%                       A return at delay d peaks at output n = d + Lseq - 1.

clear;

% constants
Nlfsr = 10;                     % LFSR length, sequence length 2^Nlfsr - 1 = 1023
Krec  = 3;                      % record length in sequence lengths
Gn    = 3.0;                    % noise standard deviation
Gs    = [1.00 0.83 0.71];       % return amplitudes
dly   = [100 900 1800];         % return delays in samples (each <= Lrec - Lseq)
seed  = 1;                      % fixed seed so the ROM is reproducible
do_plot = !isempty(getenv("DISPLAY"));

outdir = "../source/datagen";

% transmit sequence, (0,1) -> (+1,-1)
seq  = 1 - 2*m_sequence(Nlfsr);
Lseq = length(seq);
Lrec = Krec*Lseq;
if any(dly < 0 | dly > Lrec - Lseq)
    error("delays must be in 0..%d so each return fits in the record", Lrec - Lseq);
endif

% returns plus noise, quantized to 1 bit
randn("seed", seed);
s = zeros(1, Lrec);
for k = 1:numel(Gs)
    s(dly(k) + (1:Lseq)) += Gs(k) * seq;
endfor
x = sign(s + Gn*randn(1, Lrec));
x(x == 0) = 1;                  % sign(0) never happens in practice; map it to +1
bits = (x < 0);                 % +1 -> 0, -1 -> 1

% expected hardware output: circular correlation, window ending at sample n
y = zeros(1, Lrec);
for n = 0:Lrec-1
    idx = mod(n - Lseq + 1 + (0:Lseq-1), Lrec) + 1;
    y(n+1) = sum(seq .* x(idx));
endfor

% write files
if !exist(outdir, "dir")
    mkdir(outdir);
endif
fid = fopen(fullfile(outdir, "rx_record.mem"), "w");
fprintf(fid, "%d\n", bits);
fclose(fid);
fid = fopen(fullfile(outdir, "corr_expected.txt"), "w");
fprintf(fid, "%d\n", y);
fclose(fid);

% report
pk = dly + Lseq - 1;            % expected peak outputs (0-based)
mask = true(1, Lrec);
for k = 1:numel(pk)
    mask(max(1, pk(k)-2+1):min(Lrec, pk(k)+2+1)) = false;    % exclude +-2 around each peak
endfor
printf("record %d samples, %d ones; noise %.1f\n", Lrec, sum(bits), Gn);
for k = 1:numel(pk)
    printf("  return %d: gain %.2f, delay %4d -> peak %4d at output %4d\n", k, Gs(k), dly(k), y(pk(k)+1), pk(k));
endfor
printf("  off-peak: std %.1f, max |y| %d\n", std(y(mask)), max(abs(y(mask))));
printf("wrote %s/rx_record.mem and corr_expected.txt\n", outdir);

% plot
if do_plot
    figure(1);
    plot(0:Lrec-1, y, "b.-", pk, y(pk+1), "ro");
    title(sprintf("Expected correlator output, Lseq = %d, Gn = %.1f, no averaging", Lseq, Gn));
    xlabel("Output index n (peak at delay + Lseq - 1)");
    ylabel("Correlation");
    grid on;
endif
