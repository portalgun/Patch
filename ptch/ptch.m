classdef ptch < handle  & ptch_map &  ptch_plot & ptch_src & ptch_util & ptch_dsp & ptch_xyzD & ptch_xyzT & ptch_dspRMS & ptch_buff & ptch_link
% XXX
% PARSE
%   dspthing
properties
    name % ONCE SEL
    num
    dire
end
properties(Dependent)
    PszXY
    PszRC
    PszRCbuff
    PszXYbuff
end
properties
    mapNames=cell(0,1)
    mskNames=cell(0,1)
    texNames=cell(0,1)

    maps=struct
    msks=struct
    texs=struct

    mapsBuff=struct % xyz, CPs
    msksBuff=struct %targets %msk targets
    msksBuffT=struct

    CPs=cell(2,1)
    CPsBuff=cell(2,1)
    CPsBuffT=cell(2,1)

    DispInfo % just the name
    winInfo% window on display
    trgtInfo %trgtDsp %dispORwin %
    focInfo %dispORwin
    subjInfo=struct() % struct % IPDM % LExyz % RExyz
    wdwInfo

    % BUFF
    PctrCPs=cell(2,1)

    bStereo=2 % whether to include cp in crop
    bDSP=0
    flatAnchor=''
end
properties(SetAccess=?ptch_link)
    im % main dispaly
    tex
    msk % mstrmask
    map
    win %DspDispWin % NOTE number of nests
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
end
properties(Access=?ptch_link)
    PszRCm
    PszRCbuffm
end
properties(SetAccess={?ptch_link,?ptchs,?ptchsInfo,?ptchInfo}, Hidden=true)
    Disp % object
    imList=cell(1,2)
    bFlat=false
    bZeroed=false


    % XYZ
    primaryXYZ
    bXYZSource=false
    bXYZDisplay=false
    bXYZTransform=false
        bCenter=false
        bScale=false
        bSheer=false
        bCorrectCtrXYZ=false
        shrinkTo=''

    WszRCPixOffset=0

    % PHT
    primaryPht=''
    bPhtTransform=false
    bPhtSource=false

    cropRule='med'
    cropInterpType='linear'
    msksOld
    mapsOld
    msksBuffOld
    mapsBuffOld
    trgtDspOld


    statFncName=''
    Stats=cell(0,0)

    bnewplotflag=true
    badflag=false
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
    function obj=ptch(varargin)
        if nargin < 1
            return
        end
        if  length(varargin)==1 && isstruct(varargin{1})
            obj.parse_struct(varargin{1});
        elseif Args.isPairs(varargin)
            obj.parse_struct(struct(varargin{:}));
        else
            obj.parse(varargin{:});
        end
        if isempty(obj.PszRCbuff)
            obj.PszRCbuff=obj.PszRC;
        end
        if isa(obj.srcInfo,'srcInfo') || isstruct(obj.srcInfo);
            obj.parse_src();
        end
        %obj.init_disp();
    end
    function obj=parse_struct(obj,S)
        objs={'win','trgt','foc','subjInfo'};
        p3D={'win','foc','trgt'};
        flds=fieldnames(S);
        for i = 1:length(flds)
            fld=flds{i};

            bA=iscell(S.(fld));
            bMap=bA && numel(S.(fld))==2 && isnumeric(S.(fld){1});
            bMaps=bA && iscell(S.(fld){1});

            if ismember(fld,objs) && ~isa(S.(fld),fld);
                if ~isstruct(obj.([fld 'Info']))
                    obj.([fld 'Info'])=struct();
                end
                obj.([fld 'Info'])=S.(fld);
            elseif bMap
                if isemember(fld,{'maps','map'})
                    obj.maps=[obj.maps; S.(fld)];
                elseif isemember(fld,{'msks','msk'})
                    obj.msks=[obj.msks; S.(fld)];
                elseif isemember(fld,{'texs','tex'})
                    obj.texs=[obj.texs; S.(fld)];
                end
                if isemember(fld,{'maps','map'})
                    obj.maps=[obj.maps; S.(fld)];
                elseif isemember(fld,{'msks','msk'})
                    obj.msks=[obj.msks; S.(fld)];
                elseif isemember(fld,{'texs','tex'})
                    obj.texs=[obj.texs; S.(fld)];
                end
            elseif bMaps
                if isemember(fld,{'maps','map'})
                    obj.maps=[obj.maps; S.(fld)];
                elseif isemember(fld,{'msks','msk'})
                    obj.msks=[obj.msks; S.(fld)];
                elseif isemember(fld,{'texs','tex'})
                    obj.texs=[obj.texs; S.(fld)];
                end
            elseif isprop(obj,fld)
                obj.(fld)=S.(fld);
            elseif ismember('_',fld);
                spl=strsplit(fld,'_');
                if ismember(spl{1},p3D) && Obj.isProp('Point3D',spl{2}) || strcmp(spl{2},'dispORwin')
                    if ~isstruct(obj.([spl{1} 'Info']))
                        obj.([spl{1} 'Info'])=struct();
                    end
                    obj.([spl{1} 'Info']).(spl{2})=S.(fld);
                elseif strcmp(spl{1},'trgt') && ismember(spl{2},{'trgtDsp','Dsp','dsp'})
                    if ~isstruct(obj.([spl{1} 'Info']))
                        obj.([spl{1} 'Info'])=struct();
                    end
                    obj.trgtInfo.trgtDsp=S.(fld);
                elseif strcmp(spl{1},'wdw')
                    if ~isstruct(obj.wdwInfo);
                        obj.wdwInfo=struct();
                    end
                    obj.wdwInfo.(spl{2})=struct();
                end
            end
        end
    end
    function obj=parse(obj,PszRC,PszRCbuff,srcInfo,bStereo,mapNames,mskNames,texNames,wdwInfo,src)
        % PSZ
        if ~exist('PszRC','var')
            return
        end
        obj.PszRC=PszRC;
        obj.PszXY=fliplr(obj.PszRC);
        if exist('PszRCbuff','var')
            obj.PszRCbuff=PszRCbuff;
        end
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
        % SRC
        if exist('srcInfo','var')
            obj.srcInfo=srcInfo;
        end
        if exist('src','var') && ~isempty(src)
            obj.src=src;
        end
    end

    function obj=parse_src(obj)
        bSrcInfo=~isempty(obj.srcInfo);
        % GET SRC
        if isempty(obj.src) && bSrcInfo
            obj.get_map_srcs();
        elseif ~bSrcInfo
            obj.src=struct();
        end
        if (~isfield(obj.src,'XYZ') || isempty(obj.src.XYZ))
            obj.get_src_xyz();
        end

        if obj.bStereo & (~isfield(obj.src,'CPs') || isempty(obj.src.CPs))
            obj.get_raw_CPs();
        end

        % MAPS MASKS TEX WNDW
        obj.get_buff_CPs();
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

        if isa(obj.srcInfo,'srcInfo')
            obj.name=obj.get_name();
            obj.num=obj.get_num();
        end

        if isempty(obj.PszRCbuff)
            obj.PszRCbuff=PszRC;
            bSmallOnly=1;
        else
            bSmallOnly=0;
        end
        if bSmallOnly
            obj.CPs=obj.CPsBuff;
            obj.CPsBuff=[];

            obj.msks=obj.msksBuff;
            obj.msksBuff=[];

            obj.msks=obj.msksBuff;
            obj.msksBuff=[];

            obj.maps=obj.mapsBuff;
            obj.mapsBuff=[];
            obj.PszRCbuff=[];

        end
    end
    function obj=init_src(obj)
        obj.srcInfo.get_db();
        obj.srcInfo.get_genOpts();
    end
%% SET
    function value=get.PszRC(obj)
        value=obj.PszRCm;
    end
    function value=get.PszXY(obj)
        value=fliplr(obj.PszRCm);
    end
    function obj=set.PszRC(obj,val)
        obj.PszRCm=val;
    end
    function obj=set.PszXY(obj,val)
        obj.PszRCm=fliplr(val);
    end

    function value=get.PszRCbuff(obj)
        value=obj.PszRCbuffm;
    end
    function value=get.PszXYbuff(obj)
        value=fliplr(obj.PszRCbuffm);
    end
    function obj=set.PszRCbuff(obj,val)
        obj.PszRCbuffm=val;
    end
    function obj=set.PszXYbuff(obj,val)
        obj.PszRCbuffm=fliplr(val);
    end
end
methods(Static=true)
    function obj=circle(varargin)
        opts=struct(varargin{:});

        opts.PszRC=[100 100];
        opts.trgt_posXYZm=[0,0,0];
        opts.trgt_dispORwin='disp';
        opts.trgt_trgtDsp=0;

        p={'radius',[],'Num.isnumeric' ...
           ;'color',1,'Num.isnumeric' ...
           ;'alpha',1,'Num.isnumeric' ...
           ;'PctrXY',[],'Num.isnumeric' ...
          };

        circOpts=Parse.byOpts([],opts,p,[],true,true);
        Struct.rmFlds(opts,circOpts);
        if isempty(circOpts.radius)
            circOpts.radius=min(opts.PszRC)/2;
        end
        if isempty(circOpts.PctrXY)
            cirOpts.PctrXY=fliplr(opts.PszRC/2);
        end

        % TEST
        %opts.map=Tx.(opts.PzRC,genName)
        circ=Msk.circle(fliplr(opts.PszRC),circOpts.radius,circOpts.PctrXY);
        if isempty(circOpts.alpha)
            circOpts.alpha=circ;
        end

        opts.msk=circOpts.alpha;
        opts.map=circOpts.alpha;

        obj=ptch(opts);

    end
    function obj=ring(varargin)
        opts=Struct(varargin{:});

        obj.ptch(opts);
    end

end
end
