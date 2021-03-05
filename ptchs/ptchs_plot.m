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
end
end
