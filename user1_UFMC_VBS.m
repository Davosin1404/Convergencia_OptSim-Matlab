%____________________________________________________________________
%
%                    Custom Component for MATLAB
%          Automatically generated from VBS template
%
% Name         : user1_UFMC
% Author       : ALUMNO
% Cration Date : Thu Oct 05 19:16:35 2023
%
%____________________________________________________________________
%
%                  MATLAB base workspace variables
%
% - Simulation parameters
%
% sim_technique ::= 'VBS'
%   current simulation technique ('SPT'|'VBSp'|'VBS')
%
% runs :: double vector [runs_num 1]
%   run(s) of the current CCM instance execution
%
% lower_frequency :: double number
%   VBS lower bandwidth frequency expressed in THz
%
% center_frequency :: double number
%   VBS center bandwidth frequency expressed in THz
%
% upper_frequency :: double number
%   VBS upper bandwidth frequency expressed in THz
%
% is_opt_noise :: double number
%   flag indicating if the optical noise is simulated
%
% is_elt_noise :: double number
%   flag indicating if the electrical noise is simulated
%
% polarization_mode :: double number
%   polarization representation of the optical field
%   (1 = signal, 2 = double)
%
% start_valid_samples :: double number
%   instant when a measurement component should start measuring
%   expressed in ps
%
% stop_valid_samples :: double number
%   instant when a measurement component should stop measuring
%   expressed in ps
%
% delt_ps :: double number
%   time sampling step expressed in ps
%
% num_samples :: double number
%   number of signal samples in time domain
%
% time :: double vector [num_samples 1]
%   time sample values expressed in ps
%
%
% - Output signals
%
% TX_UFMC :: double vector [num_samples 1]
%   electrical signal TX_UFMC time domain samples
%
%
%
%____________________________________________________________________

% Write MATLAB code here
%%% PAR�METROS DE TRANSMISI�N

% N�mero de puntos FFT
numFFT = 2^19;
% Tama�o de las sub-bandas (>1)
tamanoSubbanda = 100;
% N�mero de sub-bandas (numSubbandas*tamanoSubbanda<=numFFT)
numSubbandas = 100;
% Separaci�n entre sub-bandas
offsetSubbanda = numFFT/2 - tamanoSubbanda*numSubbandas/2;
% Longitud del filtro
longitudFiltro = 43;
% Atenuaci�n del l�bulo lateral (dB)
atenuacionLobulo = 50;
% Bits por subportadora M-QAM (2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM)
bitsPorSubportadora = 2;
% Creaci�n del filtro Dolph-Chebyshev
filtroPrototipo = chebwin(longitudFiltro, atenuacionLobulo);
% Modulador M-QAM
qamMapper = comm.RectangularQAMModulator('ModulationOrder', ...
    2^bitsPorSubportadora, 'BitInput', true, ...
    'NormalizationMethod', 'Average power');
% Factor de incremento para la amplitud de la se�al
amplitud = 80;
% Creaci�n del vector de datos
inpDatos = zeros(bitsPorSubportadora*tamanoSubbanda, numSubbandas);
% Creaci�n de la se�al UFMC
txSig = complex(zeros(numFFT+longitudFiltro-1, 1));
% Vector para el registro de s�mbolos
symTx = [];
% Vector para los bits de transmisi�n
bitsTx = [];

% hFig = figure;
% axis([-0.5 0.5 -100 20]);
% hold on
% grid on
% 
% xlabel('Frecuencia Normalizada');
% ylabel('PSD (dBW/Hz)')
% title(['UFMC, ' num2str(numSubbandas) ' Subbandas / '  ...
%     num2str(tamanoSubbanda) ' Subportadoras'])


%%% CONSTRUCCI�N DE LA SE�AL UFMC

for bandIdx = 1:numSubbandas
    % Bits de datos por sub-banda
    bitsIn = randi([0 1], bitsPorSubportadora*tamanoSubbanda, 1);
    % S�mbolos por sub-banda
    symbolsIn = qamMapper(bitsIn);
    % Concatenar bits en un solo vector
    inpDatos(:, bandIdx) = bitsIn;
    % S�mbolos transmitidos
    symTx = [symTx; bitsIn];
    % Guardar los bits de transmisi�n
    % save bitsTx.txt symTx -ascii
    % Empaquetamiento de datos en un s�mbolo OFDM
    % Desplazamiento entre sub-bandas
    offset = offsetSubbanda + (bandIdx-1)*tamanoSubbanda;
    % Obtener los s�mbolos OFDM
    symbolsInOFDM = [zeros(offset, 1); symbolsIn; ...
        zeros(numFFT-offset-tamanoSubbanda, 1)];
    % Operaci�n IFFT
    symifftOut = ifft(ifftshift(symbolsInOFDM));
    % Filtro para cada sub-banda desplazada en frecuencia
    bandFilter = filtroPrototipo.*exp(1i*2*pi*(0:longitudFiltro-1)'/numFFT* ...
        ((bandIdx-1/2)*tamanoSubbanda+0.5+offsetSubbanda+numFFT/2));
    % Se�al con el filtro Dolph-Chebyshev
    filterOut = conv(bandFilter, symifftOut);
    
    % Se�al UFMC que se va a transmitir
    txSig = txSig + filterOut;
end

% Parte real de la se�al UFMC
ufmcReal = real(txSig)';
% Parte imaginaria de la se�al UFMC
ufmcImag = imag(txSig)';

% Creaci�n de la se�al PBRS para el sincronismo
pbrsSignal = PRBS([0 1 0 1 0 1 1], [7 6]);
% Amplitud para diferenciar la se�al PBRS
syncSignal = pbrsSignal*max(abs(txSig))*1.5;
% Garantizar la divisibilidad para 8
div8 = zeros(21, 1)';

% Concatenar la se�al
ufmcoutTx = amplitud*[syncSignal ufmcReal ufmcImag div8];
% Vector de relleno de ceros
vectorCeros = zeros(1, 10e2);
% Se�al UFMC con relleno de ceros
ufmcTx = [vectorCeros ufmcoutTx vectorCeros];
% Guardar la se�al UFMC
% save('C:\Users\DELL\Desktop\UFMC\DatosOfTXE.mat','ufmcTx');
% save ufmcTx.txt ufmcTx -ascii
% save('ufmcTx.mat')
bitsTx = inpDatos(:);

numMuestras = 14192128;
numMuestrasOptSim = numMuestras;
diferenciaLongitud = numMuestras - length(ufmcTx); % Diferencia entre la cantidad de muestras y la longitud de la se�al a transmitir
senalTx = [zeros(1, 0.5*diferenciaLongitud) ufmcTx zeros(1, 0.5*diferenciaLongitud)]; % Compensaci�n de longitud
TX_UFMC = senalTx'; % Env�o de la se�al UFMC a OptSim mediante la interfaz "senalTx"

% Guardado de datos en TX 
save('%Ubicacion de la carpeta%\LTEE\user1_UFMC\DatosTX.mat');

save('%Ubicacion de la carpeta%\LTEE\user1_UFMC_RX\DatosOfTX.mat', ...
    'vectorCeros', 'diferenciaLongitud', 'amplitud', ...
    'bitsTx', 'TX_UFMC', 'ufmcTx');


%____________________________________________________________________
%
% End of file
%____________________________________________________________________
