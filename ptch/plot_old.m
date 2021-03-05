
    function [sg,pos]=plot(obj,sg,pos,clim)
        if ~exist('sg','var')
            sg=[];
        end
        if ~exist('clim','var')
            clim=[];
        end
        if obj.bDSP
            sg=obj.plot_dsp(sg,clim);
        else
            sg=obj.plot_pch(sg,clim);
        end
        if ~exist('pos','var') || isempty(pos)
            pos(1)=0;
            pos(2)=0;
            pos(3)=238;
            pos(4)=375;
        else
            POS=get(gcf, 'Position');
            pos=[POS(1:2) pos(3:4)];
        end
        set(gcf,'Position', pos);
    end
    function sg=plot_pch_old(obj,sg,clim)
        if ~exist('sg','var')
            sg=[];
        end
        pht=obj.mapsbuff.pht;
        xyz=obj.mapsbuff.xyz;
        R=2;
        if exist('clim','var') && ~isempty(clim)
            R=3;
        end
        C=1;
        obj.plot_fun(pht,'pht',R,C,1,1);
        obj.plot_fun(xyz,'xyz',R,C,2,1);
        if R==3
            obj.plot_fun(xyz,'xyz',R,C,3,1, clim);
        end
        if isempty(sg)
            sg=sgtitle(obj.get_sgtitle);
        else
            sg.String=obj.get_sgtitle;
        end
    end

    function plot_fun_old(obj,src,name,R,C,r,c, clim)
        C=C*(obj.bStereo+1);
        cstart=c;
        bClim=0;
        if exist('clim','var') && ~isempty(clim)
            bClim=1;
        end
        for k = 1:(obj.bStereo+1)
            % IM
            im=src{k};
            if iscell(im)
                im=im{k};
            end
            if strcmp(name,'pht')
                im=im.^.4;
            elseif strcmp(name,'xyz')
                im=im(:,:,3);
            end

            %titl
            titl='';
            if k==1 && bClim
                titl='xyzAbs';
            elseif k==1
                titl=name;
            elseif k==2 && bClim
                titl=num2strSane(clim,3,1,1);
            else
                titl='';
            end

            if obj.bStereo; m=2; else m=1; end

            c=cstart+(cstart-1)*obj.bStereo+(k-1);

            subPlot([R C],r,c);

            imagesc(im);
            formatImage();
            formatFigure('','',titl);
            if exist('clim','var') && ~isempty(clim)
                caxis(clim);
            end
        end
    end

    function obj=plot_all(obj,bNested)
        if obj.bDSP
            obj.plot_dsp_all();
        else
            obj.plot_pch_all();
        end
    end

    function sg=plot_pch_all(obj)
        R=max([numel(obj.mapNames), numel(obj.mskNames), numel(obj.texNames)]);
        obj.plot_fun_all('mapsbuff',R,3);
        obj.plot_fun_all('msksbuff',R,3);
        obj.plot_fun_all('texs',R,3);
        sg=sgtitle(obj.get_sgtitle);
    end
    function plot_fun_all(obj,fld,R,C, clim)
        N=~isempty(obj.texNames)+~isempty(obj.mapNames)+~isempty(obj.texNames);
        if startsWith(fld,'map')
            c=1;
            names='mapNames';
        elseif startsWith(fld,'msk')
            c=2;
            names='mskNames';
        elseif startsWith(fld,'tex')
            c=3;
            names='texNames';
        end
        c=min([c N]);
        C=min([C N]);

        n=length(obj.(names));
        for r = 1:n
            name=obj.(names){r};
            src=obj.(fld).(name);
            obj.plot_fun(src,name,R,C,r,c);
        end
    end
    function plot_fun(obj,src,name,R,C,r,c, clim)
        C=C*(obj.bStereo+1);
        cstart=c;
        bClim=0;
        if exist('clim','var') && ~isempty(clim)
            bClim=1;
        end
        for k = 1:(obj.bStereo+1)
            % IM
            im=src{k};
            if iscell(im)
                im=im{k};
            end
            if strcmp(name,'pht')
                im=im.^.4;
            elseif strcmp(name,'xyz')
                im=im(:,:,3);
            end

            %titl
            titl='';
            if k==1 && bClim
                titl='xyzAbs';
            elseif k==1
                titl=name;
            elseif k==2 && bClim
                titl=num2strSane(clim,3,1,1);
            else
                titl='';
            end

            if obj.bStereo; m=2; else m=1; end

            c=cstart+(cstart-1)*obj.bStereo+(k-1);

            subPlot([R C],r,c);

            imagesc(im);
            formatImage();
            formatFigure('','',titl);
            if exist('clim','var') && ~isempty(clim)
                caxis(clim);
            end
        end
    end
    function obj=plot_3D(obj)
        % XXX
    end
