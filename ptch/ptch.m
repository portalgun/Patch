classdef ptch < handle  & ptch_buff &  ptch_map & ptch_map_xyz & ptch_msk &  ptch_plot & ptch_raw & ptch_src & ptch_T & ptch_tex & ptch_util & ptch_wdw & ptch_dsp
% XXX
% PARSE
%   dspthing
properties
    name % ONCE SEL
    num

    srcInfo
        %database
        % LorR
        % I
        % K
        % P set num
        % S bin-smp num
        %
        % PctrRC
        %
        % db
        % genOpts


    DispInfo % just the name
    Disp % object
    winInfo=struct()  % window on display
    win %DspDispWin % NOTE number of nests
    trgtInfo
        %trgtDsp
        %dispORwin
    trgt
    focInfo
        %dispORwin
    foc
    subjInfo=struct() % struct
        % IPDM
        % LExyz
        % RExyz


    PszRC
    PszXY

    bStereo=2 % whether to include cp in crop

    mapNames
    mskNames
    texNames

    im % main dispaly

    wdwInfo
    wdw

    map
    maps
        % xyz
        % CPs

    msk % mstrmask
    msks
    %targets %msk targets

    tex
    texs

    CPs=cell(2,1)


    % BUFF
    PctrCPs=cell(2,1)
    PszRCbuff
    CPsBuff 
    mapsbuff
    msksbuff

    bDSP=0
end
properties(Hidden=true)
    badflag=0
    src
        % xyz
        % pht
        % phtGamma
    tmp=cell(2,1)
end
properties(Constant=true,Hidden=true)
    LR='LR';
end
methods
    function obj=ptch(PszRC,PszRCbuff,srcInfo,bStereo,mapNames,mskNames,texNames,wdwInfo,src)
        if ~exist('PszRC','var')
            return
        end
        obj.PszRC=PszRC;
        obj.PszXY=fliplr(obj.PszRC);
        obj.PszRCbuff=PszRCbuff;
        if isempty(obj.PszRCbuff)
            obj.PszRCbuff=PszRC;
            bSmallOnly=1;
        else
            bSmallOnly=0;
        end
        obj.srcInfo=srcInfo;


        if exist('bStereo','var') && ~isempty(bStereo)
            obj.bStereo=bStereo;
        end

        if exist('mapNames','var') && ~isempty(mapNames)
            obj.mapNames=mapNames;
        else
            obj.mapNames={'pht','xyz'};
        end
        if exist('mskNames','var') && ~isempty(mskNames)
            obj.mskNames=mskNames;
        end
        if exist('texNames','var') && ~isempty(texNames)
            obj.texNames=texNames;
        end
        if exist('wdwInfo','var') && ~isempty(wdwInfo)
            obj.wdwInfo=wdwInfo;
        end
        if exist('src','var') && ~isempty(src)
            obj.src=src;
        end


        if isempty(obj.src)
            obj.get_map_srcs();
        end
        if (~isfield(obj.src,'XYZ') || isempty(obj.src.XYZ))
            obj.get_src_xyz();
        end

        if obj.bStereo & (~isfield(obj.src,'CPs') || isempty(obj.src.CPs))
            obj.get_raw_CPs_bi();
        end

        obj.get_buff_CPs_bi();
        if ~isempty(obj.mapNames)
            obj.get_maps(); %ptch_map, crpsrcsbi
        end
        if obj.badflag; return; end
        if ~isempty(obj.mskNames)
            obj.get_masks();
        end
        if obj.badflag; return; end
        if ~isempty(obj.texNames)
            obj.gen_tex();
        end
        if obj.badflag; return; end
        if isstruct(obj.wdwInfo)
            obj.gen_wdw();
        end
        if obj.badflag; return; end

        obj.name=obj.get_name();
        obj.num=obj.get_num();
        if bSmallOnly
            obj.CPs=obj.CPsBuff;
            obj.CPsBuff=[];

            obj.msks=obj.msksbuff;
            obj.msksbuff=[];

            obj.msks=obj.msksbuff;
            obj.msksbuff=[];

            obj.maps=obj.mapsbuff;
            obj.mapsbuff=[];
            obj.PszRCbuff=[];

        end
    end
    function obj=init_src(obj)
        obj.srcInfo.get_db();
        obj.srcInfo.get_genOpts();
    end
end
methods(Static=true)
end
end

