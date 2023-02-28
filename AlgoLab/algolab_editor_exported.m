classdef algolab_editor_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AlgoLabUIFigure                matlab.ui.Figure
        FichiersMenu                   matlab.ui.container.Menu
        OuvrirMenu                     matlab.ui.container.Menu
        SauvegarderMenu                matlab.ui.container.Menu
        SortieAltF4Menu                matlab.ui.container.Menu
        ModifierMenu                   matlab.ui.container.Menu
        ExcuterlecodeMenu              matlab.ui.container.Menu
        AiderMenu                      matlab.ui.container.Menu
        AproposdalgolabMenu            matlab.ui.container.Menu
        Toolbar                        matlab.ui.container.Toolbar
        PushTool4                      matlab.ui.container.toolbar.PushTool
        PushTool                       matlab.ui.container.toolbar.PushTool
        PushTool2                      matlab.ui.container.toolbar.PushTool
        PushTool3                      matlab.ui.container.toolbar.PushTool
        EnvoyerButton                  matlab.ui.control.Button
        EditField                      matlab.ui.control.EditField
        FichiersLabel                  matlab.ui.control.Label
        ConsoledecommandesLabel        matlab.ui.control.Label
        ListBox_2                      matlab.ui.control.ListBox
        TextArea_2                     matlab.ui.control.TextArea
        ScriptLabel                    matlab.ui.control.Label
        EspacedetravailWorkspaceLabel  matlab.ui.control.Label
        ListBox                        matlab.ui.control.ListBox
        TextArea                       matlab.ui.control.TextArea
    end

    
    properties (Access = private)
        CurrentScriptName % Description
        UserInput % Description
        Running % Description
    end
    
    methods (Access = private)
        
        function write(app, msg)
            txt = app.TextArea_2.Value;
            msgc = cellstr(msg);
            txt_new = [txt; msgc];
            app.TextArea_2.Value = txt_new; 
            scroll(app.TextArea_2, 'bottom');
        end

        function Refreshfiles(app)
            files = dir(); 
            files = files(~[files.isdir]);
            ii = 1;
            for i = 1:length(files)
                if(endsWith(files(i).name, '.alglab')) % get alolab scripts only
                    items{ii} = files(i).name;
                    ii = ii + 1;
                end
            end
             app.ListBox_2.Items = items;
             write(app, 'files refreshed');
        end
        
        function save_file(app)
            str = app.TextArea.Value;
            filename = app.ScriptLabel.Text;
            fileID = fopen(filename,'w');
            fprintf(fileID,'%s', strjoin(str, '\n'));
            fclose(fileID);
            write(app, 'Saved');
        end
        
        function load_file(app)
            filePath = uigetfile('.alglab','Select a File');
            if(filePath ~= 0)
                file_code = fileread(filePath);
                app.TextArea.Value = file_code;
                app.ScriptLabel.Text = filePath;
                write(app, [filePath ' loaded']);
                app.CurrentScriptName = filePath;
            else
              write(app, 'unable to load file.');
            end
        end


        function open_file(app, filePath)
            if(filePath ~= 0)
                file_code = fileread(filePath);
                app.TextArea.Value = file_code;
                app.ScriptLabel.Text = filePath;
                write(app, [filePath ' loaded']);
                app.CurrentScriptName = filePath;
            else
              write(app, 'unable to load file.');
            end
        end
        
        function run_algo(app)
            
            if( app.Running == true)
                return % we are already running a script
            end
            
            save_file(app); % save script

            write(app, ['>> ', app.CurrentScriptName] )
            try
                app.Running = true;
                algo_ws = AlgoInterpreter(app.CurrentScriptName , app, @write, false, @readl, @resetInput);
            catch ex
                write(app, ex.message);
                 app.Running = false;
                return
            end
            app.Running = false;
            write(app, '');
            items = {};
            
            [ws_lines,ws_colums] = size(algo_ws);
            %write(app, num2str(ws_lines));
            
            for i = 1:ws_lines-1
              vval = algo_ws{i, 3};
              if(strcmp(algo_ws{i, 1}, 'fonction'))
                continue;
              end
              if(strcmp(algo_ws{i, 1}, 'entier'))
                   vval = num2str(algo_ws{i, 3});
              end
              if(strcmp(algo_ws{i, 1}, 'booleen'))
                  vval = 'true';
                   if(algo_ws{i, 3} == 0)
                       vval = 'false';
                   end
              end
               if(strcmp(algo_ws{i, 1}, 'vecteur'))
                   m_str_array = '';
                   for idx = 1:length(vval)
                       m_str_array = [m_str_array, ',', num2str(vval(idx))];
                   end
                   vval = m_str_array;
              end
              items{i} = [algo_ws{i, 1}, ' ', algo_ws{i, 2}, ' = ', vval];
            end
             app.ListBox.Items = items;
        end

        function inpt = readl(app)
            %inpt = input('w in ');
            inpt = app.UserInput;%app.EditField.Value;
        end
        
        function resetInput(app)
            app.UserInput = '';
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            Refreshfiles(app);
            app.TextArea.focus();
            open_file(app, 'NouveauScript.alglab');
            app.UserInput = '';
        end

        % Callback function: OuvrirMenu, PushTool
        function PushToolClicked(app, event)

           load_file(app);
            
        end

        % Callback function: PushTool2, SauvegarderMenu
        function PushTool2Clicked(app, event)
           save_file(app);
            
        end

        % Callback function: PushTool4
        function PushTool4Clicked(app, event)
           Refreshfiles(app);
        end

        % Double-clicked callback: ListBox_2
        function ListBox_2DoubleClicked(app, event)
            item = event.InteractionInformation.Item;
            open_file(app, app.ListBox_2.Items{item});
        end

        % Value changing function: EditField
        function EditFieldValueChanging(app, event)
            changingValue = event.Value;
            
        end

        % Callback function: PushTool3
        function PushTool3Clicked(app, event)
            run_algo(app);
        end

        % Menu selected function: SortieAltF4Menu
        function SortieAltF4MenuSelected(app, event)
            app.delete; % quit the editor
        end

        % Menu selected function: ExcuterlecodeMenu
        function ExcuterlecodeMenuSelected(app, event)
            run_algo(app);
        end

        % Button pushed function: EnvoyerButton
        function EnvoyerButtonPushed(app, event)
            if(app.Running)
                app.UserInput = app.EditField.Value;
            end
            write(app, app.EditField.Value);
            app.EditField.Value = "";
        end

        % Menu selected function: AproposdalgolabMenu
        function AproposdalgolabMenuSelected(app, event)
            write(app, '-------------------------------------------------------------');
            write(app, "   AlgoLab est ecrit en MATLAB par Babaarbi Mohammed Ala.");
            write(app, "   github.com/RogyDev");
            write(app, '-------------------------------------------------------------');
        end

        % Value changed function: EditField
        function EditFieldValueChanged(app, event)
            
            %write(app, 'EditFieldValueChanged');
            EnvoyerButtonPushed(app, event);
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create AlgoLabUIFigure and hide until all components are created
            app.AlgoLabUIFigure = uifigure('Visible', 'off');
            app.AlgoLabUIFigure.Position = [100 100 980 558];
            app.AlgoLabUIFigure.Name = 'AlgoLab';

            % Create FichiersMenu
            app.FichiersMenu = uimenu(app.AlgoLabUIFigure);
            app.FichiersMenu.Text = 'Fichiers';

            % Create OuvrirMenu
            app.OuvrirMenu = uimenu(app.FichiersMenu);
            app.OuvrirMenu.MenuSelectedFcn = createCallbackFcn(app, @PushToolClicked, true);
            app.OuvrirMenu.Accelerator = 'o';
            app.OuvrirMenu.Text = 'Ouvrir';

            % Create SauvegarderMenu
            app.SauvegarderMenu = uimenu(app.FichiersMenu);
            app.SauvegarderMenu.MenuSelectedFcn = createCallbackFcn(app, @PushTool2Clicked, true);
            app.SauvegarderMenu.Accelerator = 's';
            app.SauvegarderMenu.Text = 'Sauvegarder';

            % Create SortieAltF4Menu
            app.SortieAltF4Menu = uimenu(app.FichiersMenu);
            app.SortieAltF4Menu.MenuSelectedFcn = createCallbackFcn(app, @SortieAltF4MenuSelected, true);
            app.SortieAltF4Menu.Text = 'Sortie (Alt+F4)';

            % Create ModifierMenu
            app.ModifierMenu = uimenu(app.AlgoLabUIFigure);
            app.ModifierMenu.Text = 'Modifier';

            % Create ExcuterlecodeMenu
            app.ExcuterlecodeMenu = uimenu(app.ModifierMenu);
            app.ExcuterlecodeMenu.MenuSelectedFcn = createCallbackFcn(app, @ExcuterlecodeMenuSelected, true);
            app.ExcuterlecodeMenu.Accelerator = 'r';
            app.ExcuterlecodeMenu.Text = 'Exécuter le code';

            % Create AiderMenu
            app.AiderMenu = uimenu(app.AlgoLabUIFigure);
            app.AiderMenu.Text = 'Aider';

            % Create AproposdalgolabMenu
            app.AproposdalgolabMenu = uimenu(app.AiderMenu);
            app.AproposdalgolabMenu.MenuSelectedFcn = createCallbackFcn(app, @AproposdalgolabMenuSelected, true);
            app.AproposdalgolabMenu.Text = 'A propos d''algolab';

            % Create Toolbar
            app.Toolbar = uitoolbar(app.AlgoLabUIFigure);

            % Create PushTool4
            app.PushTool4 = uipushtool(app.Toolbar);
            app.PushTool4.Tooltip = {'Rafraîchir fichiers'};
            app.PushTool4.ClickedCallback = createCallbackFcn(app, @PushTool4Clicked, true);
            app.PushTool4.Icon = fullfile(pathToMLAPP, 'refresh-page-option.png');

            % Create PushTool
            app.PushTool = uipushtool(app.Toolbar);
            app.PushTool.Tooltip = {'ouverir'};
            app.PushTool.ClickedCallback = createCallbackFcn(app, @PushToolClicked, true);
            app.PushTool.Icon = 'add.png';
            app.PushTool.Separator = 'on';

            % Create PushTool2
            app.PushTool2 = uipushtool(app.Toolbar);
            app.PushTool2.Tooltip = {'Sauvegarder'};
            app.PushTool2.ClickedCallback = createCallbackFcn(app, @PushTool2Clicked, true);
            app.PushTool2.Icon = 'diskette.png';
            app.PushTool2.Separator = 'on';

            % Create PushTool3
            app.PushTool3 = uipushtool(app.Toolbar);
            app.PushTool3.Tooltip = {'Exécuter le code'};
            app.PushTool3.ClickedCallback = createCallbackFcn(app, @PushTool3Clicked, true);
            app.PushTool3.Icon = 'play-button-arrowhead.png';
            app.PushTool3.Separator = 'on';

            % Create TextArea
            app.TextArea = uitextarea(app.AlgoLabUIFigure);
            app.TextArea.FontName = 'Consolas';
            app.TextArea.FontSize = 14;
            app.TextArea.Position = [176 220 783 317];
            app.TextArea.Value = {'Algorithme'; ''; 'Variables'; ''; 'Debut'; '   '; 'Fin'};

            % Create ListBox
            app.ListBox = uilistbox(app.AlgoLabUIFigure);
            app.ListBox.Items = {};
            app.ListBox.Position = [14 27 149 173];
            app.ListBox.Value = {};

            % Create EspacedetravailWorkspaceLabel
            app.EspacedetravailWorkspaceLabel = uilabel(app.AlgoLabUIFigure);
            app.EspacedetravailWorkspaceLabel.Position = [15 199 162 22];
            app.EspacedetravailWorkspaceLabel.Text = 'Espace de travail(Workspace)';

            % Create ScriptLabel
            app.ScriptLabel = uilabel(app.AlgoLabUIFigure);
            app.ScriptLabel.Position = [176 537 593 22];
            app.ScriptLabel.Text = 'Script';

            % Create TextArea_2
            app.TextArea_2 = uitextarea(app.AlgoLabUIFigure);
            app.TextArea_2.FontName = 'Consolas';
            app.TextArea_2.FontSize = 14;
            app.TextArea_2.Position = [176 48 782 152];
            app.TextArea_2.Value = {'AlgoLab console'};

            % Create ListBox_2
            app.ListBox_2 = uilistbox(app.AlgoLabUIFigure);
            app.ListBox_2.Items = {'file1', 'file2', 'file3', 'file4'};
            app.ListBox_2.DoubleClickedFcn = createCallbackFcn(app, @ListBox_2DoubleClicked, true);
            app.ListBox_2.Position = [15 221 149 317];
            app.ListBox_2.Value = 'file1';

            % Create ConsoledecommandesLabel
            app.ConsoledecommandesLabel = uilabel(app.AlgoLabUIFigure);
            app.ConsoledecommandesLabel.Position = [185 199 134 23];
            app.ConsoledecommandesLabel.Text = 'Console de commandes';

            % Create FichiersLabel
            app.FichiersLabel = uilabel(app.AlgoLabUIFigure);
            app.FichiersLabel.Position = [14 536 47 22];
            app.FichiersLabel.Text = 'Fichiers';

            % Create EditField
            app.EditField = uieditfield(app.AlgoLabUIFigure, 'text');
            app.EditField.ValueChangedFcn = createCallbackFcn(app, @EditFieldValueChanged, true);
            app.EditField.ValueChangingFcn = createCallbackFcn(app, @EditFieldValueChanging, true);
            app.EditField.Placeholder = 'Commande';
            app.EditField.Position = [176 27 699 22];

            % Create EnvoyerButton
            app.EnvoyerButton = uibutton(app.AlgoLabUIFigure, 'push');
            app.EnvoyerButton.ButtonPushedFcn = createCallbackFcn(app, @EnvoyerButtonPushed, true);
            app.EnvoyerButton.Position = [874 27 84 24];
            app.EnvoyerButton.Text = 'Envoyer';

            % Show the figure after all components are created
            app.AlgoLabUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = algolab_editor_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AlgoLabUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AlgoLabUIFigure)
        end
    end
end