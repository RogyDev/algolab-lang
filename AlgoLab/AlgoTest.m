
clc; 
clear;
app = 0;
alogws = AlgoInterpreter('Organizer_nombers.alglab', app, @ecrireMsg, true, 0, 0);

function ecrireMsg(app, msg)

    disp(msg);
end