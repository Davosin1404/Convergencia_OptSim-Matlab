%% Generador de bits aleatorios
function [datos] = genbits(n)

datos= randi([0,1],[1,n]);

%Creación del archivo para los bits en TX
fileID = fopen('datostx.txt','w');
fprintf(fileID,'%5f\n',datos);
fclose(fileID);
end 
