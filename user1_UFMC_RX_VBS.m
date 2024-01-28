%____________________________________________________________________
%
%                    Custom Component for MATLAB
%          Automatically generated from VBS template
%
% Name         : user1_UFMC_RX
% Author       : ALUMNO
% Cration Date : Thu Oct 05 19:17:14 2023
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
% - Input signals
%
% RX_UFMC :: double vector [num_samples 1]
%   electrical signal RX_UFMC time domain samples
%
%
%
%
%____________________________________________________________________

% Write MATLAB code here
%%% PARÁMETROS DE TRANSMISIÓN

% Número de puntos FFT
numFFT = 2^19;
% Tamaño de las sub-bandas (>1)
tamanoSubbanda = 100;
% Número de sub-bandas (numSubbandas*tamanoSubbanda<=numFFT)
numSubbandas = 100;
% Separación entre sub-bandas
offsetSubbanda = numFFT/2 - tamanoSubbanda*numSubbandas/2;
% Longitud del filtro
longitudFiltro = 43;
% Atenuación del lóbulo lateral (dB)
atenuacionLobulo = 50;
% Bits por subportadora M-QAM (2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM)
bitsPorSubportadora = 2;
% Creación del filtro Dolph-Chebyshev
filtroPrototipo = chebwin(longitudFiltro, atenuacionLobulo);

% Factor de incremento para la amplitud de la señal
amplitud = 80;
% Vector de relleno de ceros
vectorCeros = zeros(1, 10e2);


%%% RECUPERACIÓN DE LA SEÑAL

% Cargar la señal desde el archivo txt
load('%Ubicacion de la carpeta%\LTEE\user1_UFMC_RX\DatosOfTX.mat');

RX_UFMC = RX_UFMC(((DiferenciaLongitud+1)/2):end-(DiferenciaLongitud/2), 1);
% RX_UFMC = ufmc_tx';
% Obtener el número de muestras
muestras = length(RX_UFMC);
% Muestrear la señal obtenida
senalRx = RX_UFMC(1:1:length(RX_UFMC));

%%% PROCESAMIENTO DE LA SEÑAL
% Asignar la señal recibida a una variable
inData = senalRx;
% Operación FFT
inDataFFT = fft(inData);
% Retirar la componente DC
inDataFFT(1) = 0;
% Realizar la IFFT
inData = real(ifft(inDataFFT)); % Operación IFFT

% Retiro del relleno de ceros
inData = senalRx(length(vectorCeros)+1:length(senalRx)-length(vectorCeros));
% Señal de referencia para la longitud de la señal
senalReferencia = zeros(length(inData), 1);
% Crear la señal PBRS para el sincronismo
sPRBS = 2*PRBS([0 1 0 1 0 1 1], [7 6]);
% Señal de sincronización
sync1 = [0 sPRBS];
% Crear vector de longitud de la señal PBRS
senalReferencia(1:length(sync1)) = sync1';
% Rectificar la señal
senalRectificada = inData - mean(inData);
% FFT de la señal rectificada
Y1 = fft(senalRectificada);
% FFT de la señal de referencia
Y2 = fft(senalReferencia);
% Operación conjugada entre la FFT de las señales rectificada y referencia
Y = ifft(Y1 .* conj(Y2));
% Obtener los máximos del resultante
[maximo, posicionMaximo] = max(abs(Y(1:(length(Y)/2))));
% Sincronizar la señal
senalSincronizada = circshift(inData, [-posicionMaximo+1 0]);

% Señal UFMC en la recepción
senalUFMCRx = senalSincronizada;
% Retirar la señal PBRS y de la señal de divisibilidad
senalUFMC1 = senalUFMCRx(length(sync1):length(senalUFMCRx)-21); 
% Obtener la parte real de la señal recibida
UFMCReal = senalUFMC1(1:length(senalUFMC1)/2)/amplitud;
% Obtener la parte imaginaria de la señal recibida
UFMCImag = senalUFMC1(length(UFMCReal)+1:length(senalUFMC1))/amplitud;
% Construir la señal UFMC
RxUFMC = UFMCReal + UFMCImag*1i;

% Excluir ventanas y filtro adicionales
PaddedRx = [RxUFMC; zeros(2*numFFT - numel(RxUFMC), 1)];
% Realizar la FFT
simbolosRx2 = fftshift(fft(PaddedRx));
% Seleccionar las muestras pares
simbolosRx = simbolosRx2(1:2:end);
% Seleccionar las subportadoras de datos.
simbolosSubportadoras = simbolosRx(offsetSubbanda + (1:numSubbandas*tamanoSubbanda));

% Desempaquetado OFDM
RxFrec = [filtroPrototipo .* exp(1i * 2 * pi * 0.5 * (0:longitudFiltro-1)' / numFFT); zeros(numFFT - longitudFiltro, 1)];
% Ecualización zero-forcing
prototipoFiltroFrec = fftshift(fft(RxFrec));
prototipoFilteroInv = 1./prototipoFiltroFrec(numFFT/2 - tamanoSubbanda/2 + (1:tamanoSubbanda));

% Ordenar los símbolos
simbolosRxMat = reshape(simbolosSubportadoras, tamanoSubbanda, numSubbandas); % Ordenamiento de los símbolos de recepción
% Ecualizador por sub-banda y eliminación de la distorsión por filtro
equalizadosMat = bsxfun(@times, simbolosRxMat, prototipoFilteroInv);
% Obtener símbolos ecualizados
simbolosEqualizadosRx = equalizadosMat(:);
% simbolosEqualizadosRx = simbolosEqualizadosRx ./ abs(simbolosEqualizadosRx);

% Demodulador M-QAM
qamDemod = comm.RectangularQAMDemodulator('ModulationOrder', ...
    2^bitsPorSubportadora, 'BitOutput', true, ...
    'NormalizationMethod', 'Average power');

% Demodular los símbolos QAM
bitsRx = qamDemod(simbolosEqualizadosRx);

% Guardar los bits de recepción
save bitsrx.txt bitsRx -ascii
% save('datosRx.mat')


% Calcular los errores
errores = xor(Bitstx, bitsRx);
% Calcular el BER
BER = sum(errores) / length(Bitstx)

[numero, tasa] = biterr(Bitstx, bitsRx);

% Cálculo EVM
BitsPorSubportadora = 2; % Número de bits por subportadora, modulación M-QAM. 2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM 
EVM_RMS = comm.EVM; % Creación del objeto comm.EVM
EVM_RMS.ReferenceSignalSource = "Estimated from reference constellation"; % Definición del diagrama de constelación de referencia
EVM_RMS.ReferenceConstellation = qammod(0:2^BitsPorSubportadora-1, 2^BitsPorSubportadora, 'UnitAveragePower', true); % Diagrama de constelación de referencia con 2^BitsPorSubportadora estados
EVM1 = EVM_RMS(simbolosEqualizadosRx./abs(simbolosEqualizadosRx)); % Cálculo del EVM de los símbolos de recepción
EVM_VALOR = num2str(EVM1);


%% save BitsRx.txt BitsRx -ascii; % Registro de los bits de recepción
save('%Ubicacion de la carpeta%\LTEE\user1_UFMC_RX\datosRx.mat') % Registro del workspace


%____________________________________________________________________
%
% End of file
%____________________________________________________________________
