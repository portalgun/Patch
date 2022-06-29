classdef ptchs < handle & ptch_link & ptchs_file & ptchs_patch & ptchs_dsp & ptchs_plot & ptchs_blk & ptchs_gen
% LOADER SELECTOR
properties
    ptch

    name

    idx
    fnames % XXX rm from sel table
    %I % XXX rm from sel key
    %D % XXX rm from sel key
    %lvlInd
    %blk
    %trl
    %intrvl
    %cmpInd
    %cmpNum

    %Blk stuff

    hashes

    ptchOpts=struct( ...
                    'DispInfo',[]  ...
                   ,'Disp',[]  ...
                   ,'winInfo',[]  ...
                   ,'win',[]  ...
                   ,'trgtInfo',[]  ...
                   ,'trgt',[]  ...
                   ,'focInfo',[]  ...
                   ,'foc',[]  ...
                   ,'subjInfo',[]  ...
                   ,'wdwInfo',[]  ...
                   ,'wdw',[]  ...
                   ,'rmsFix',[]  ...
                   ,'dcFix',[]  ...
                   );
    bDSP=false
    Stats=struct
    edges=struct('bin',[],'smp',[])
    counts=struct('bin',[],'smp',[])

    addAlias

    bLocal=false
    bXYZ=true
    bSameWdw=false
    bSameWin=false
end
properties(Hidden=true)

    Viewer
    Flags

    INDS
    bLoaded

    MODE=-1

    % FOR IND PATCHES
    dire
    dbInfo
    genOpts
    VDisp

    addHashes
    bAppliedOpt=false
    W
    Win
end
methods(Static)
    function a=getAlias()
        a=Env.var('PATCH_ALIAS');
        if isempty(a)
            a=Env.var('ALIAS');
        end
    end
    function p=getBlk(moude,lvlInd,blocks,subjName,hostname,alias)
        if nargin < 6 || isempty(alias)
            alias=Blk.getAlias;
        end
        B=Blk.get(alias);
        if nargin == 1 && strcmp(moude,'all')
            bAll=true;
        else
            bAll=false;
        end
        if bAll || (nargin >= 1 && ischar(moude) && strcmp(moude,'all'))
            moude=B.get_modes();
        elseif nargin >=1
            ;
        else
            moude=[];
        end
        if bAll || (nargin>= 2 && ischar(lvlInd) && strcmp(lvlInd,'all'))
            lvlInd=B.get_lvlInds();
        elseif nargin >= 2
            ;
        else
            lvlInd=[];
        end
        if bAll || (nargin>=  3 && ischar(blocks) && strcmp(blocks,'all'))
            blocks=B.get_blocks();
        elseif nargin >= 3
            ;
        else
            blocks=[];
        end
        if nargin < 4
            subjName=[];
        end
        if nargin < 5
            hostname=[];
        end
        p=ptchs.get_helper(moude,lvlInd,blocks,hostname,subjName, B);
        if nargout < 1
            assignin('caller','P',p);
        end
    end
    function p=getAll(subjName,hostname)
        B=Blk.get();
        mode=B.get_modes();
        lvlInd=B.get_lvlInds();
        blocks=B.get_blocks();

        if nargin < 1
            subjName=[];
        end
        if nargin < 2
            hostname=[];
        end

        p=ptchs.get_helper(mode,lvlInd,blocks,hostname,subjName, B);

        if nargout < 1
            assignin('caller','P',p);
        end
    end
    function p=getRaw(subjName,hostname)
        if nargin < 1
            subjName=[];
        end
        if nargin < 3
            hostname=[];
        end
        p=ptchs.get_helper(hostname,subjName);
        if nargout < 1
            assignin('caller','P',p);
        end
    end
    function gen(bRedo)
        if nargin < 1
            bRedo=false;
        end
        if bRedo
            Blk.gen();
        end
        P=ptchs.getRaw();
        assignin('base','P',P);
        P.gen_ptch_all_blk('blkAlias',Blk.getAlias(), 'ptchAlias',ptchs.getAlias(),'bRedo',bRedo);
    end
end
methods(Static,Access=protected)
    function P=get_helper(moude,lvlInd,blocks,hostname,subjName,B)
        palias=ptchs.getAlias();
        if nargin < 3
            P=ptchs.load(palias);
        else
            if nargin >= 6 && isa(B,'Blk')
                balias=B;
            else
                balias=Blk.getAlias();
            end
            P=ptchs.loadBlk(palias, ...
                            balias,...
                            [],...
                            moude,lvlInd,blocks);
            P.apply_display(hostname,subjName);
        end
        P.name=palias;
    end
end
methods
    function obj=ptchs(name, hashes, srcTable, srcKey, selTable,selKey, lvlTable)
        if ~exist('name','var')
            return
        end
        obj.Info.name=name;
        obj.hashes=hashes;

        if exist('srcTable','var') && ~isempty(srcTable)
            obj.parse_srcTable(srcTable,srcKey);
        end

        if exist('selTable','var') && ~isempty(selTable)
            obj.parse_selTable(selTable,selKey);
            obj.get_mode();
        end
        if exist('lvlTable','var') && ~isempty(lvlTable)
            obj.parse_lvlTable(lvlTable);
        end
        obj.get_mode();
        obj.INDS=cell(length(obj.fnames),1);
        obj.bLoaded=false(length(obj.fnames),1);


        obj.init_parts();
        obj.getFlags();
    end
    function bInd=exist(obj,bBlk,bins)
        if bBlk
            nums=P.Blk.unique('P');
        else
            nums=true(size(obj.fnames));
            if nargin >= 2
                nums=ismember(obj.idx.B,bins);
            end
        end
        bInd=nan(size(obj.fnames));
        bInd(nums)=double(cellfun(@Fil.exist, strcat(obj.get_dir, obj.fnames(nums),'.mat')));
    end
    function obj=apply_display(obj,hostn,subjName)
        global VDISP;
        if isempty(hostn) && ~isempty(VDISP)
            hostn=VDISP.hostname;
        elseif isempty(hostn)
            hostn=Sys.hostname;
        end
        if isempty(VDISP)
            Error.warnSoft(['Applying default display to patches: ' hostn ]);
            obj.VDisp=VDisp(hostn,subjName);
        else
            obj.VDisp=VDISP;
        end
        obj.ptchOpts.DispInfo=hostn;
        obj.ptchOpts.subjInfo=obj.VDisp.SubjInfo;
    end
    function init_parts(obj)
        if isempty(obj.Flags)
            obj.Flags=PtchsFlag(obj);
        end
    end
    function obj=parse_srcTable(obj,srcTable,srcKey)
        %srcKey={'P','fname','I','K','B','S','PctrRC','binVal','val'}
        obj.idx=struct();
        flds=srcKey;
        for i = 1:length(flds)
            fld=flds{i};
            val=srcTable(:,i);
            if strcmp(fld,'fname')
                obj.fnames=val;
            else

                if all(cellfun(@isnumeric,val))
                    val=cell2mat(val);
                end
                obj.idx.(fld)=val;
            end
        end
    end
    function obj=parse_selTable(selTable,selKey)
        %selKey={'I','D','lvl','blk','trl','cmpNum','fname'}
        obj.idx=struct();
        flds=selKey;
        for i = 1:length(flds)
            fld=flds{i};
            val=selTable(:,i);
            obj.idx.(fld)=val;
        end
    end
    function obj=parse_lvlTable(lvlTable)
        obj.Xunits=lvlTable.unitsKey;
        obj.Xnames=lvlTable.nameKey;
        obj.Xinds=lvlTable.inds;
        obj.Xvals=lvlTabl.valKey;
    end
    function obj=get_mode(obj);
        if isfield(obj.idx,'mode') && ~isempty(obj.idx.mode) && Set.isUniform(obj.idx.mode)
            obj.MODE=obj.idx.mode(1);
        end
    end
    function obj=init(obj,initLvl)
        if initLvl==1
            return
        elseif initLvl==2
            obj.load_all_patches_minimal();
        elseif initLvl==3
            obj.load_all_patches();
        end
    end
%% INIT 2
%% SAVE
    function obj=save_patch(obj)

        % TODO
    end
    function obj=return_psy_info(obj)
        S=struct();
        [S.stdIind, S.X, S.bin, S.intrvl]=cmp_fun(obj,0);
        %stdXind

        n=max(obj.inds==1);
        nans=nan(size(obj.fnames),n);

        S.cmpIind=nans;
        S.X=nans;
        S.bin=nans;
        S.intrvl=nans;

        for i = 1:n
            [S.cmpIind(:,i),S.X(:,i),S.bin(:,i),S.intrvl(:,i)]=cmp_fun(obj,i);
        end
        function [Iind,X,bin,Intrvl]=cmp_fun(obj,num)
            ind=obj.idx.cmp==num;
            Iind=obj.idx.P(ind);
            X=obj.idx.X.P(ind);
            Intrvl=obj.idx.X.intrvl(ind);
        end
    end
%% PLOT
    function out=length(obj)
        if obj.bBlk
            out=obj.Blk.blk.length();
        else
            out=length(obj.fnames);
        end
    end
%% FILTER
%% FLAGS
    function getFlags(obj)
        obj.Flags.get();
    end
%% VIEWER
    function OUT=plot(obj,start,alias)
        if nargin < 2
            start=[];
        end
        if nargin < 3
            alias=[];
        end
        if isempty(obj.Viewer)
            obj.Viewer=PtchsViewer(obj,alias,false);
        end
        obj.Viewer.run(start,true);
        if nargout > 0
            OUT=obj.Viewer;
        end
    end
    function OUT=view(obj,start,alias)
        if nargin < 2
            start=[];
        end
        if nargin < 3
            alias=[];
        end
        if isempty(obj.Viewer)
            obj.Viewer=PtchsViewer(obj,alias,false);
        end
        obj.Viewer.run(start,false);
        if nargout > 0
            OUT=obj.Viewer;
        end
    end
    function OUT=pView(obj,bReInit,start,alias)
        if nargin < 2
            bReInit=false;
        end
        if nargin < 3
            start=[];
        end
        if nargin < 4
            alias=[];
        end
        if bReInit || isempty(obj.Viewer)
            obj.Viewer=PtchsViewer(obj,alias,true);
            assignin('base','V',obj.Viewer);
        end
        obj.Viewer.run(start,false);
        if nargout > 0
            OUT=obj.Viewer;
        end
    end
    function reload(obj)
        %obj.Ptchs.reload();
    end
    function out=get_src_table(obj,alias)
        if nargin < 2 || isempty(alias)
            dire=obj.get_dir;
        else
            hashes=ImapCommon.alias2hashes(alias);
            dire=ImapCommon.get_directory_f(hashes.database,'tbl',hashes.tbl);
        end
        S=load([dire '_src_.mat']);
        ind=cellfun(@isempty,S.table(:,6));
        types={'double','char','double','double','double','double','double','double','double'};
        out=Table(S.table,S.key,types);
    end
    function tbl=to_table(obj,bins)
        if nargin < 2 || isempty(bins)
           bins=true(size(obj.fnames));
        end
        inds=ismember(obj.idx.B,bins);
        tbl=[obj.idx.B(inds) obj.idx.I(inds) obj.idx.K(inds) obj.idx.PctrRC(inds,:)];
    end
    function getStat(obj,stat,varargin)
        switch stat
        case 'dot'
            nm=['_CP_verify_dot_' strrep(Num.toStr(varargin{1}),',','-') '_'];
        case {'rms','RMS'}
            nm='_RMSmono_.mat';
        end
        fname=[obj.get_dir() nm];
        S=load(fname);
        flds=fieldnames(S);
        for i = 1:length(flds)
            obj.Stats.(flds{i})=S.(flds{i});
        end
    end
    function addExtra(obj,alias)
        tbl=obj.get_src_table(alias);
        P.addAlias=alias;

        n=size(obj.fnames,1);
        N=max(tbl{'P'});

        obj.fnames=[obj.fnames; tbl{'fname'}];
        flds=tbl.KEY;


        for i = 1:length(flds)
            if ismember(flds{i},{'fname'});
                continue
            end
            obj.idx.(flds{i})=[obj.idx.(flds{i}); tbl{flds{i}}];
        end
        if ~isfield(obj.idx,'bExtra')
            obj.idx.bExtra=false(N,1);
        end
        obj.idx.bExtra(n+1:end)=true;

        L=false(N-n,1);
        D=zeros(N-n,1);
        flds={'seen','bad','poor','other'};
        for i = 1:length(flds)
            if islogical(obj.Flags.(flds{i}))
                obj.Flags.(flds{i})=[obj.Flags.(flds{i}); L];
            else
                obj.Flags.(flds{i})=[obj.Flags.(flds{i}); D];
            end
        end
        bBad=obj.load_badGen;
        bBad=[bBad; L];
        dire=obj.get_dir();
        fname=[dire '_bad_gen_.mat'];
        save(fname,'bBad');
    end
    function maxP(obj)
        p=obj.Blk('P');
        disp(max(p{:}))
    end

end
end
