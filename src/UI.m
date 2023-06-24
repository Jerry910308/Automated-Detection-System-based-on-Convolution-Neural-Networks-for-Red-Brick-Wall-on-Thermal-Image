classdef UI0622_by1013v2_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        Save_REAL    matlab.ui.control.Button
        Save_FLIR    matlab.ui.control.Button
        Message      matlab.ui.control.Label
        Label_REAL   matlab.ui.control.Label
        Label_FLIR   matlab.ui.control.Label
        Select_REAL  matlab.ui.control.Button
        Image_REAL   matlab.ui.control.Image
        Start        matlab.ui.control.Button
        Select_FLIR  matlab.ui.control.Button
        Image_FLIR   matlab.ui.control.Image
        Label        matlab.ui.control.Label
        Label_2      matlab.ui.control.Label
    end

    properties (Access = private)
        orignImage_REAL % Description
        orignImage_FLIR
        netwallIR = coder.loadDeepLearningNetwork('name.mat','-mat');
        netwaterIR = coder.loadDeepLearningNetwork('name.mat','-mat');
        realexist = 0
        saveImage_REAL 
        saveImage_FLIR
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Select_FLIR
        function SelectFLIR(app, event)
            [FileName,PathName] = uigetfile({'*.jpg; *.png; *.JPG; *.jpeg; *.JPEG;'},'Select an image');
            try
                app.orignImage_FLIR=imread(strcat(PathName,FileName));
                app.orignImage_FLIR = imresize(app.orignImage_FLIR,[705 940]);
                Vmessage = "熱影像讀取成功。";
                app.Message.Text = Vmessage;
                                
                app.Image_FLIR.ImageSource = app.orignImage_FLIR;
                
                app.Start.Enable = 'on';
                app.Save_FLIR.Enable = 'off';
            catch
                
                app.Message.Text = {'熱影像讀取失敗。','請確保圖片是可用。'};
            end
        end

        % Button pushed function: Select_REAL
        function SelectREAL(app, event)
             [FileName,PathName] = uigetfile({'*.jpg; *.png; *.JPG; *.jpeg; *.JPEG;'},'Select an image');
            try
                app.orignImage_REAL=imread(strcat(PathName,FileName));
                
                Vmessage = "實際圖讀取成功。";
                app.Message.Text = Vmessage;
                app.Image_REAL.ImageSource = app.orignImage_REAL;

                app.realexist = 1;
                app.Save_REAL.Enable = 'off';
                
            catch
                
                app.Message.Text = {'實際圖讀取失敗。','請確保圖片是可用。'};

            end           
        end

        % Button pushed function: Start
        function StartAI(app, event)
            width=size(app.orignImage_FLIR,2); 
            length=size(app.orignImage_FLIR,1);
            w =width-235;
            x=floor(w/47);
            l =length-235;
            y=floor(l/47);

            redwallcount = 0;
            targetcount = 0;
            z = zeros(length,width,'uint8');
            mainmap = z;
            wallmap = z;
            
            for Inx = 1:(x-1)
                for Iny = 1:(y-1)
                    imgIR = imcrop(app.orignImage_FLIR,[(Iny*47),(Inx*47),235,235]);
                    imgIR = imresize(imgIR, [227 227]);
                    imgWall = imcrop(app.orignImage_FLIR,[(Iny*47),(Inx*47),235,235]);
                    imgWall = imresize(imgWall, [227 227]);
                    [YPred,~] = classify(app.netwallIR,imgWall);
                    if YPred == "紅牆"
                        redwallcount = redwallcount +1 ;
                        wallmap((Iny*47+1):(Iny*47+235),(Inx*47+1):(Inx*47+235),:) = 1 ;
                        [YPred,~] = classify(app.netwaterIR,imgIR);
                        if YPred == "unusual"
                            targetcount = targetcount +1 ;
                            mainmap((Iny*47+1):(Iny*47+235),(Inx*47+1):(Inx*47+235),:) = 1 ;
                        end
                    end    
                end
            end
            
            SE=strel('square',8);
            BW=imerode(mainmap,SE);
            BW2 = mainmap - BW ;
            newpic = app.orignImage_FLIR;
            newpic(:,:,1) = newpic(:,:,1) + BW2*255;
            newpic(:,:,2) = newpic(:,:,2) + BW2*255;
            newpic(:,:,3) = newpic(:,:,3) + BW2*255;

            redwallrate = (redwallcount/(x-1)/(y-1));
            rate = floor(sum(mainmap) /sum(wallmap)*100);
            
            if redwallrate < 0.2
                Vmessage = "紅牆面積不足！";
                app.Message.Text = Vmessage;
            else
                if targetcount < 1
                    Vmessage = "檢測完成，未檢測出病徵。";
                    app.Message.Text = Vmessage;
                else
                    if app.realexist == 1
                        rz = app.orignImage_REAL;
                        rz(:,:,1) = rz(:,:,1) + BW2*255;
                        rz(:,:,2) = rz(:,:,2) + BW2*255;
                        rz(:,:,3) = rz(:,:,3) + BW2*255;
                        app.Image_REAL.ImageSource = rz;
                        app.realexist = 0;
                        app.Save_REAL.Enable = 'on';
                        app.saveImage_REAL = rz;

                    else
                        app.realexist = 0;
                        app.Save_REAL.Enable = 'off';
                    end
                    app.Image_FLIR.ImageSource = newpic;
                    app.Start.Enable = 'off';
                    app.Save_FLIR.Enable = 'on';
                    app.saveImage_FLIR = newpic;

                    
                    Vmessage = strcat('約有',num2str(rate),'%的紅牆滲水');
                    app.Message.Text = {'檢測完成',Vmessage};
                end
            end
        end

        % Button pushed function: Save_FLIR
        function Save_FLIRfile(app, event)
            [ffilename, fpathname, ffileindex]=uiputfile({'*.jpg'; '*.png';},'图片保存為');

            if ffilename==0
                Vmessage = "儲存失敗。";
                app.Message.Text = Vmessage;
            else
                switch ffileindex
                    case 1
                        imwrite(app.saveImage_FLIR, [fpathname, ffilename], 'jpg');
                    case 2
                        imwrite(app.saveImage_FLIR, [fpathname, ffilename], 'png');
                end
                Vmessage = "儲存成功。";
                app.Message.Text = Vmessage;
            end
        end

        % Button pushed function: Save_REAL
        function Save_REALfile(app, event)
            [rfilename, rpathname, rfileindex]=uiputfile({'*.jpg'; '*.png';},'图片保存為');

            if rfilename==0
                Vmessage = "儲存失敗。";
                app.Message.Text = Vmessage;
            else
                switch rfileindex
                    case 1
                        imwrite(app.saveImage_REAL, [rpathname, rfilename], 'jpg');
                    case 2
                        imwrite(app.saveImage_REAL, [rpathname, rfilename], 'png');
                end
                Vmessage = "儲存成功。";
                app.Message.Text = Vmessage;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9608 0.9608 0.9608];
            app.UIFigure.Position = [100 100 880 520];
            app.UIFigure.Name = '紅牆病徵檢測';

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Label_2.Position = [621 291 260 230];
            app.Label_2.Text = '';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.BackgroundColor = [0.8 0.8 0.8];
            app.Label.Position = [2 1 619 520];
            app.Label.Text = '';

            % Create Image_FLIR
            app.Image_FLIR = uiimage(app.UIFigure);
            app.Image_FLIR.BackgroundColor = [1 1 1];
            app.Image_FLIR.Position = [12 61 600 450];

            % Create Select_FLIR
            app.Select_FLIR = uibutton(app.UIFigure, 'push');
            app.Select_FLIR.ButtonPushedFcn = createCallbackFcn(app, @SelectFLIR, true);
            app.Select_FLIR.FontSize = 15;
            app.Select_FLIR.Position = [265 10 100 26];
            app.Select_FLIR.Text = '選擇';

            % Create Start
            app.Start = uibutton(app.UIFigure, 'push');
            app.Start.ButtonPushedFcn = createCallbackFcn(app, @StartAI, true);
            app.Start.FontSize = 20;
            app.Start.FontWeight = 'bold';
            app.Start.Enable = 'off';
            app.Start.Position = [661 111 180 40];
            app.Start.Text = '開始';

            % Create Image_REAL
            app.Image_REAL = uiimage(app.UIFigure);
            app.Image_REAL.BackgroundColor = [1 1 1];
            app.Image_REAL.Position = [631 331 240 180];

            % Create Select_REAL
            app.Select_REAL = uibutton(app.UIFigure, 'push');
            app.Select_REAL.ButtonPushedFcn = createCallbackFcn(app, @SelectREAL, true);
            app.Select_REAL.Position = [731 299 100 22];
            app.Select_REAL.Text = '選擇';

            % Create Label_FLIR
            app.Label_FLIR = uilabel(app.UIFigure);
            app.Label_FLIR.HorizontalAlignment = 'center';
            app.Label_FLIR.FontSize = 15;
            app.Label_FLIR.FontWeight = 'bold';
            app.Label_FLIR.Position = [289 40 50 22];
            app.Label_FLIR.Text = '熱影像';

            % Create Label_REAL
            app.Label_REAL = uilabel(app.UIFigure);
            app.Label_REAL.HorizontalAlignment = 'center';
            app.Label_REAL.Position = [671 299 41 22];
            app.Label_REAL.Text = '實際圖';

            % Create Message
            app.Message = uilabel(app.UIFigure);
            app.Message.BackgroundColor = [1 1 1];
            app.Message.HorizontalAlignment = 'center';
            app.Message.FontSize = 15;
            app.Message.Position = [641 171 220 100];
            app.Message.Text = '請輸入熱影像';

            % Create Save_FLIR
            app.Save_FLIR = uibutton(app.UIFigure, 'push');
            app.Save_FLIR.ButtonPushedFcn = createCallbackFcn(app, @Save_FLIRfile, true);
            app.Save_FLIR.Enable = 'off';
            app.Save_FLIR.Position = [701 19 100 22];
            app.Save_FLIR.Text = '熱影像儲存';

            % Create Save_REAL
            app.Save_REAL = uibutton(app.UIFigure, 'push');
            app.Save_REAL.ButtonPushedFcn = createCallbackFcn(app, @Save_REALfile, true);
            app.Save_REAL.Enable = 'off';
            app.Save_REAL.Position = [701 59 100 22];
            app.Save_REAL.Text = '實際圖儲存';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = UI0622_by1013v2_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
