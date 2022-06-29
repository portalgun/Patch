classdef ptchs_plot < handle & ptch_link
methods
    function plot(obj,varargin)
        if ~obj.bPTB
            obj.ptch.plot(varargin{:});
        end
    end
    function [X,Y]=hist_src_bin(obj,bLog)
        e=Hist.edges2ctrs(obj.edges.bin);
        counts=sum(obj.counts.bin,[2,3]);
        edges=obj.edges.bin;


        %figure(1)
        h=histogram('BinEdges',edges,'BinCounts',counts);
        %set(gca,'xscale','log')


        ctrs=Hist.edges2ctrs(edges);
        x=ctrs;
        y=h.Values;
        if nargin < 1
            h=plot(x,y,'k','LineWidth',2);
            % TODO CHECK IF LOG
            set(gca,'xscale','log');
            Fig.format('Bins','Count','Patch selection by bins');
        else
            X=x;
            Y=y;
        end
    end
    function [X,Y]=hist_src_smp(obj,bLog)
        e=Hist.edges2ctrs(obj.edges.smp);
        counts=sum(obj.counts.smp,[2,3]);
        edges=obj.edges.smp;

        if length(edges) == length(counts)
            edges=[edges inf];
        end
        %figure(1)
        h=histogram('BinEdges',edges,'BinCounts',counts);
        %set(gca,'xscale','log')

        ctrs=Hist.edges2ctrs(edges);
        x=ctrs;
        y=h.Values;
        if nargin < 1
            h=plot(ctrs,y,'k','LineWidth',2);
            % TODO CHECK IF LOG
            set(gca,'xscale','log');
            Fig.format('Bins','Count','Patch selection by bins');
        else
            X=x;
            Y=y;
        end
    end
    function [Counts,Ctrs,edges,x,y]= hist_bins(obj)
        vals=obj.idx.val;
        edges=obj.edges.smp;
        edgesRC=Hist.edges2RC(edges);

        if nargout > 0
            [Counts,Ctrs,x,y]=Hist.RC(vals,edgesRC);
        else
            Hist.RC(vals,edgesRC);
        end


        % TODO CHECK IF LOG
        %ylim([0 max(counts)*1.05]);
        %xlim(Num.minMax(x).*[.95 1.10]);
    end
    function [Counts,Ctrs,edges,x,y]=hist_blk(obj)

        %bins=unique(obj.blkBins)+1; % NOTE PLUS 1 BECAUSE ADDED ZERO?
        %plot(Xs(bins),Ys(bins),'xb','LineWidth',3);
        bins=unique(obj.blkBins); % NOTE PLUS 1 BECAUSE ADDED ZERO?

        vals=obj.idx.val(unique(obj.Blk.blk('P').ret()));

        edges=[obj.edges.smp(bins); obj.edges.smp(bins+1)]';

        if nargout > 0
            [Counts,Ctrs,x,y]=Hist.RC(vals,edges);
        else
            Hist.RC(vals,edges);
        end

    end
    function hist(obj)
        [Xb,Yb]=obj.hist_src_bin();
        [~,~,~,Xs,Ys]=obj.hist_bins();
        if obj.bBlk
            [~,~,~,Xe,Ye]=obj.hist_blk;
        end
        Yz=Yb(:);
        mini=min(Yz(Yz>0));

%% 1
        clf;
        subPlot([1 2],1,1);
        hold on

        Y(Yz==0)=mini;
        plot(Xb,Yb,'k','LineWidth',2);

        X=Xs(:);
        Y=Ys(:);
        Y(Y==0)=mini;
        patch(X,Y,'r','FaceAlpha',.5,'LineStyle','none');

        if obj.bBlk
            X=Xe(:);
            Y=Ye(:);
            Y(Y==0)=mini;
            patch(X,Y,'r','FaceAlpha',1,'LineStyle','none');
        end

        set(gca,'xscale','log');
        set(gca,'yscale','log');
        axis square;
        h=get(gca,'Children');
        legend('db','smp','exp');
        yl=ylim;
        ylim([mini yl(2)]);
        Fig.format('Bins','Count');

%% 2
        subPlot([1 2],1,2);
        set(gca,'xscale','log');
        hold on

        plot(Xb,Yb,'k','LineWidth',2);

        yyaxis('right');

        patch(Xs,Ys,'r','FaceAlpha',.5,'LineStyle','none');

        if obj.bBlk
            patch(Xe(:),Ye(:),'r','FaceAlpha',1,'LineStyle','none');
        end

        ax=gca;
        set(ax,'xscale','log');
        h=get(ax,'Children');
        legend('db','smp','exp');
        Fig.format('Bins');
        ax.YAxis(2).Color = 'r';

    end
    function hist_img_counts(obj)
        IEdges=0:(max(obj.idx.I)+1);
        h=histogram(obj.idx.I,IEdges);
        bins=h.BinEdges(1:end);
        vals=[h.Values 0];

        subPlot([1 2],1,1);
        plot(bins,vals,'k','LineWidth',2);
        Fig.format('Image No.','Count');
        axis square;

        subPlot([1 2],1,2);
        plot(bins,sort(vals),'k','LineWidth',2);
        Fig.format('Image No. Sorted','Count');
        axis square;

        sgtitle('Patch selection by source image','FontSize',25);
    end
    function hist_img_bins(obj)
        IEdges=0:(max(obj.idx.I)+1);
        BEdges=0:(max(obj.idx.B)+1);
        h=histogram2(obj.idx.B,obj.idx.I,BEdges,IEdges);
        imagesc(transpose(h.Values));
        colorbar;
        colormap(hot);
        Fig.format('Bins','Image No.','Patch selection distribution');
        axis image;
        set(gca,'YDir','normal');
    end
%% MONTAGE
    function [Bad]=montage_bins_blk(obj,nPerImg,bSave,dire,opts,bPlot)
        md=1;


        if ~exist('bPlot','var') || isempty(bPlot)
            bPlot=1;
        end
        lookup=obj.Blk.lookup;
        blk=obj.Blk.blk;

        IDX=blk('P').ret();
        cndInd=blk('cndInd').ret();
        modeInd=blk('mode').ret();

        BINS=lookup.lvl('bins').ret;
        STD=lookup.lvl('stdInd').ret;
        LVLS=lookup.cnd('lvlInd').ret();
        CND=lookup.cnd('cndInd').ret();

        bins=unique(BINS);


        if ~exist('nPerImg','var') || isempty(nPerImg)
            nPerImg=100;
        end
        if ~exist('bSave','var') || isempty(bSave)
            bSave=0;
        end
        if ~exist('dire','var') || isempty(dire)
            dire='';
        elseif ~endsWith(dire,filesep)
            dire=[dire filesep];
        end
        if ~exist('opts','var') || isempty(opts)
            opts=struct();
        end

        clims=[0 1];
        opts.subjInfo=SubjInfo.get_default();

        rng(2);
        Bad=[];
        for i = 1:length(bins)
            if bPlot
                h=figure(1);
                set(h, 'Renderer', 'painters');
                set(h, 'RendererMode', 'manual');
                set(h, 'GraphicsSmoothing', false);
            end


            B=bins(i);
            ind=ismember(cndInd,CND(ismember(LVLS,STD(BINS==B)))) & ismember(modeInd,md);
            assignin('base','out',blk(find(ind)));
            if bPlot
                idx=unique(IDX(ind));
            else
                idx=IDX(ind);
            end
            n=numel(idx);

            Nimg=ceil(n/nPerImg);
            N=nPerImg*3;
            nCol=sqrt(N);
            nRows=floor(N/nCol);
            nCol=ceil(N/nRows/3);

            for j = 1:ceil(Nimg)
                if j == ceil(n/nPerImg)
                    inds=idx(1+nPerImg*(j-1):end);
                else
                    inds=idx((1:nPerImg)+nPerImg*(j-1));
                end
                [P,bad]=obj.load_patches_for_montage(inds,1,0,opts);
                Bad=[Bad; bad];

                if bPlot
                    sz=size(P{1});
                    montage(P,'DisplayRange',clims,'Size',[nRows nCol],'ThumbnailSize',sz);
                    Axis.match_res(2);
                    Axis.set_border_prcnt(0.05);
                    saveas(h,[dire 'bin' num2str(i) '_' num2str(j) ],'epsc');
                end
            end
        end
    end
    function montage_bins(obj,bins,n,nPerImg,bSave,dire)
        if (~exist('bins','var') || isempty(bins)) && obj.bBlk
            bins=unique(obj.blkBins(~isnan(obj.blkBins)));
        elseif (~exist('bins','var') || isempty(bins))
            bins=unique(obj.idx.B);
        end
        bAll=0;
        if ~exist('n','var') || isempty(n)
            n=[];
            bAll=1;
        end
        if ~exist('nPerImg','var') || isempty(nPerImg)
            nPerImg=100;
        end
        if ~exist('bSave','var') || isempty(bSave)
            bSave=0;
        end
        if ~exist('dire','var') || isempty(dire)
            dire='';
        elseif ~endsWith(dire,filesep)
            dire=[dire filesep];
        end


        N=n/nPerImg*3;
        nCol=sqrt(N);
        nRows=floor(N/nCol);
        nCol=ceil(n/nRows);
        clims=[0 1];
        rng(2);
        opts=struct();
        opts.subjInfo=SubjInfo.get_default();

        for i = 1:length(bins)
            h=figure(1);
            set(h, 'Renderer', 'painters');
            set(h, 'RendererMode', 'manual');
            set(h, 'GraphicsSmoothing', false);
            if obj.bBlk;
                bInd=(obj.blkBins==bins(i));
                idx=find(bInd);
            else
                idx=find(obj.idx.B==bins(i));
            end

            if bAll
                n=length(idx);
            end
            INDS=idx(randperm(length(idx),n));
            for j = 1:ceil(n/nPerImg)
                if j == ceil(n/nPerImg)
                    inds=INDS(1+nPerImg*(j-1):end);
                else
                    inds=INDS((1:nPerImg)+nPerImg*(j-1));
                end
                P=obj.load_patches_for_montage(inds,1,0,opts);

                sz=size(P{1});
                montage(P,'DisplayRange',clims,'Size',[nRows nCol],'ThumbnailSize',sz);
                Axis.match_res(2);
                Axis.set_border_prcnt(0.05);
                saveas(h,[dire 'bin' num2str(i) '_' num2str(j) ],'epsc');
            end
        end
    end
    function montage(obj,inds,nRows)
        if ~exist('nRows','var')
            nRows=10;
        end

        if ~exist('inds','var') || isempty(inds)
            inds=idx(randperm(length(obj.fnames),nRows));
        end
        clims=[];
        P=obj.load_patches_as_4Darray(inds);

        if ~exist('nRows','var') || isempty(nRows)
                nRows = ceil(sqrt(size(P,4)));
        end
        montage(P.^.4,'DisplayRange','Size',[nRows NaN]);
    end
end
end

%load('/Volumes/Data/.daveDB/ptch/LRSI/pch/a8a3837c874442e61e3d901561ea9f01/_P_.mat')
