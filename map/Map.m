classdef Map < handle & stim
%TODO reall GAMMA
%TODO DOWNSAMPLE
% XXX interpolate between pixels
properties
    %PszXY
    %PszRC
    img=cell(1,2)
    LorR
    index

    W=cell(1,2)
    winTex=cell(1,2)
    imgOrig=cell(1,2)
    IbOld

    %RMS
    %DC

    figNum
    fig
    partition %normalizing factor

    bUpdated
    bAutoUpdate=1
    dnk=1
    bAuotUpdate=1
    bContrastFixed=0
    bLuminanceFixed=0
    bWindowed=0
    bNormalized=0
    bCropped=0
    bContrastImg=0
    bEdge=0
    bGamma=0
    monoORbino='bino' %whether to compute stats as single image or independently
    %    Opts.contrast
    %      bByImage %0
    %      monoORbino
    %      DCfix    % .4
    %      RMSfix   %.14
    %      W
    %      nChnl %1

    rmsFix
    dcFix
    dnkFix
    winOpts
end
properties(Hidden=true)

    rmsOld
    dcOld
end
methods
    function obj=Map(Limg,Rimg,LorR,WL,WR,index,winTexL,winTexR)
        if isa(Limg,'ptch')
            obj=init_from_ptch(Limg);
            return
        end

        if exist('Limg','var')
            obj.img{1}=Limg;
            obj.PszXY=size(obj.img{1});
            obj.PszRC=fliplr(obj.PszXY);
        end
        if exist('Rimg','var')
            obj.img{2}=Rimg;
            obj.PszXY=size(obj.img{2});
            obj.PszRC=fliplr(obj.PszXY);
        end
        if exist('LorR','var')
            obj.LorR=LorR;
        end
        obj=obj.init_window;
        if exist('WL','var')
            obj.W{1}=WL;
        else
            obj.W{1}=ones(size(obj.img{2}));
        end
        if exist('WR','var')
            obj.W{2}=WR;
        else
            obj.W{2}=ones(size(obj.img{1}));
        end
        if exist('winTexL','var')
            obj.winTex{1}=winTexL;
        else
            obj.winTex{1}=ones(size(obj.img{1}));
        end
        if exist('winTexR','var')
            obj.winTex{2}=winTexR;
        else
            obj.winTex{2}=ones(size(obj.img{1}));
        end

        if exist('index','var')
            obj.index=index;
        end
        if ~isempty(obj.img{1}) && ~isempty(obj.img{2}) && ~isa(obj,'msk')
            obj=obj.update;
        end
    end
    function obj=init2(obj)
        obj.fix_contrast_bi(obj.rmsFix, obj.dcFix);
        % TODO DNK
        % TODO wdw? obj.
    end
%% FROM PTCH
    % XXX
%% CONVERSION
    function [Limg, Rimg]=split_fun(obj,img)
        Limg=img(:,1:obj.PszRC(1));
        Rimg=img(:,obj.PszRC(1)+1:end);
    end
    function name=name_fun(obj)
        switch class(obj)
            case 'lum'
                name='Luminance';
            case 'edg'
                name='Edge';
            case 'cntrst'
                name='Contrast';
            case 'rnge'
                name='Range';
            otherwise
                name=[];
        end
    end
%% NORMALIZE
    function [obj]=normalize(obj)
        if obj.bWindowed
            indL=logical(obj.W{1});
            indR=logical(obj.W{2});
        else
            indL=logical(ones(size(obj.img{1})));
            indR=logical(ones(size(obj.img{2})));
        end
        if isempty(obj.img{2})
            tmp=obj.img{1};
            tmp(~indL)=nan;
            obj.partition=sqrt(nansum(tmp(:).^2));
            obj.img{1}=obj.img{1}/obj.partition;
        elseif isequal(obj.monoORbino,'mono')
            Ltmp=obj.img{1};
            Rtmp=obj.img{2};
            Ltmp(~indL)=nan;
            Rtmp(~indR)=nan;
            obj.partition(1)=sqrt(nansum(Ltmp(:).^2));
            obj.partition(2)=sqrt(nansum(Rtmp(:).^2));
            obj.img{1}=obj.img{1}/obj.partition(1);
            obj.img{2}=obj.img{2}/obj.partition(2);
        elseif isequal(obj.monoORbino,'bino')
            Ltmp=obj.img{1};
            Rtmp=obj.img{2};
            Ltmp(~indL)=nan;
            Rtmp(~indR)=nan;
            tmp=[Ltmp Rtmp];
            obj.partition=sqrt(nansum(tmp(:).^2));
            img=[obj.img{1} obj.img{2}]/obj.partition;
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end
        obj.bNormalized=1;
        if obj.bAutoUpdate
            obj=obj.update;
        end
    end
%% CONTRAST
    function obj=contrast(obj)
        if isempty(obj.img{2})
            [obj.img{1},Ib]=obj.contrast_helper(obj.img{1});
        elseif strcmp(obj.monoORbino,'mono')
            [obj.img{1},Ib(1)]=obj.contrast_helper(obj.img{1});
            [obj.img{2},Ib(2)]=obj.contrast_helper(obj.img{2});
        elseif strcmp(obj.monoORbino,'bino')
            [img,Ib]=obj.contrast_helper([obj.img{1} obj.img{2}]);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end
        obj.IbOld=Ib;
        obj.bContrastImg=1;
    end
    function [img,Ib]=contrast_helper(obj,img)
        null(obj);
        Ib=mean(mean(img));
        img=(img-Ib)/Ib;
    end
    function obj=uncontrast(obj)
        if strcmp(obj.monoORbino,'mono');
            obj.Limg=obj.uncontrast_helper(obj.Limg);
            obj.Rimg=obj.uncontrast_helper(obj.Rimg);
        else strcmp(obj.monoORbino,'bino');
            img=obj.uncontrast_helper([obj.Limg obj.Rimg]);
            [obj.Limg,obj.Rimg]=obj.split_fun(img);
        end
        obj.bContrastImg=0;
    end
    function img=uncontrast_helper(obj,img)
        img=img*obj.IbOld+obj.IbOld;
    end
    function obj=unfix_contrast(obj)
        if isequal(obj.monoORbino,'mono')
            error('not implemented')
        end
        obj.fix_contrast_bi(obj.rmsOld{1},[]);
        obj.bContrastFixed=0;
    end
    function obj=unfix_dc(obj)
        if isequal(obj.monoORbino,'mono')
            error('not implemented')
        end
        obj.fix_contrast_bi([],obj.dcOld{1});
        obj.bLuminanceFixed=0;
    end
    function obj=fix_contrast_bi(obj,RMSfix,DCfix,nChnl,monoORbino)
        if ~exist('monoORbino','var')
            monoORbino=obj.monoORbino;
        end
        if ~obj.bContrastFixed
            bSaveOldRms=1;
        else
            bSaveOldRms=0;
        end
        if ~obj.bLuminanceFixed
            bSaveOldDC=1;
        else
            bSaveOldDC=0;
        end
        if (exist('RMSfix','var') && ~isempty(RMSfix))
            obj.bContrastFixed=1;
        end
        if  ~exist('RMSfix','var')
            RMSfix=[];
        end
        if (exist('DCfix','var') && ~isempty(DCfix)) || obj.bLuminanceFixed
            obj.bLuminanceFixed=1;
        end
        if ~exist('DCfix','var')
            DCfix=[];
        end
        if isempty(RMSfix) && isempty(DCfix)
            return
        end

        if ~exist('nChnl','var')
            nChnl=1;
        end
        dcOld=cell(1,2);
        rmsOld=cell(1,2);
        if isempty(obj.img{2})
            [obj.img{1},rmsOld{1},dcOld{2}]=Map.fix_contrast(obj.img{1},RMSfix,obj.W{1},DCfix,nChnl);
        elseif isequal(monoORbino,'mono')

            [obj.img{1},rmsOld{1},dcOld{1}]=Map.fix_contrast(obj.img{1},RMSfix,obj.W{1},DCfix,nChnl);
            [obj.img{2},rmsOld{2},dcOld{2}]=Map.fix_contrast(obj.img{2},RMSfix,obj.W{2},DCfix,nChnl);
        elseif isequal(monoORbino,'bino')
            [img,rmsOld{1},dcOld{1}]=Map.fix_contrast([obj.img{1} obj.img{2}],RMSfix,[obj.W{1} obj.W{2}],DCfix,nChnl);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end
        if obj.bAutoUpdate
            obj=obj.update;
        end
        if bSaveOldRms
            obj.rmsOld=rmsOld;
        end
        if bSaveOldDC
            obj.dcOld=dcOld;
        end
    end
%% WINDOWW
    function obj=init_window(obj)
        if isempty(obj.W{1})
            obj.W{1}=ones(size(obj.img{2}));
        end
        if isempty(obj.W{2})
            obj.W{2}=ones(size(obj.img{1}));
        end
    end
    function obj=window(obj)
        if isempty(obj.W{1}) && isempty(obj.W{2})
            error('No window not defined');
        end

        % TODO
        if obj.bContrastImg
            cntr=obj.contrast;
            cntr=cntr.window_helper;
            obj=cntr.uncontrast;
        end
        obj=obj.update;
    end
    function obj=window_helper(obj)
        % TODO
        W=lum(obj.winTex{1},obj.winTex{2});
        W=W.contrast;
        obj.imgOrig{1}=obj.img{1};
        obj.imgOrig{2}=obj.img{2};
        obj.img{1}=obj.img{1}.*obj.W{1}+(~obj.W{1}.*W.Limg);
        obj.img{2}=obj.img{2}.*obj.W{2}+(~obj.W{2}.*W.Rimg);
        obj.bWindowed=1;
    end
    function obj=window_selector(obj,windowType,varargin)
        % TODO
        switch windowType
        case 'cos'
            obj.cos_window(varargin{:});
        end
    end
    function obj=cos_window(obj,WszRCT,dskDmRCT,rmpDmRCT)
        % TODO
        if numel(WszRCT) == 3
        elseif numel(WszRCT) == 2
            obj.W{1}=cosWindowXY(fliplr(WszRCT),fliplr(dskDmRCT),fliplr(rmpDmRCT),1);
            obj.W{2}=cosWindowXY(fliplr(WszRCT),fliplr(dskDmRCT),fliplr(rmpDmRCT),1);
        end
    end
    function obj=unwindow(obj)
        if obj.bWindowed==0
            return
        end
        obj.img{1}=obj.imgOrig{1};
        obj.img{2}=obj.imgOrig{2};
        obj.imgOrig{1}=[];
        obj.imgOrig{2}=[];
        obj.bWindowed=0;
    end
%% AVERAGE
    function obj=average_vert(obj)
        obj.img{1}=repmat(mean(obj.img{1},1),size(obj.img{1},1),1);
        obj.img{2}=repmat(mean(obj.img{2},1),size(obj.img{2},1),1);
        obj=obj.update;
    end
    function obj=average_hori(obj)
        obj.img{1}=repmat(mean(obj.img{1},1),size(obj.img{1},1),1);
        obj.img{2}=repmat(mean(obj.img{2},1),size(obj.img{2},1),1);
    end
    function obj=flatten_depth(obj)
    end
%% CROP
    function obj=crop(PctrRC,PszXY)
        obj.img{1}=cropImgCtrIntrp(obj.img{1},PctrRC,PszXY);
        obj.img{2}=cropImgCtrIntrp(obj.img{2},PctrRC,PszXY);
        obj.bCropped=1;
        obj.PszRC=size(obj.img{1});
        obj.PszXY=fliplr(obj.PszRC);
    end
    function crop_fun(obj,img)
    end
%% EDGE
    function obj = get_edge_strength(obj,tapNum,direction,order)
        if obj.bEdge
            return
        end
        if ~obj.bContrastImg
            obj.contrast;
        end
        if ~obj.bNormalized
            obj.norm;
        end
        if ~exist('tapNum','var')
            tapNum=5;
        end
        if ~exist('direction','var')
            direction='h';
        end
        if ~exist('order','var')
            order=1;
        end
        obj.img{1}=IderivTap(obj.img{1},tapNum,order,direction);
        obj.img{2}=IderivTap(obj.img{2},tapNum,order,direction);
        obj.bEdge=1;
        if obj.bAutoUpdate
            obj.update();
        end
    end
    function obj = get_transition_region(obj,width)
        obj.img{1}=logicalExtremeEdge(obj.img{1},'R',0);
        obj.img{2}=logicalExtremeEdge(obj.img{2},'L',0);

        obj.img{1}=logicalOutline(obj.img{1},width,0);
        obj.img{2}=logicalOutline(obj.img{2},width,0);
    end
%% GAMMA
    function obj=gamma_correct_bi(obj)
        if obj.bGamma
            return
        end
        if isempty(obj.img{2})
            obj.img{1}=Map.gamma_correct(obj.img{1});
        elseif strcmp(obj.monoORbino,'mono')
            obj.img{1}=Map.gamma_correct(obj.img{1});
            obj.img{2}=Map.gamma_correct(obj.img{2});
        elseif strcmp(obj.monoORbino,'bino')
            img=Map.gamma_correct([obj.img{1} obj.img{2}]);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end
        obj.bGamma=1;
    end
    function obj=gamma_uncorrect_bi(obj)
        if ~obj.bGamma
            return
        end
        if isempty(obj.img{2})
            obj.img{1}=Map.gamma_uncorrect(obj.img{1});
        elseif strcmp(obj.monoORbino,'mono')
            obj.img{1}=Map.gamma_uncorrect(obj.img{1});
            obj.img{2}=Map.gamma_uncorrect(obj.img{2});
        elseif strcmp(obj.monoORbino,'bino')
            img=Map.gamma_uncorrect([obj.img{1} obj.img{2}]);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end

        obj.bGamma=0;
    end
    function obj=faux_gamma_correct_bi(obj)
        if obj.bGamma
            return
        end
        if isempty(obj.img{2})
            obj.img{1}=Map.faux_gamma_correct(obj.img{1});
        elseif strcmp(obj.monoORbino,'mono')
            obj.img{1}=Map.faux_gamma_correct(obj.img{1});
            obj.img{2}=Map.faux_gamma_correct(obj.img{2});
        elseif strcmp(obj.monoORbino,'bino')
            img=Map.faux_gamma_correct([obj.img{1} obj.img{2}]);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end
        obj.bGamma=1;
    end
    function obj=faux_gamma_uncorrect_bi(obj)
        if ~obj.bGamma
            return
        end
        if isempty(obj.img{2})
            obj.img{1}=Map.faux_gamma_uncorrect(obj.img{1});
        elseif strcmp(obj.monoORbino,'mono')
            obj.img{1}=Map.faux_gamma_uncorrect(obj.img{1});
            obj.img{2}=Map.faux_gamma_uncorrect(obj.img{2});
        elseif strcmp(obj.monoORbino,'bino')
            img=Map.faux_gamma_uncorrect([obj.img{1} obj.img{2}]);
            [obj.img{1},obj.img{2}]=obj.split_fun(img);
        end

        obj.bGamma=0;
    end
%% PROPS
    function obj=update(obj)
        obj.init_window;
        [obj.RMS,obj.DC]=obj.rms;
    end
    % RMS & DC
    function [RMS,DC]=rms(obj)
        if isempty(obj.img{2})
            [RMS,DC]=obj.rms_helper(obj.img{1},obj.W{1});
        elseif strcmp(obj.monoORbino,'mono')
            [RMS(1),DC(1)]=obj.rms_helper(obj.img{1},obj.W{1});
            [RMS(2),DC(2)]=obj.rms_helper(obj.img{2},obj.W{2});
        elseif strcmp(obj.monoORbino,'bino')
            [RMS,DC]=obj.rms_helper([obj.img{1},obj.img{2}],[obj.W{1} obj.W{2}]);
        end
    end
    function [RMS,DC]=rms_helper(obj,img,W)
        if obj.bContrastImg
            [RMS,DC]=Map.rmsDeviation(img,W,obj.bWindowed);
        else
            [RMS,DC]=rmsContrast(img,W,obj.bWindowed);
        end
    end
%% PLOT
    function obj=plot(obj)
        if isempty(obj.figNum)
            obj.figNum=nFn;
        end
        obj.update();
        obj.fig=figure(obj.figNum);
        imagesc([obj.img{1} obj.img{2}]);
        formatFigure(['RMS ' sprintf('%3.4f',obj.RMS) newline 'DC ' sprintf('%3.4f',obj.DC) ],'',obj.title_fun);
        formatImage;
        if obj.bEdge
            obj.fig.Colormap=hot;
        end
    end
    function obj= plot_contrast(obj)
        obj=obj.contrast;
        obj.plot;
    end
    function titl=title_fun(obj)
        name=obj.name_fun;
        if exist('name','var')
            titl=[name ' Image,'];
        else
            titl=[];
        end
        if ~isempty(obj.index)
            titl=[titl ' ' num2str(obj.index)];
        end
        if ~isempty(obj.LorR)
            titl=[titl ' ' obj.LorR ' Anchor'];
        end
    end
end
methods(Static=true)
%% CROP
    function m=crop_f(im,PctrRC,PszRC,interpType)
        if ~exist('interpType','var')  || isempty(interpType)
            interpType='linear';
        end
        PszXY=fliplr(PszRC);

        switch interpType
        case 'none'
            m = Map.cropImgCtr(im,round(PctrRC),PszXY,1:size(im,3));
            return
        end
        m= Map.crop_interp(im,PctrRC,PszXY,interpType);
    end

    function m=crop_interp(Im,PctrRC,PszXY,interpType)
        BszXY   = PszXY + [1+ceil(abs(rem(PctrRC(2),1)))  2 ];
        [XbffPix,YbffPix]=meshgrid(1:BszXY(1),1:BszXY(2));

        crp=Map.cropImgCtr(Im, fix(PctrRC),BszXY);
        intrp=interp2m( crp, XbffPix+rem(PctrRC(2),1), YbffPix, interpType);
        m=Map.cropImgCtr(intrp,[],PszXY);
    end

    function crp=cropImgCtr(Im,PctrRC,PszXY,indChnl)
        if ~exist('PctrRC','var') || isempty(PctrRC)
            PctrRC(1) = floor((size(Im,1))/2 + 1);
            PctrRC(2) = floor((size(Im,2))/2 + 1);
        end

        if ~exist('indChnl','var') || isempty(indChnl)
            indChnl = 1:size(Im,3);
        end
        crp = Map.cropImg(Im, Map.ctr2crd(PctrRC,PszXY),PszXY,indChnl);
    end
    function crp=cropImg(Im,PcrdRC,PszXY,indChnl)
        crp = Im(PcrdRC(1):(PcrdRC(1)+PszXY(2)-1), ...
                PcrdRC(2):(PcrdRC(2)+PszXY(1)-1), ...
                indChnl,:);
    end
    function intrp=interpfun(V,Xq,Yq,interpType)
        % TODO
        for d = 1:size(V,3)
            Vq(:,:,d) = interp2(V(:,:,d),Xq,Yq,interpType);
        end
    end
    function PcrdRC=ctr2crd(PctrRC,PszXY)
        PcrdRC = bsxfun(@minus,PctrRC,floor(fliplr(PszXY)./2));
    end
%% CONTRAST
    function [IccdRMS,kRMS,DC]=fix_contrast(img,RMSfix,W,DCfix,nChnl)
        DC=sum(img(:).*W(:))./sum(W(:));
        Iweb     = (img-DC)./DC;
        %kRMS     = Map.rmsDeviation(Iweb,W,0);
        kRMS = sqrt(sum( (Iweb(:).^2).*W(:))./sum(W(:)));

        if ~exist('DCfix','var') || isempty(DCfix)
            DCfix   = DC;
        end
        if ~exist('RMSfix','var') || isempty(RMSfix)
            RMSfix=kRMS;
        end

        IccdRMS  = (DCfix.*(RMSfix.*Iweb./kRMS) + DCfix);
    end
    function [RMS,DC] = rmsDeviation(Izro,W,bPreWndw)
        % AVG LUMINANCE UNDER WINDOW
        if bPreWndw == 0
            DC   = sum(Izro(:).*W(:))./sum(W(:));
            % ZERO MEAN IMAGE
            Idev = Izro - DC;
            % RMS DEVIATION COMPUTED FROM MEAN-ZERO IMAGE
            RMS  = sqrt( sum( W(:).*( Idev(:) ).^2 )./sum(W(:)) );
        elseif bPreWndw == 1
            [RMS,DC] = rmsDeviationPreWindowed(Izro,W);
        end
    end
    function [Iweb,DC] = contrastImageVec(I,W,bPreWndw)
        % function [Iweb,DC] = contrastImageVec(I,W,bPreWndw)
        %
        %   example calls: Iweb =    contrastImageVec(I)
        %                  Iweb =    contrastImageVec(I,W)
        %                  Iweb = W.*contrastImageVec(I,W)
        %
        % matrix of weber contrast images in column vector form
        % from matrix of intensity images in column vector form
        %
        % I:         matrix of images in column vector form      [ Nd x nStm ]
        % W:         window under which to compute contrast      [ Nd x  1   ]
        % bPreWndw:  boolean indicating whether images have been pre-windowed
        %            1 -> images have     been pre-windowed
        %            0 -> images have NOT been pre-windwoed
        %%%%%%%%%%%%
        % Iweb:      weber contrast image                        [ Nd x nStm ]
        % DC:        mean of image                               [ 1  x nStm ]

        % INPUT HANDLING
        if ~exist('W','var')        || isempty(W)
           W = ones(size(I,1),1);
        end
        if ~exist('bPreWndw','var') || isempty(bPreWndw)
           bPreWndw = 0;
        end

        tol = 0.2; % MINIMUNM MEAN THAT DOES NOT THROW AN ERROR
        if sum(mean(I) < tol),         disp( ['contrastImageVec: WARNING! mean luminance is less than ' num2str(tol) ' in ' num2str(sum(mean(I) < tol)) ' images... Enter a luminance image']);   end
        if size(W,2) ~= 1,             error(['contrastImageVec: WARNING! window is not in column vector form: size(W)=[' num2str(size(W,1)) ' ' num2str(size(W,2)) ']']);   end
        if size(W,1) ~= size(I,1),     error(['contrastImageVec: WARNING! window size [' num2str(size(W,1)) ' ' num2str(size(W,2)) '] does not match image size [' num2str(size(I,1)) ' ' num2str(size(I,2)) ']']); end
        if sum(W(:)>1) > 1
            error(['contrastImageVec: WARNING! check input W. Values greater than 1.0: max(W(:))=' num2str(max(W(:)))]);
        end


        if bPreWndw == 0 % UNWINDOWED
            % MEAN: EASY TO READ (DC = sum(I(:).*W(:))./sum(W(:))
            DC   = bsxfun(@rdivide,sum(bsxfun(@times,I    ,W) ),sum(W));
            % CONTRAST IMAGE
            Iweb  = bsxfun(@rdivide,    bsxfun(@minus,I    ,DC),DC   );
        elseif bPreWndw == 1 % PREWINDOWED
            % NON-ZERO INDICES
            indGd = W(:)>0;
            % MEAN OF PREWINDOWED IMAGE
            DC   = mean(I,1);
            % CONTRAST IMAGE
            Iweb  = bsxfun(@rdivide,    bsxfun(@minus,I    ,DC) ,DC   );
        end
    end
    function im=gamma_correct(im)
        error('not implemented');
    end
    function im=gamma_uncorrect(im)
        error('not implemented');
    end
    function im=faux_gamma_correct(im)
        im=im.^.4;
    end
    function im=faux_gamma_uncorrect(im)
        im=im.^2.5;
    end
end
end
