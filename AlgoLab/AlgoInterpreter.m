function workspace_vars = AlgoInterpreter(script_path, app, writefunc, classic_input, inputfunc, clearInput)

% ---------------------------------------
%  ENPC-1erAnnee G1 Babaarbi Mohammed Ala
% ---------------------------------------
%writefunc(app, 'huhgg');

%fileID = fopen('script.alglab');
fileID = fopen(script_path);
s = textscan(fileID, '%s', 'Delimiter', '^');
r = s{1};
fclose(fileID);
difVars = false;
varNum = 1;
funcNum = 1;
once_fix = true;
i = 1;
vec_set_index = -1;
loop_for_first_back = false;
ws = {};

%for i = 1:length(r) 
while(i < length(r))
    line = r{i};
   % disp(line);
    
    % skip line if it starts with '//' (comment), just like '%' in matlab
    if(startsWith(line, '//'))
          i = i + 1;
        continue;
    end
    
  if(strcmp(line, 'Algorithme') || strcmp(line, 'algorithme'))
    i = i + 1;
    continue;
  end

    if(strcmp(line, 'Variables') || strcmp(line, 'variables'))
        difVars = true;
        i = i + 1;
        continue;
    end
% ------------------- VARIABLES ---------------------
    if(difVars)

        if(strcmp(line, 'Debut') || strcmp(line, 'debut'))
            difVars = false;
            i = i + 1;
            continue;
        end

        vtype = '';
        vname = '';
        vval = '';
        tokens = strsplit(line);
        switch tokens{1}
            case 'entier'
                vtype = 'entier';
                vval = 0;
            case 'chain'
                 vtype = 'chain';
                vval = '';
            case 'booleen'
                vtype = 'booleen';
                vval = 0;
            case 'vecteur'
                vtype = 'vecteur';
            case 'fonction'
                vtype = 'fonction';
                vval = i;
        end
        vname = tokens{2};
        
        if(strcmp(vtype, 'vecteur'))
           if(~strcmp(tokens{3}, 'de'))
                    writefunc(app, ['Erreur en ligne ', num2str(i), ' : manque de "de"']);
                    workspace_vars = ws;
                    return;
           end
           if(str2double(tokens{4}) > 0)
               vec_size = str2double(tokens{4});
               vec_size = fix(vec_size); % get naturel part only
               vec_type = tokens{5};
               if(strcmp(vec_type,'entier'))
                    vval = zeros(1, vec_size);
               end
               if(strcmp(vec_type,'chain'))
                    vval = strings(1, vec_size);
               end
           else
                writefunc(app, ['Erreur en ligne ', num2str(i), ' : La taille de vecteur doit être un nombre positive!']);
                workspace_vars = ws;
                return;
           end
        end

        ws{varNum, 1} = vtype;
        ws{varNum, 2} = vname;
        ws{varNum, 3} = vval;
        varNum = varNum + 1;

        if(strcmp(vtype,'fonction'))
            fws{funcNum, 1} = vname;

            funcNum = funcNum + 1;
            % skip function body
             for ii = i:length(r) 
                   if(strcmp(r{ii} ,'fin_foncion'))
                        i = ii;
                        break;
                   end
             end
        end

        
    else
        
    %{
    if(once_fix) 
        once_fix = false; 
        disp('varNumvarNum');
        disp(size(ws));
        ws{varNum, 1} = '_0_';
        ws{varNum, 2} = '_0_';
        ws{varNum, 3} = varNum + 1;
        varNum = varNum + 1;
    end
    %}
        
    % ------------------- Code ---------------------
    %tokens = strsplit(line);
    tokens = SplitTokens(line);
    operation = '';
    varIndex = 1;
    for j = 1:length(tokens)

           if(strcmp(operation, 'assign'))
               if(strcmp(ws{varIndex, 1}, 'entier'))
                    ws{varIndex, 3} = GetResult(ws, j, tokens, false);

                    operation = '';
                    vec_set_index = -1;
                    break;
                   
               end
               if(strcmp(ws{varIndex, 1}, 'chain'))
                    
                    ws{varIndex, 3} = GetResult(ws, j, tokens, false);

                     operation = '';
                    vec_set_index = -1;
                    break;
               end
               if(strcmp(ws{varIndex, 1}, 'booleen'))
                    if(GetResult(ws, j, tokens, false) == 0)
                        ws{varIndex, 3} = 0;
                    else
                        ws{varIndex, 3} = 1;
                    end
                   
                     operation = '';
                    vec_set_index = -1;
                    break;
               end
                if(strcmp(ws{varIndex, 1}, 'vecteur'))
                    op_result =  GetResult(ws, j, tokens, true);
                    if(vec_set_index > length( ws{varIndex, 3}))
                        writefunc(app, ['Erreur en ligne ', num2str(i), ' : L"indice ne doit pas etre plus grand que ', num2str(length( ws{varIndex, 3}))]);
                        workspace_vars = ws;
                        return;
                    else
                        ws{varIndex, 3}(vec_set_index) = op_result;
                    end
                   
               end
                operation = '';
                vec_set_index = -1;
           end
        
           if(strcmp(tokens{j}, 'ecrire'))
                writefunc(app, GetResult(ws, j, tokens, false));
           end
           % TODO: better read 'lire' implementation :/
           if(strcmp(tokens{j}, 'lire'))
               for kk =1:(varNum - 1) 
                    if(strcmp(tokens{j+2}, ws{kk, 2}))
                        if(classic_input) % matlab command window
                            ws{kk, 3} = input('');
                        else % AlgoLab editor command window
                            got_input = false;
                            while(got_input == false)
                                
                                pause(0.2);
                                got_val = inputfunc(app);
                                if(~strcmp(inputfunc(app), ''))
                                    got_input = true;
                                end
        
                                ws{kk, 3} = got_val;
                                clearInput(app);
                            end
                            break; % stop looping through tokens
                        end
                    end
               end
           end

       for k =1:(varNum - 1)
           

            if(strcmp(tokens{j}, ...
                    ws{k, 2}) ...
                    && length(tokens) >= j+1)

                if( strcmp(tokens{j+1} ,'=') && ~strcmp(tokens{j+2} ,'='))
                    operation = 'assign';
                    varIndex = k;
                    break;
                    
                else
                    % in case of a vecteur....
                     if( strcmp(tokens{j+1} ,'['))
                            to_assign = '';
                            for aterms = j+2 : length(tokens)
                                if(strcmp(tokens{aterms}, ']'))
                                    break;
                                end
                                a_n_term = tokens{aterms};
                                for kk =1:(varNum - 1) 
                                    if(strcmp(a_n_term, ws{kk, 2}))
                                        switch(ws{kk, 1})
                                            case 'entier'
                                                a_n_term = num2str(ws{kk, 3});
                                            otherwise
                                                a_n_term = ws{kk, 3}; 
                                        end                                        
                                    end
                                end
                                 to_assign = strcat(to_assign , a_n_term);
                            end
                           
                           
                            op_result = eval(to_assign);
                            if(op_result < 0)
                                writefunc(app, ['Erreur en ligne ', num2str(i), ' : L"indice doit etre un nombre positif!']);
                                workspace_vars = ws;
                                return;
                            else
                                vec_set_index = (op_result + 1);
                                 %disp(vec_set_index);
                                  operation = 'assign';
                                   varIndex = k;
                            end
                     end
                end
            end
       end
        % ------------------- if statment ---------------------
        % if we find 'sinon' don't excute its code and jump to 'finsi'.
       if(strcmp(tokens{j} ,'sinon'))
             for ii = i:length(r) 
                   if(strcmp(r{ii} ,'finsi'))
                        i = ii ;
                        break;
                   end
             end
       end
       % si statement
       if(strcmp(tokens{j} ,'si'))
            
            to_assign = '';
            for aterms = j+1 : length(tokens)
                a_n_term = tokens{aterms};
                for k =1:(varNum - 1) 
                     if(strcmp(a_n_term, ws{k, 2}))
                        a_n_term = num2str(ws{k, 3});
                     end
                end
              to_assign = strcat(to_assign , a_n_term);
            end
            
           op_result = eval(to_assign);
           if(op_result == 1)
               
           else
               for ii = i:length(r) 
                    if(strcmp(r{ii} ,'finsi') || strcmp(r{ii} ,'sinon'))
                        i = ii;
                        break;
                    end
               end
           end
           continue;
       end
       % ------------------- while loop ---------------------
       if(strcmp(tokens{j} ,'fintantque'))
           ii = i;
           found_tq = false;
           while(ii > 1)
               if(length(r{ii}) > 7 && strcmp(r{ii}(1:7) ,'tantque'))
                   i = ii - 1;
                   found_tq = true;
                   break;
               end
                ii = ii - 1;
           end
           if(found_tq)
               continue;
           end
       end
        if(strcmp(tokens{j} ,'tantque'))
             to_assign = '';
            for aterms = j+1 : length(tokens)
                a_n_term = tokens{aterms};
                for k =1:(varNum - 1) 
                     if(strcmp(a_n_term, ws{k, 2}))
                        a_n_term = num2str(ws{k, 3});
                     end
                end
              to_assign = strcat(to_assign , a_n_term);
            end
           op_result = eval(to_assign);
           if(op_result == 1)
               
           else
               for ii = i:length(r) 
                    if(strcmp(r{ii} ,'fintantque'))
                        i = ii;
                        break;
                    end
               end
           end
        end
        % ------------------- for loop ---------------------
        if(strcmp(tokens{j} ,'finpour'))
           ii = i;
           found_pour = false;
           while(ii > 1)
               if(length(r{ii}) > 7 && strcmp(r{ii}(1:4) ,'pour'))
                   i = ii - 1;
                   found_pour = true;
                  
                   break;
               end
                ii = ii - 1;
           end
           if(found_pour)
               loop_for_first_back = true;
               continue;
           end
        end
        if(strcmp(tokens{j} ,'pour'))
            % get the variable we will be working with (usually called i)
            forvar = tokens{j + 1};
            forvarindx = -1;
            for k =1:(varNum - 1) 
                 if(strcmp(forvar, ws{k, 2}))
                     if(~strcmp(ws{k, 1}, 'entier'))
                           writefunc(app, ['Erreur en ligne ', num2str(i), ' : pour variable doit etre un entier!']);
                            workspace_vars = ws;
                            return;
                     else
                         forvarindx = k;
                     end
                 end
            end
            % Do the loop
            to_assign = '';
            for aterms = j+2 : length(tokens)
                a_n_term = tokens{aterms};
                for k =1:(varNum - 1) 
                     if(strcmp(a_n_term, ws{k, 2}))
                        a_n_term = num2str(ws{k, 3});
                     end
                end
              to_assign = strcat(to_assign , a_n_term);
            end
           op_result = eval(to_assign);
           if(op_result == 1 )
               if(loop_for_first_back)
                ws{forvarindx, 3} =  ws{forvarindx, 3} + 1;
                loop_for_first_back = false;
               end
           else
               for ii = i:length(r) 
                    if(strcmp(r{ii} ,'finpour'))
                        i = ii;
                        loop_for_first_back = false;
                        break;
                    end
               end
           end

        end
         % ------------------- END for loop ---------------------
    end
    end
    i = i + 1;
end
workspace_vars = ws;

%{ 
function writefunc(app, msgk)
    disp(msgk);
end
%}
  
% this function replaces any variable with its value for 'eval' to excute
% correctly then eval the statment and get the final result
function op_result = GetResult(ws, j, tokens, is_vec)
    to_assign_op = '';
    op_inside_str = false;
    %for aterms_op = j+1 : length(tokens)
   aterms_op = j+1 ;
   
   aterms_start = false;
    while(aterms_op <= length(tokens))
        a_n_term_op = tokens{aterms_op};
        
        if(is_vec && aterms_start == false)
            if(strcmp(a_n_term_op, '='))
                aterms_start = true;
                aterms_op = aterms_op + 1;
                continue;
            else
                aterms_op = aterms_op + 1;
                continue;
            end
        end
        
        if(strcmp(a_n_term_op, "'") || strcmp(a_n_term_op, '"'))
            op_inside_str = ~op_inside_str;
        end       

        if(varNum > 2 && op_inside_str == false)
        for k_op =1:(varNum - 1) 
            if(strcmp(a_n_term_op, ws{k_op, 2}))
                switch(ws{k_op, 1})
                    case 'entier'
                        a_n_term_op = num2str(ws{k_op, 3});
                    case 'booleen'
                         a_n_term_op = num2str(ws{k_op, 3});
                    case 'chain'
                        %a_n_term = ws{k, 3};
                        a_n_term_op = strcat(strcat("'", ws{k_op, 3}), "'");
                    case 'vecteur'
                        v_indx = '';
                        skiped_tokens_count = 0;
                        for vdx = aterms_op+1 : length(tokens)
                            skiped_tokens_count = skiped_tokens_count + 1;
                             if(strcmp(tokens{vdx}, ']'))                              
                                    break;
                             end
                             v_indx = strcat(v_indx , tokens{vdx});
                        end
                        aterms_op = aterms_op + skiped_tokens_count;
                        %a_n_term_op = op_result(v_indx);
                        r_indx = GetResult(ws, 1, SplitTokens(v_indx), false);

                        the_vec = ws{k_op, 3};
                         % add 1 because in algolab vector first index is 0
                        a_vec_value = the_vec(r_indx + 1);
                        if ~isnumeric(a_vec_value)
                             a_n_term_op = strcat(strcat("'", a_vec_value), "'");
                        else
                            a_n_term_op = num2str(a_vec_value);
                        end
                        
                       
                end
                
            end
        end
        end
         to_assign_op = strcat(to_assign_op , a_n_term_op);
         aterms_op = aterms_op + 1;
    end
  %disp('to_assign_op')
 % disp(to_assign_op)
    op_result = eval(to_assign_op);
end

function tkns = SplitTokens(code_line)
    pattern = '(\w+)|(\W)';
    tokens1 = regexp(code_line, pattern, 'match');
    
    qq = 1;
    for q=1:length(tokens1)
        if(~startsWith(tokens1{q}, ' '))
            a_tokens{qq} = tokens1{q};
            qq = qq + 1;
        end
    end
    tkns = a_tokens;
end

end