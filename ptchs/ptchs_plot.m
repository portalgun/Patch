classdef ptchs_plot < handle
methods
    function hist_bins(obj)
        BEdges=0:(max(obj.idx.B)+1);
        h=histogram(obj.idx.B,BEdges);
        bins=h.BinEdges(1:end);
        plot(bins,[h.Values 0],'k','LineWidth',2);
        formatFigure('Bins','Count','Patch selection by bins');
    end
    function hist_img(obj)
        IEdges=0:(max(obj.idx.I)+1);
        h=histogram(obj.idx.I,IEdges);
        bins=h.BinEdges(1:end);
        vals=[h.Values 0];

        subPlot([1 2],1,1);
        plot(bins,vals,'k','LineWidth',2);
        formatFigure('Image No.','Count');
        axis square;

        subPlot([1 2],1,2);
        plot(bins,sort(vals),'k','LineWidth',2);
        formatFigure('Image No. Sorted','Count');
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
        formatFigure('Bins','Image No.','Patch selection distribution');
        axis image;
        set(gca,'YDir','normal');
    end
    function montage_bins(obj,bins,nRows)
        if (~exist('bins','var') || isempty(bins)) && obj.bBlk
            bins=unique(obj.blkBins(~isnan(obj.blkBins)));
        elseif (~exist('bins','var') || isempty(bins))
            bins=unique(obj.idx.B);
        end
        if ~exist('nRows','var')
            nRows=15;
        end
        clims=[];
        nCol=numel(bins);
        %nCol=nan;
        inds=zeros(nRows,nCol);
        rng(1);
        for i = 1:length(bins)
            if obj.bBlk;
                idx=find( obj.idx.B==bins(i) & ismember(obj.idx.P,obj.Blk.blk('P').ret()));
            else
                idx=find(obj.idx.B==bins(i));
            end
            %inds(i,:)=idx(randperm(length(idx),nRows));
            inds(:,i)=idx(randperm(length(idx),nRows));
        end
        inds=transpose(inds);
        P=obj.load_patches_as_4Darray(inds);
        montage(P,'DisplayRange',clims,'Size',[nRows nCol]);
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
        %montage(P,'DisplayRange','Size',[nRows NaN]);
    end
end
end

%load('/Volumes/Data/.daveDB/ptch/LRSI/pch/a8a3837c874442e61e3d901561ea9f01/_P_.mat')
