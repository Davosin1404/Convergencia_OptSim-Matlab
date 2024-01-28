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

% Factor de incremento para la amplitud de la se�al
amplitud = 80;
% Vector de relleno de ceros
vectorCeros = zeros(1, 10e2);


%%% RECUPERACI�N DE LA SE�AL

% Cargar la se�al desde el archivo txt
load('%Ubicacion de la carpeta%\LTEE\user1_UFMC_RX\DatosOfTX.mat');

RX_UFMC = RX_UFMC(((DiferenciaLongitud+1)/2):end-(DiferenciaLongitud/2), 1);
% RX_UFMC = ufmc_tx';
% Obtener el n�mero de muestras
muestras = length(RX_UFMC);
% Muestrear la se�al obtenida
senalRx = RX_UFMC(1:1:length(RX_UFMC));

%%% PROCESAMIENTO DE LA SE�AL
% Asignar la se�al recibida a una variable
inData = senalRx;
% Operaci�n FFT
inDataFFT = fft(inData);
% Retirar la componente DC
inDataFFT(1) = 0;
% Realizar la IFFT
inData = real(ifft(inDataFFT)); % Operaci�n IFFT

% Retiro del relleno de ceros
inData = senalRx(length(vectorCeros)+1:length(senalRx)-length(vectorCeros));
% Se�al de referencia para la longitud de la se�al
senalReferencia = zeros(length(inData), 1);
% Crear la se�al PBRS para el sincronismo
sPRBS = 2*PRBS([0 1 0 1 0 1 1], [7 6]);
% Se�al de sincronizaci�n
sync1 = [0 sPRBS];
% Crear vector de longitud de la se�al PBRS
senalReferencia(1:length(sync1)) = sync1';
% Rectificar la se�al
senalRectificada = inData - mean(inData);
% FFT de la se�al rectificada
Y1 = fft(senalRectificada);
% FFT de la se�al de referencia
Y2 = fft(senalReferencia);
% Operaci�n conjugada entre la FFT de las se�ales rectificada y referencia
Y = ifft(Y1 .* conj(Y2));
% Obtener los m�ximos del resultante
[maximo, posicionMaximo] = max(abs(Y(1:(length(Y)/2))));
% Sincronizar la se�al
senalSincronizada = circshift(inData, [-posicionMaximo+1 0]);

% Se�al UFMC en la recepci�n
senalUFMCRx = senalSincronizada;
% Retirar la se�al PBRS y de la se�al de divisibilidad
senalUFMC1 = senalUFMCRx(length(sync1):length(senalUFMCRx)-21); 
% Obtener la parte real de la se�al recibida
UFMCReal = senalUFMC1(1:length(senalUFMC1)/2)/amplitud;
% Obtener la parte imaginaria de la se�al recibida
UFMCImag = senalUFMC1(length(UFMCReal)+1:length(senalUFMC1))/amplitud;
% Construir la se�al UFMC
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
% Ecualizaci�n zero-forcing
prototipoFiltroFrec = fftshift(fft(RxFrec));
prototipoFilteroInv = 1./prototipoFiltroFrec(numFFT/2 - tamanoSubbanda/2 + (1:tamanoSubbanda));

% Ordenar los s�mbolos
simbolosRxMat = reshape(simbolosSubportadoras, tamanoSubbanda, numSubbandas); % Ordenamiento de los s�mbolos de recepci�n
% Ecualizador por sub-banda y eliminaci�n de la distorsi�n por filtro
equalizadosMat = bsxfun(@times, simbolosRxMat, prototipoFilteroInv);
% Obtener s�mbolos ecualizados
simbolosEqualizadosRx = equalizadosMat(:);
% simbolosEqualizadosRx = simbolosEqualizadosRx ./ abs(simbolosEqualizadosRx);

% Demodulador M-QAM
qamDemod = comm.RectangularQAMDemodulator('ModulationOrder', ...
    2^bitsPorSubportadora, 'BitOutput', true, ...
    'NormalizationMethod', 'Average power');

% Demodular los s�mbolos QAM
bitsRx = qamDemod(simbolosEqualizadosRx);

% Guardar los bits de recepci�n
save bitsrx.txt bitsRx -ascii
% save('datosRx.mat')


% Calcular los errores
errores = xor(Bitstx, bitsRx);
% Calcular el BER
BER = sum(errores) / length(Bitstx)

[numero, tasa] = biterr(Bitstx, bitsRx);

% C�lculo EVM
BitsPorSubportadora = 2; % N�mero de bits por subportadora, modulaci�n M-QAM. 2: 4QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM 
EVM_RMS = comm.EVM; % Creaci�n del objeto comm.EVM
EVM_RMS.ReferenceSignalSource = "Estimated from reference constellation"; % Definici�n del diagrama de constelaci�n de referencia
EVM_RMS.ReferenceConstellation = qammod(0:2^BitsPorSubportadora-1, 2^BitsPorSubportadora, 'UnitAveragePower', true); % Diagrama de constelaci�n de referencia con 2^BitsPorSubportadora estados
EVM1 = EVM_RMS(simbolosEqualizadosRx./abs(simbolosEqualizadosRx)); % C�lculo del EVM de los s�mbolos de recepci�n
EVM_VALOR = num2str(EVM1);


%% save BitsRx.txt BitsRx -ascii; % Registro de los bits de recepci�n
save('%Ubicacion de la carpeta%\LTEE\user1_UFMC_RX\datosRx.mat') % Registro del workspace


%____________________________________________________________________
%
% End of file
%____________________________________________________________________
