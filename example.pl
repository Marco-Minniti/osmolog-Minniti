%%%%%%%%%%%%%%%%%%%%%%%
% Example Application %
%%%%%%%%%%%%%%%%%%%%%%%

mel((usersData,full), [docker], 64, []). 

mel((videoStorage,full), [docker], 16, []).
mel((videoStorage,medium), [docker], 8, []).

mel((movementProcessing,full), [docker], 8, []).
mel((movementProcessing,medium), [gcc, make], 4, []).
mel((movementProcessing,light), [docker], 2, []).

mel((arDriver,full), [docker], 4, [phone, lightSensor]).
mel((arDriver,medium), [gcc,caffe], 2, [phone, lightSensor]). 
mel((arDriver,light), [gcc], 1, [phone]).


mel((audioDriver,full), [docker], 40, []).
mel((audioDriver,medium), [docker], 20, []).  
mel((audioDriver,light), [docker], 5, []). 

mel((cameraRecognition,full), [gcc,caffe], 4, [phone, lightSensor]). 
%mel((cameraRecognition,full), [gcc,caffe], 6, [phone, lightSensor]). 
mel((cameraRecognition,medium), [gcc,caffe], 2, []). 
mel((cameraRecognition,light), [gcc,caffe], 1, []).

mel((dynamicSensor,full), [docker], 40, []).
mel((dynamicSensor,medium), [gcc,caffe], 6, [phone, lightSensor]). 
mel((dynamicSensor,light), [docker], 20, []).

mel((standbyDriver,full), [docker], 40, []).
%mel((standbyDriver,full), [docker], 20, []).
mel((standbyDriver,medium), [gcc,caffe], 6, [phone, lightSensor]). 
mel((standbyDriver,light), [docker], 5, []).


mel((sCo2,full), [swCo2], 635, []).



mel2mel(mel1, mel2, 999).
application((arApp, full), [(usersData,full), (videoStorage,full), (movementProcessing,full), (arDriver,full)]).
application((arApp, adaptive), [(usersData,full), (videoStorage,_), (movementProcessing,_), (arDriver,_)]).
application((vrApp, adaptive), [(audioDriver,_), (cameraRecognition,_), (dynamicSensor,_), (standbyDriver,_)]).
%application((vrApp, adaptive), [(cameraRecognition,_), (dynamicSensor,_), (standbyDriver,_)]).
%application((vrApp, adaptive), [(audioDriver,_), (cameraRecognition,_), (dynamicSensor,_), (standbyDriver,_), (s1,full)]).
application((appCo2, adaptive), [(sCo2,_)]).



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example Infrastructure %
%%%%%%%%%%%%%%%%%%%%%%%%%%

node(n1, [(gcc,0),(caffe,4)], (6, 3), [(phone,1),(lightSensor,1)]).
node(n2, [(docker, 5)], (100, 1), []).
% nodi uguali, profitto raddoppiato
node(n3, [(gcc,0),(caffe,4)], (6, 6), [(phone,1),(lightSensor,1)]).
node(n4, [(docker, 5)], (100, 2), []).
% nodi uguali, profitto raddoppiato ma sfora i target 
node(n5, [(gcc,0),(caffe,8)], (6, 6), [(phone,2),(lightSensor,2)]).
node(n6, [(docker, 10)], (100, 2), []).
% nodi che supportano tutto, quello 50 profitti uguali, quello con 20 profitti doppi
% node(n7,[(docker,5),(gcc,0),(caffe,4)],(50, 2),[(phone,1),(lightSensor,1)]).
% node(n8,[(docker,10),(gcc,0),(caffe,8)],(15, 6),[(phone,2),(lightSensor,2)]).

%node(edge42, [(gcc,0),(caffe,4)], (6, 3), [(phone,1),(lightSensor,1)]).
%node(cloud42, [(docker, 5)], (100, 1), []).
node(nCo2, [(swCo2,0)], (801, 1), []).

% energyConsumption(NodeId, WattXHwUnit)
energyConsumption(n1,4).
energyConsumption(n2,3).
energyConsumption(n3,1).
energyConsumption(n4,3).
energyConsumption(n5,3).
energyConsumption(n6,2).
energyConsumption(n7,4).
energyConsumption(n8,3).

energyConsumption(edge42, 3).
energyConsumption(cloud42, 2).
energyConsumption(nCo2, 1).

% Format: energyMix( NodeId, [(Fonte fossile, % usata)], [(Fonte rinnovabile, % usata)] ). 
energyMix(n1,[(coal, 0.7), (gas, 0.1), (solar, 0.2)]).
energyMix(n2,[(coal, 0.3), (gasoline, 0.7)]).
energyMix(n3,[(coal, 0.7), (gas, 0.1), (solar, 0.2)]).
energyMix(n4,[(coal, 0.3), (gasoline, 0.7)]).
energyMix(n5,[(coal, 0.3), (gasoline, 0.7)]).
energyMix(n6,[(coal, 1)]).
energyMix(n7,[(coal, 0.3), (gasoline, 0.7)]).
energyMix(n8,[(coal, 0.3), (gasoline, 0.7)]).


energyMix(edge42, [(coal, 0.7), (gasoline, 0.1), (solar, 0.2)]).
energyMix(cloud42, [(gasoline, 0.6), (solar, 0.4)]).
energyMix(nCo2, [(coal, 1)]).

% Format: co2(Fonte, kgCO2-eq/kWh).
co2(coal, 1.1).
co2(gasoline, 1.0).
co2(gas, 0.610).
co2(onshorewind, 0.0097).
co2(offshorewind, 0.0165).
co2(solar, 0.05). 
% https://solarbay.com.au/portfolio-item/how-much-emissions-does-solar-power-prevent/


target(energy, 2000).
target(co2, 1000).


link(edge42, cloud42, 20).
link(edge42, other42, 20).
