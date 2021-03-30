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
    function montage_bins(obj,bins,n,bSave,dire)
        if (~exist('bins','var') || isempty(bins)) && obj.bBlk
            bins=unique(obj.blkBins(~isnan(obj.blkBins)));
        elseif (~exist('bins','var') || isempty(bins))
            bins=unique(obj.idx.B);
        end
        if ~exist('n','var') || isempty(n)
            n=100;
        end
        if ~exist('bSave','var') || isempty(bSave)
            bSave=0;
        end
        if ~exist('dire','var') || isempty(dire)
            dire='';
        elseif ~endsWith(dire,filesep)
            dire=[dire filesep];
        end
        N=n*3;
        nCol=sqrt(N);
        nRows=floor(N/nCol);
        nCol=ceil(n/nRows);
        clims=[0 1];
        %nCol=nan;
        %inds=zeros(nRows,nCol);
        %inds=ones(nRows,nCol).*0.4;
        rng(2);
        %iptsetpref('ImshowBorder','tight');
        %iptsetpref('ImBorder','tight');
        %iptsetpref('ImShowInitialMagnification','fit');
        %iptsetpref('ImtoolInitialMagnification','fit');
        %set(0, 'DefaultFigureRenderer', 'painters');
        for i = 1:length(bins)
            %h=figure('name',['bin ' num2str(i)],'Toolbar','none','Menubar','none');
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
            %c=i+2*(i-1);
            %inds(:,i)=idx(randperm(length(idx),nRows));

            inds=idx(randperm(length(idx),n));
            P=obj.load_patches_for_montage(inds);
            %P=obj.load_patches_as_3Darray(inds);


            %imshow(P);
            %imshow(P);
            %formatImage();

            %caxis(clims);


            %subPlot([1,nCol],1,i);
            sz=size(P{1});
            %axis image off;
            montage(P,'DisplayRange',clims,'Size',[nRows nCol],'ThumbnailSize',sz);
            %title(['bin ' num2str(bins(i)) ]);
            Axis.match_res(2);
            Axis.set_border_prcnt(0.05);
            saveas(h,[dire 'bin' num2str(i) ],'epsc');
        end
        %inds=transpose(inds);
        %P=obj.load_patches_for_montage(inds,1,1);
        %montage(P,'DisplayRange',clims,'Size',[nRows nCol],'ThumbnailSize',sz);
        %formatImage();
        %setRes(h);

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
