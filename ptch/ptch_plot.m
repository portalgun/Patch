classdef ptch_plot < handle
methods
    function [sp]=plot(obj,sp,clim,pos)
        if ~exist('clim','var')
            clim=[];
        end

        % SP
        bSP=exist('sp','var') && ~isempty(sp);
        if  ~bSP
            sp=obj.get_sp(clim);
        elseif ~isempty(clim) && sp.nRows==2
            sp=obj.get_sp(clim);
            %pos=get(gcf,'Position');
            %sp.position=pos;
        elseif exist('pos','var') && ~isempty(pos)
            sp.position=pos;
        else
            pos=get(gcf,'Position');
            sp.position=pos;
        end
        R=sp.nRows;
        C=sp.nCols;

        % NAMES
        names=cell(R,1);
        names{1}='pht';
        if ismember('xyz',obj.mapNames)
            names{2}='xyz';
        end
        if R==3
            names{end+1}='xyz';
        end

        % FLD
        if obj.bDSP || isempty(obj.PszRCbuff)
            PctrRC=obj.PctrCPs;
            fld='maps';
        else
            PctrRC=obj.PszRCbuff/2;
            fld='mapsbuff';
        end

        bIm=~isempty(obj.im);
        s=1+bIm;
        e=R+bIm;

        % PLOT IM
        hold off
        if bIm
            obj.faux_gamma_correct();
            sp.select(1,1);
            plot_fun( obj.im.img{1},fld,PctrRC,obj.PszRC);
            sp.select(1,2);
            plot_fun(obj.im.img{2},fld,PctrRC,obj.PszRC);
            sp.select(1,3);
            plot_fun(obj.im.img{1},fld,PctrRC,obj.PszRC);
            obj.faux_gamma_uncorrect();
            hold on
        end

        % PLOT MAPS
        for r = s:R
        for c = 1:C
            name=names{r-bIm};
            sp.select(r,c);
            if c==3;
                k=1;
            else
                k=c;
            end

            im=obj.(fld).(name){k};
            if strcmp(name,'pht')
                im=im.^.4;
            elseif strcmp(name,'xyz')
                im=im(:,:,3);
            end

            plot_fun(im,fld,PctrRC,obj.PszRC);

            if c==1
                cax=caxis();
            else
                caxis(cax);
            end
        end
        end
        sp.finalize();
        function plot_fun(im,fld,PctrRC,PszRC)

            hold off
            imagesc(real(im)); hold on;
            if strcmp(fld,'mapsbuff')
                plotRectOnIm(PctrRC,PszRC(1),PszRC(2),'r',1);
            end
        end
    end
    function sp=get_sp(obj,clim)
        bIm=~isempty(obj.im);
        bXyz=ismember('xyz',obj.mapNames);
        bClim=~isempty(clim) & bXyz;

        R=1+bXyz+bClim+bIm;
        C=1+2*min([obj.bStereo,1]);
        RC=[R C];

        % Row TITLE
        rtitl=cell(1+bXyz+bClim,1);
        rtitl{1}='pht';
        if bXyz
            rtitl{2}='xyz';
        end
        if bClim
            rtitl{3}='xyzAbs';
        end
        if bIm
            rtitl=['im'; rtitl];
        end

        % Col TITLE
        ctitl={'L','R','L'};

        Opts=struct();
        Opts.xticks='';
        Opts.yticks='';
        Opts.xtickLabels='';
        Opts.ytickLabels='';
        Opts.bImg=1;
        sp=subPlots(RC,[],[],obj.get_sgtitle(),rtitl,ctitl,Opts);
    end
end
methods(Access=protected)

    function obj=plot_map(obj,mapName)
        if ~exist('bNotitle','var') || isempty(bNoTitle)
            bNoTitle=0;
        end
        map=obj.select_map(mapName);
        imagesc(map);
        formatImage();
        formatFigure(mapName);
        obj.apply_title();
    end
    function plot_map_in_context(obj,mapName)
        % XXX
    end
    function titl=get_sgtitle(obj)
        if obj.bDSP
            str='Dsp';
            pszRC=obj.PszC;
        else
            str='Pch';
            pszRC=obj.PszRCbuff;
        end
        k=obj.srcInfo.K;
        pszstr=[' [' strrep(num2strSane(pszRC),',' ,', ') '] ' ];
        pstr=[' [' strrep(num2strSane(obj.srcInfo.PctrRC{k}),',' ,', ') '] ' ];
        titl=[str ' ' num2str(obj.srcInfo.P) ' ' pszstr newline ...
                  num2str(obj.srcInfo.I) obj.LR(k) pstr    '   '...
                  'Bin ' num2str(obj.srcInfo.B) '.' num2str(obj.srcInfo.S) newline ...
             ];
    end
end
end
