
clc; 
clear;
app = 0;
alogws = AlgoInterpreter('script.alglab', app, @ecrireMsg, true, 0, 0);

function ecrireMsg(app, msg)
    disp(msg);
end