classdef ptch_plot < handle & ptch_link
methods
    function sp=plot(obj,varargin)
        Opts=obj.parsePlotArgs(varargin{:});
        %tiledlayout(2,2, 'Padding', 'none', 'TileSpacing', 'compact');

        % PLOT IM
        r=0;
        if Opts.bImg
            r=r+1;
            obj.faux_gamma_correct();
            obj.plot_fun('IM',obj.im.img,Opts,false,r);
            obj.faux_gamma_uncorrect();
        end
        if Opts.bPht
            r=r+1;
            im=cellfun(@(x) x.^0.4,obj.(Opts.fld).pht,'UniformOutput',false);
            obj.plot_fun('PHT',im,Opts,true,r);
        end
        if Opts.bXYZ
            r=r+1;
            if strcmp(Opts.buffORptch,'buff')
                f=['xyz' Str.Alph.upper(obj.primaryXYZ)];
            else
                f='xyz';
            end

            im=cellfun(@(x) x(:,:,3),obj.(Opts.fld).(f),'UniformOutput',false);
            obj.plot_fun('XYZ',im,Opts,true,r);
        end
        if Opts.bAnaglyph
            r=r+1;
            name='ANAG';
            obj.select(Opts,r,1);
            obj.plotXYZAnaglyph();
            if ~Opts.bSP obj.format_fun(); end
            if ~Opts.bSP; ylabel(name); end
        end
        if Opts.bSP
            Opts.sp.finalize(obj.bDSP);
        end
        if nargout > 0
            sp=Opts.sp;
        end
    end
    function plotAllXYZ(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        if k==1
            nk=2;
        else
            nk=1;
        end
        n=1+obj.bDSP;
        m=1+obj.bDSP*2;

        c=1;
        subPlot([n m],1,c);
        obj.plotXYZBuff3D(k);
        title('LRSI');
        cl=ylim;

        subPlot([n m],2,c);
        obj.plotXYZBuff(k);
        colorbar;
        caxis(cl);

        c=2;
        if ~obj.bDSP
            return
        end
        subPlot([n m],1,c);
        obj.plotXYZMap3D(k);
        title('Display');
        cl=ylim;

        subPlot([n m],2,c);
        obj.plotXYZMap(k);
        colorbar;
        caxis(cl);

        c=3;
        subPlot([n,m],1,3);
        obj.plotXYZBino();


    end
    function xyz=getAnaglyph(obj)
        phtL=real(obj.im.img{1});
        phtR=real(obj.im.img{2});
        xyz=stereoAnaglyph(phtL,phtR);
    end
    function plotXYZAnaglyph(obj)
        %phtL=obj.maps.pht{1};
        %phtR=obj.maps.pht{2};
        %imagesc(phtR)
        %dk
        xyz=obj.getAnaglyph();
        image(xyz);
        imshow(xyz);
        %image(xyz,'CDataMapping','scaled')
        %Fig.formatIm();

    end
    function plotXYZBuff3D(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        name=['xyz' Str.Alph.upper(obj.primaryXYZ)];
        xyz=obj.mapsBuff.(name){k};
        pht=obj.mapsBuff.pht{k};
        LorR=obj.srcInfo.LorR;
        ptch.plotXYZ3D_fun(xyz,pht,LorR,false,obj.PszRC);
    end
    function plotXYZBuff(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        name=['xyz' Str.Alph.upper(obj.primaryXYZ)];
        xyz=obj.mapsBuff.(name){k};
        z=xyz(:,:,3);
        imagesc(z);
        hold on;

        ctr=size(z)/2;
        crpCtr=floor(ctr + 1);
        U=crpCtr(1)+obj.PszRC(1)/2;
        B=crpCtr(1)-obj.PszRC(1)/2;
        L=crpCtr(2)+obj.PszRC(2)/2;
        R=crpCtr(2)-obj.PszRC(2)/2;

        UR=[U,R];
        UL=[U,L];
        LR=[B,R];
        LL=[B,L];
        Rec=[UR; UL; LL; LR; UR];

        Axis.formatIm();
        Axis.format();
        hold off;
    end
    function plotXYZMap(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        m=obj.maps.xyz{k}(:,:,3);
        imagesc(m);
        Axis.formatIm();
        Axis.format();
    end
    function plotXYZMap3D(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        xyz=obj.maps.xyz{k};
        pht=obj.maps.pht{k};
        LorR=obj.srcInfo.LorR;
        ptch.plotXYZ3D_fun(xyz,pht,LorR,true,obj.PszRC);
    end

end
methods(Access=protected)
    function Opts=parsePlotArgs(obj,varargin)
        P=ptch.getPlotP();
        Opts=Args.parse(struct(),P,varargin{:});
        if isempty(Opts.buffORptch) && obj.bDSP
            Opts.buffORptch='ptch';
        elseif isempty(Opts.buffORptch)
            Opts.buffORptch='buff';
        end
        if strcmp(Opts.buffORptch,'ptch') && ~isempty(obj.maps);
            Opts.bPtch=1;
        else
            Opts.bPtch=0;
        end
        if strcmp(Opts.buffORptch,'ptch') && ~obj.bDSP
            Opts.buffORptch='buff';
        end
        if strcmp(Opts.buffORptch,'ptch')
            Opts.fld='maps';
        else
            Opts.fld='mapsBuff';
        end
        if obj.bDSP
            Opts.PctrRC=obj.PctrCPs;
            Opts.PszRC=obj.PszRC;
        else
            Opts.PctrRC={obj.PszRCbuff/2; obj.PszRCbuff/2};
            Opts.PszRC=obj.PszRCbuff;
        end
        if isempty(Opts.bAnaglyph)
            Opts.bAnaglyph=false;
        end
        if isempty(Opts.bImg)
            Opts.bImg=~isempty(obj.im);
        end

        Opts.R=Opts.bImg+Opts.bXYZ+Opts.bPht+Opts.bAnaglyph;
        Opts.C=1+2*min([obj.bStereo,1]);
        RC=[Opts.R Opts.C];

        %% SP
        if ~Opts.bSP
            return
        end
        if ~isempty(Opts.sp);
            ysz=get(gca,'YLim');
            xsz=get(gca,'XLim');
            lastSz=[ysz(2)-ysz(1) xsz(2)-xsz(1)];
            Opts.bNew=(Opts.bPtch && ~isequal(lastSz,obj.PszRC)) || (~Opts.bPtch && ~isequal(lastSz,obj.PszRCbuff));
        else
            Opts.sp=obj.get_sp(RC, Opts.clim,Opts.bPtch);
            Opts.bNew=false;
        end
        if Opts.bNew && isempty(Opts.pos)
            Opts.pos=get(gcf,'Position');
        end
        if ~isempty(Opts.pos)
            Opts.sp.position=Opts.pos;
        end


    end
    function sp=get_sp(obj,RC,clim, bPtch)
        Opts=struct();

        bImg=~isempty(obj.im);
        bXyz=ismember('xyz',obj.mapNames);
        bClim=~isempty(clim) & bXyz;


        % Row TITLE
        rtitl=cell(1+bXyz+bClim,1);
        rtitl{1}='pht';
        if bXyz
            rtitl{2}='xyz';
        end
        if bClim
            rtitl{3}='xyzAbs';
        end
        if bImg
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
        Opts.rlabelLoc='left';
        %Opts.caxis;
        Opts.bImg=1;
        sp=SubPlots(RC,[],[],obj.get_sgtitle(),rtitl,ctitl,Opts);
    end
    function select(obj,Opts,r,c)
        if Opts.bSP
            Opts.sp.select(r,c);
        else
            subPlot([Opts.R Opts.C],r,c);
        end
    end
    function plot_fun(obj,name,im,Opts,bRect,r)
        for c = 1:3
            obj.plot_fun_single(name,im,Opts,bRect,r,c);
        end
    end
    function plot_fun_single(obj,name,im,Opts,bRect,r,c)
        if c==3
            k=1;
        else
            k=c;
        end
        LorR=CPs.getLorR(k);
        obj.select(Opts,r,c);
        hold off
        imagesc(real(im{k})); hold on;
        hold on;
        if bRect; obj.plot_rect(Opts,k); end
        if ~Opts.bSP
            if r==1
                title(LorR);
            end
            if c==1
                ylabel(name);
            end
            obj.format_fun();
        end
        hold off

    end
    function format_fun(obj)
        Axis.formatIm;
        ax = gca;
        outerpos = ax.OuterPosition;
        ti = ax.TightInset;
        left = outerpos(1) + ti(1);
        bottom = outerpos(2) + ti(2);
        ax_width = outerpos(3) - ti(1) - ti(3);
        ax_height = outerpos(4) - ti(2) - ti(4);
        ax.Position = [left bottom ax_width ax_height];
    end
    function plot_rect(obj,Opts,k)
        if ~strcmp(Opts.fld,'mapsBuff')
            return
        end
        Plot.rect(Opts.PctrRC{k}, Opts.PszRC(1), Opts.PszRC(2),'r',1,1);
    end

    function obj=plot_map(obj,mapName)
        if ~exist('bNotitle','var') || isempty(bNoTitle)
            bNoTitle=0;
        end
        map=obj.select_map_bi(mapName);
        imagesc(map);
        Axis.formatIm();
        Axis.format(mapName);
        obj.apply_title();
    end
    function plot_map_in_context(obj,mapName)
        % XXX
    end
    function titl=get_sgtitle(obj)
        k=obj.srcInfo.K;
        %pszstr=[' [' strrep(Num.toStr(pszRC),',' ,', ') '] ' ];
        %pstr=[' [' strrep(Num.toStr(obj.srcInfo.PctrRC{k}),',' ,', ') '] ' ];
        fname=obj.srcInfo.fname;
        if iscell(fname)
            fname=fname{1};
        end
        titl=[ num2str(obj.srcInfo.P) ': ' strrep(fname,'_','-') newline];
    end
end
methods(Static)
    function plotYXZ_fun(xyz,LorR,bZero,PszRC);
    end
    function plotXYZ3D_fun(xyz,pht,LorR,bZero,PszRC)
        x=xyz(:,:,1);
        y=xyz(:,:,2);
        z=xyz(:,:,3);
        mp=mat2gray(pht);
        h=warp(x,z,y,mp);

        set(gca, 'YDir','normal');
        ylabel('Z');
        grid on;
        ctr=size(z)/2;
        crpCtr=floor(ctr + 1);
        C=xyz(ctr(1),ctr(2),:);
        hold on

        PszRCbuff=size(xyz(:,:,1));

        % PLOT Direction
        d=min(abs(diff([xlim; zlim; ylim],[],2)))/3.*squeeze(sign(C));
        unit=abs(squeeze(C)./sqrt(sum(C.^2)));
        k=reshape(unit.*d,[1,1,3]);
        dot=C-k;
        Plot.RC3([C; dot],'r');
        nrm=squeeze(dot-C);

        % Buff CROP RECT
        UR=xyz(1,1,:);
        UL=xyz(1,end,:);
        LR=xyz(end,1,:);
        LL=xyz(end,end,:);
        RecB=[UR; UL; LL; LR; UR];
        Plot.RC3(RecB,'r');
        %sz=[diff(Num.minMax(x),[]) diff(Num.minMax(y),[])]


        % MAP CROP RECT
        if PszRC~=PszRCbuff
            U=crpCtr(1)+PszRC(1)/2;
            B=crpCtr(1)-PszRC(1)/2;
            L=crpCtr(2)+PszRC(2)/2;
            R=crpCtr(2)-PszRC(2)/2;

            UR=xyz(U,R,:);
            UL=xyz(U,L,:);
            LR=xyz(B,R,:);
            LL=xyz(B,L,:);
            Rec=[UR; UL; LL; LR; UR];
            Plot.RC3(Rec,'r','LineWidth',2);
            t=Rec-k;
            %Plot.RC3(t,'r');
        end
        %


        %p=reshape(C,1,3,1);
        %D=-p*nrm;
        %r=abs(d(1));
        %xx=linspace(p(1)-r,p(1)+r,2);
        %yy=linspace(p(2)-r,p(2)+r,2);
        %[xx,yy]=meshgrid(xx,yy);

        %z = (-nrm(1)*xx - nrm(2)*yy - D)/nrm(3);
        %rec=[xx(:) yy(:) z(:)];
        %xy=sign([xx(:) yy(:)]);
        %[~,ind]=sortrows(xy,'descend');
        %rec=rec(ind,:);
        %rec=[rec(1:2,:); rec(4,:); rec(3,:); rec(1,:)];
        %Plot.RC3(rec,'r');


        if bZero
            Zer=C;
            Zer(3)=1;
            Plot.RC3(Zer,'.b');
        end
        title(LorR);
        hold off;
        axis square;
        zd=abs(diff(xlim))/2;
        zm=nanmedian(z,'all');
        ylim([zm-zd zm+zd]);
        axis square;
        %zl=ylim;
        %zl(1)=obj.win.win.posXYZm(3);
        %ylim(zl);
        %imagesc(pht)
    end
end
methods(Static,Access=?PtchsViewer)
    function P=getPlotP()
        P={'sp',[],@(x) isempty(x) | isa(x,'SubPlots');
           'clim',[],'isnumeric_2_e';
           'pos',[],'isnumeric_4_e';
           ...
           'bImg',true,'isBinary_e';   % SHOW FPHT
           'bPht',true','isBinary_e';   % SHOW FPHT
           'bXYZ',true','isBinary_e';   % SHOW XYZ
           ...
           'bZer',false','isBinary_e';  % PATCH rect loc
           'buffORptch','','ischar_e';
           'bSP',false,'isBinary_e';   % USE SUBPLOTS aka sp
           'bAnaglyph',false,'isBinary_e';
        };
    end
end
end
