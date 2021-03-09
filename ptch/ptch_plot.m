classdef ptch_plot < handle
methods
    function [sp]=plot(obj,sp,clim,pos,buffORptch,bDC)
        if ~exist('clim','var')
            clim=[];
        end
        if ~exist('bDC','var') || isempty(bDC)
            bDC=0;
        end
        bBP=(exist('buffORptch','var') && ~isempty(buffORptch));
        if ~bBP && obj.bDSP
            buffORptch='ptch';
        elseif ~bBP
            buffORptch='buff';
        end
        if strcmp(buffORptch,'ptch') && ~isempty(obj.maps);
            bPtch=1;
        else
            bPtch=0;
        end

        % SP
        bSP=exist('sp','var') && ~isempty(sp);
        if bSP
            ysz=get(gca,'YLim');
            xsz=get(gca,'XLim');
            lastSz=[ysz(2)-ysz(1) xsz(2)-xsz(1)];
            if (bPtch && ~isequal(lastSz,obj.PszRC)) || (~bPtch && ~isequal(lastSz,obj.PszRCbuff))
                bNew=1;
            else
                bNew=0;
            end
        else
            bNew=0;
        end

        if  ~bSP
            sp=obj.get_sp(clim,bPtch,bDC);
        elseif bNew
            sp=obj.get_sp(clim,bPtch);
            if ~exist('pos','var') || isempty(pos)
                pos=get(gcf,'Position');
            end
            sp.position=pos;
        elseif ~isempty(clim) && sp.nRows==2
            sp=obj.get_sp(clim,bPtch);
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
        if bPtch
            PctrRC=obj.PctrCPs;
            fld='maps';
        elseif ~obj.bDSP
            PctrRC={obj.PszRCbuff/2; obj.PszRCbuff/2};
            fld='mapsbuff';
        elseif obj.bDSP
            PctrRC=obj.PctrCPs;
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
            plot_fun( obj.im.img{1},fld,PctrRC{1},obj.PszRC,obj.bDSP,1);

            sp.select(1,2);
            plot_fun(obj.im.img{2},fld,PctrRC{2},obj.PszRC,obj.bDSP,1);

            sp.select(1,3);
            plot_fun(obj.im.img{1},fld,PctrRC{1},obj.PszRC,obj.bDSP,1);
            obj.faux_gamma_uncorrect();

        end

        % PLOT MAPS
        for r = s:R
        for c = 1:C
            name=names{r-bIm};
            sp.select(r,c);
            if c==3; k=1; else; k=c; end

            im=obj.(fld).(name){k};
            if strcmp(name,'pht')
                im=im.^.4;
            elseif strcmp(name,'xyz')
                im=im(:,:,3);
            end


            plot_fun(im,fld,PctrRC{k},obj.PszRC,obj.bDSP, 0);

        end
        end
        sp.finalize(obj.bDSP);

        function plot_fun(im,fld,PctrRC,PszRC,bDSP,bIm)

            hold off
            imagesc(real(im)); hold on;

            if bIm & bDSP
                return
            elseif strcmp(fld,'mapsbuff') && ~bDSP
                plotRectOnIm(PctrRC,PszRC(1),PszRC(2),'r',1,1);
            elseif strcmp(fld,'mapsbuff') && bDSP
                ysz=get(gca,'YLim');
                xsz=get(gca,'XLim');
                sz=[ysz(2)-ysz(1) xsz(2)-xsz(1)];
                ctr=sz./2;
                plotRectOnIm(ctr,PszRC(1),PszRC(2),'r',1,1);
                plotRectOnIm(PctrRC,PszRC(1),PszRC(2),'y',1,1);
            end
        end
    end
    function sp=get_sp(obj,clim,bPtch,bDC)
        Opts=struct();

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

        Opts.xticks='';
        Opts.yticks='';
        Opts.xtickLabels='';
        Opts.ytickLabels='';
        Opts.xlimRCBN='R';
        Opts.ylimRCBN='R';
        Opts.climRCBN='R';
        Opts.bImg=1;
        %Opts.caxis;
        Opts.bImg=1;
        sp=subPlots(RC,[],[],obj.get_sgtitle(bPtch),rtitl,ctitl,Opts);
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
    function titl=get_sgtitle(obj,bPtch)
        if obj.bDSP & bPtch
            str='Dsp';
            pszRC=obj.PszRC;
        elseif bPtch
            str='Patch';
            pszRC=obj.PszRC;
        else
            str='PatchBuff';
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
