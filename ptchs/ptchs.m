classdef ptchs < handle & ptchs_file & ptchs_load & ptchs_dsp & ptchs_plot & ptchs_blk
% LOADER SELECTOR
properties
    ptch

    name

    fnames % XXX rm from sel table
    bLoaded

    idx
    %I % XXX rm from sel key
    %D % XXX rm from sel key
    %lvlInd
    %blk
    %trl
    %intrvl
    %cmpInd
    %cmpNum


    Xnames
    Xunits
    Xvals
    Xinds

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
    bDSP=0
end
properties(Hidden=true)
    INDS
    MODE=-1
end
methods
    function obj=ptchs(name, hashes, srcTable, srcKey, selTable,selKey, lvlTable)
        obj.name=name;
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
        if isfield(obj.idx,'mode') && ~isempty(obj.idx.mode) && isuniform(obj.idx.mode)
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
    function obj=plot(obj)
        ptchsViewer(obj);
    end
end
end
