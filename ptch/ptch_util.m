classdef ptch_util < handle
% TODO binVal -> edges
% TODO PctrRC after K
methods
    %function ptch=load(obj)
    %    fname=obj.get_fname();
    %    load(fname);
    %end
    function ptch=ptch2struct(obj)
        ptch=convert_fun(obj);

        function out=convert_fun(in)
            out=obj2structPublic(in);
            if ~isstruct(out)
                return
            end
            flds=fieldnames(in);
            for i = 1:length(flds)
                fld=flds{i};
                if isobject(out.(fld))
                    out.(fld)=convert_fun(out.(fld));
                end
            end
        end
    end
    function save(obj)
        fname=obj.get_fname();
        dire=fileparts(fname);
        if ~exist(dire,'dir')
            mkdir(dire);
        end

        ptch=obj.ptch2struct();
        ptch=obj.to_single_fun(ptch);
        ptch.srcInfo.db=[];
        ptch.srcInfo.genOpts=[];
        save(fname,'ptch');
    end
    function ptch=to_single_fun(obj,ptch)

        for k = 1:(obj.bStereo+1)
            ptch.PctrCPs{k}=single(ptch.PctrCPs{k});
            for i = 1:2
                ptch.CPsBuff{i}{k}=single(ptch.CPsBuff{i}{k});
            end
            for f=1:length(obj.mapNames)
                fld=obj.mapNames{f};
                val=ptch.mapsbuff.(fld){k};
                if iscell(val)
                    for i = 1:length(val)
                        ptch.mapsbuff.(fld){k}{i}=single(val{i}); % k and i switched
                    end
                else
                    ptch.mapsbuff.(fld){k}=single(val); % k and i switched
                end
            end
        end
    end
    function ptch=to_double_fun(obj)

        for k = 1:(obj.bStereo+1)
            obj.PctrCPs{k}=double(obj.PctrCPs{k});
            for i = 1:2
                obj.CPsBuff{i}{k}=double(obj.CPsBuff{i}{k});
            end
            for f=1:length(obj.mapNames)
                fld=obj.mapNames{f};
                val=obj.mapsbuff.(fld){k};
                if iscell(val)
                    for i = 1:length(val)
                        obj.mapsbuff.(fld){k}{i}=double(val{i}); % k and i switched
                    end
                else
                    obj.mapsbuff.(fld){k}=double(val); % k and i switched
                end
            end
        end
    end
    function out=check_patch_exist(obj)
        if isfield(obj.srcInfo.hashes,'dsp')  && ~isempty(obj.srcInfo.hashes.dsp) && bDSP

            hash=obj.srcInfo.hashes.dsp;
        else
            hash=obj.srcInfo.hashes.pch;
        end
        out=ptch.check_patch_exist_p(obj.database,hash,obj.I,obj.k,obj.B,obj.S);

    end
    function fname=get_fname(obj)
        s=obj.srcInfo;
        if ~obj.bDSP
            fname=ptch.get_fname_p(s.database, s.hashes.pch, s.I, s.K, s.B, s.S);
        else
            fname=obj.get_fname_dsp_p(s.database, s.hash.dsp, s.I, s.K, s.B, s.S);
        end
    end
    function num=get_num(obj)
        num=obj.srcInfo.P;
    end
    function name=get_name(obj)
        name=ptch.get_name_p(obj.srcInfo.I, obj.srcInfo.K, obj.srcInfo.B, obj.srcInfo.S);
    end
%% genOpts
    function obj=load_genOpts(obj)
        obj.srcInfo.genOpts=imapGen.load_genOpts(obj.srcInfo.database, obj.srcInfo.hashes.gen);
    end
%% db
    function obj=load_db(obj)
        obj.srcInfo.db=dbInfo('LRSI');
    end
end
methods(Static=true)
    function obj=load(thing)
        if isstruct(thing)
            S=thing;
        elseif ischar(thing)
            S=load(thing);
            S=S.ptch;
        end

        obj=ptch();
        flds=fieldnames(S);
        for i = 1:length(flds)
            fld=flds{i};
            if strcmp(fld,'srcInfo') && isstruct(S.(fld))
                obj.srcInfo=srcInfo(S.srcInfo);
            %elseif strcmp(fld,'dispInfo') && isstruct(S.(fld))
            %    obj.dispInfo=dispInfo(S.srcInfo);
            %elseif strcmp(fld,'winInfo') && isstruct(S.(fld))
            %    obj.winInfo=winInfo(S.srcInfo);
            %elseif strcmp(fld,'trgtInfo') && isstruct(S.(fld))
            %    obj.trgtInfo=trgtInfo(S.srcInfo);
            %elseif strcmp(fld,'focInfo') && isstruct(S.(fld))
            %    obj.focInfo=focInfo(S.srcInfo);
            elseif isprop(obj,fld)
                obj.(fld)=S.(fld);
            end
        end
        obj.to_double_fun();
        obj.load_db();
        obj.load_genOpts();
        obj.get_default_masks();
        obj.apply_map_bi('pht',[]);
    end
    function out=check_patch_exist_p(database,hash,I,k,B,S)
        out=0;
        [fname,dire]=ptch.get_fname_p(database,hash,I,k,B,S);
        fname=[fname '.mat'];
        out=exist(fname,'file');
    end
    function [fname,dire]=get_fname_dsp_p(database,hash,I,k,B,P)
        name=ptch.get_name_p(I,k,B,P);
        dire=ptch.get_directory_dsp_ind_p(database,hash);
        fname=[dire name];
    end
    function [fname,dire]=get_fname_p(database,hash,I,k,B,S)
        name=ptch.get_name_p(I,k,B,S);
        dire=ptch.get_directory_p(database,hash);
        fname=[dire name];
    end
    function name=get_name_p(I,k,B,P)
        if k == 1
            LR='L';
        elseif k==2
            LR='R';
        end

        name=[LR numfun(I)  und  numfun(B) und numfun4_p(P) ];
        function str=numfun(num)
            str=num2str(num,'%03i');
        end
        function str=numfun4_p(num)
            str=num2str(num,'%04i');
        end
    end
    function dire=get_directory_p(database,hash)
        database=[database 'ptch'];
        rootDBdir=imapCommon.get_rootDBdir(database);
        dire=[rootDBdir 'pch' filesep  hash filesep];
    end
    function dire=get_directory_dsp_p(database,hash)
        database=[database 'ptch'];
        rootDBdir=imapCommon.get_rootDBdir(database);
        dire=[rootDBdir 'dsp' filesep '_' hash filesep];
    end
%% DSP ind
    function dire=get_directories_dsp_ind_p(database,indHash)
        ptch.get_directory_dsp_p(database,indHash,database);
    end
    function dire=get_directory_dsp_ind_p(database,indHash)
        database=[database 'ptch'];
        rootDBdir=imapCommon.get_rootDBdir(database);
        dire=[rootDBdir 'dsp' filesep indHash filesep];
    end
    function ind=load_dsp_ind(database,hash)
        fname=get_dsp_ind_fname(database,hash);
        load(fname);
    end
    function fname=get_dsp_ind_fname(database,hash)
        dire=ptch.get_directory_dsp_p(database,indHash);
        fname=[dire '_ind'];
    end
end
end
