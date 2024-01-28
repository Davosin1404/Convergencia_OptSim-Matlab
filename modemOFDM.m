%=========================================================================
%                            MODULADOR LTE
%=========================================================================
function [y,NT,NsymT] = modemOFDM(X,Nc,Nda,CP,PC)
%-------------------------------------------------------------------------
% X=   vector de simbolos a transmitir
% N=   numero de puntos de FFT(256)
% Nda=  numero de portadoras de datos(254)
% Np=  numero de portadoras piloto (0)
% CP=  prefijo ciclico(no)
% PC=  si hay prefijo ciclico =1 si no hay =0
%-------------------------------------------------------------------------
% size(X) %1 63000
save('simbolostx.mat','X')      % guarda los simbolos a tx
Lx=size(X,2);                   % Tamano del vector de simbolos a transmitir
Nsym = Lx/Nda;                   % Numero de simbolos OFDM en la cadena
Ng = Nc*CP;                      % Longitud del prefijo ciclico
if PC
 NT = Nc+Ng;                     % Longitud total del simbolo OFDM en tiempo cuando hay prefijo ciclico
else
 NT = Nc;                        % Longitud total del simbolo OFDM en tiempo cuando NO hay prefijo ciclico
end
%--------------------------------------------------------------------------
% Creacion de la señal OFDM
%--------------------------------------------------------------------------
Xtmp = reshape(X,Nda,Nsym);      % Separamos los simbolos en columnas
% size(Xtmp)% 63 1000
Xd = zeros(Nc,Nsym);             % matriz para la generar el simbolo OFDM
% size(Xd) %% 128 1000
for jj=0:62                    %generacion de la parte hermitica
    kk=63-jj;
     Xtmpconj(kk,:)=Xtmp(jj+1,:);    
end  
for ii=1:Nsym  
XOFDM(2:64,ii) =  Xtmp(1:63,ii).';     % llenado de  datos de la matriz OFDM hermitica  
XOFDM(66:128,ii) =  Xtmpconj(1:63,ii)';% llenado de  datos de la matriz OFDM hermitica (datos conjugados)
end
%%% para la mitad de la señal
fil1=XOFDM([1:64],:); % agregar del 2 al 64 antes de los ceros
size(fil1);
fil2=XOFDM([65:128],:);% agregar del 65 al 127 despues de los ceros
size(fil2);
% coo=XOFDM(:,1).';% e obtiene todas las filas de una columnaa
% size(coo)%128 0 y 1 complejos hacia abajo 
% co= [coo(1:64)  zeros(1,128)  coo(65:128) ].';%%% falta mil 
% size(co)%256 hacia la derecha
% c= zeros(256,1000);
%  for i=1:256
%   c(i,1)=co(i,1);    
%  end 
c= zeros(8192,1000);
 for i=1:64
for j=1:1000

      c(i,j)=fil1(i,j); % agregar del 2 al 64 antes de los ceros
      c(i+8128,j)=fil2(i,j); % agregar del 2 al 64 antes de los ceros
%     end 
    end
 end
 size( c);%256 1000
%  x = ifft( c,256);                   % obtenemos la senal OFDM en tiempo (en las columnas estan los simbolos)
%  xps=reshape(x,1,256000);             % datos de paralelo a serie
 x = ifft( c,8192);                   % obtenemos la senal OFDM en tiempo (en las columnas estan los simbolos)
 xps=reshape(x,1,8192000);             % datos de paralelo a serie


 %--------------------------------------------------------------------------
xprbs=PRBS([1 0 1 1 0 1 1],[7 6]);   % generador PRBS 7 para sincronismo
xprbs1=xprbs';
save PRBStx.txt xprbs1 -ascii       %guarda los datos PRBS+OFDM a tx
%xprbs= 2*xprbs-1;
xprbs =10*(xprbs * max(abs(xps))); % 0,5 de amplitud / sin nada se muestra el PBRS
xxofdm=[0 xprbs xps  ];             % generacion de la trama [0+PBRS+simbolos OFDM] para completar 128128 divisible para 8 que pide el AWG
xofdm=40*[ zeros(1,3000000) xxofdm zeros(1,3000000)];             % 1000000generacion de la trama [0+PBRS+simbolos OFDM] para completar 128128 divisible para 8 que pide el AWG

if PC                            % Bloque CP: Añadimos el prefijo ciclico si procede
 xtmp(1:Ng,:) = x(Nc-Ng+1:Nc,:);   % Coloco las ultimas muestras de primeras para CP
 xtmp(Ng+1:NT,:) = x;
 xofdm = xtmp;                   % simbolo OFDM+CP  en columnas
end
NsymT=Nsym+1;                    % numero de simbolos totales(OFDM + trainning)
y = xofdm;                       % vector de la senal OFDM a transmitir (PBRS+OFDM)

y1=[y y y y];
y1=y1';
save signalofdmtx.txt y1 -ascii %guarda los datos PRBS+OFDM a tx
% save paramentrosOFDM_moderm.mat
end
