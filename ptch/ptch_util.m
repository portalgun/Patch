classdef ptch_util < handle & ptch_link
% TODO binVal -> edges
% TODO PctrRC after K
methods
    %function ptch=load(obj)
    %    fname=obj.get_fname();
    %    load(fname);
    %end
    %
    function fnames=load_name_index(obj)
        fnames=ptch.load_name_index_f(obj.srcInfo.database,obj.srcInfo.hashes.smp);
    end
    function ptch=ptch2struct(obj)
        ptch=convert_fun(obj);

        function out=convert_fun(in)
            out=Obj.pubStruct(in);
            if ~isstruct(out)
                return
            end
            flds=fieldnames(in);
            for i = 1:length(flds)
                fld=flds{i};
                if isobject(out.(fld))
                    out.(fld)=convert_fun(out.(fld));
                elseif isempty(out.(fld)) || ( iscell(out.(fld)) && all(cellfun(@isempty,out.(fld))) );
                    out=rmfield(out,fld);
                end
            end
        end
    end
    function [bSuccess,ME]=save(obj)
        bSuccess=false;
        fname=obj.get_fname();
        dire=Fil.parts(fname);
        if ~exist(dire,'dir')
            mkdir(dire);
        end

        ptch=obj.ptch2struct();
        ptch=obj.prune_ptch(ptch);

        try
            ptch=obj.to_single_fun(ptch);
            ME=[];
        catch ME
            if nargout < 1
                disp(['warning: patch ' num2str(obj.srcInfo.P) ' not saved'])
            end
            return
        end

        save(fname,'ptch');
        bSuccess=true;
    end
    function p=prune_ptch(obj,p)
        flds={'bStereo','name','im','bDSP','winInfo','subjInfo','PszXY','num','database'};
        for i = 1:length(flds)
            if isfield(p,flds{i})
                p=rmfield(p,flds{i});
            end
        end

        flds={'genOpts','db'};
        for i =1:length(flds)
            if isfield(p.srcInfo,flds{i})
                p.srcInfo=rmfield(p.srcInfo,flds{i});
            end
        end

    end
    function ptch=to_single_fun(obj,ptch)

        for k = 1:(obj.bStereo+1)
            if isfield(ptch,'PctrCPs')
                ptch.PctrCPs{k}=single(ptch.PctrCPs{k});
            end
            if isfield(ptch,'CPsBuff')
                for i = 1:2
                    ptch.CPsBuff{i}{k}=single(ptch.CPsBuff{i}{k});
                end
            end
            for f=1:length(obj.mapNames)
                fld=obj.mapNames{f};
                val=ptch.mapsBuff.(fld){k};
                if iscell(val)
                    for i = 1:length(val)
                        ptch.mapsBuff.(fld){k}{i}=single(val{i}); % k and i switched
                    end
                else
                    ptch.mapsBuff.(fld){k}=single(val); % k and i switched
                end
            end
        end
    end
    function ptch=to_double_fun(obj)

        for k = 1:min(2,(obj.bStereo+1))
            obj.PctrCPs{k}=double(obj.PctrCPs{k});
            for i = 1:2
                obj.CPsBuff{i}{k}=double(obj.CPsBuff{i}{k});
            end
            for f=1:length(obj.mapNames)
                fld=obj.mapNames{f};
                val=obj.mapsBuff.(fld){k};
                if iscell(val)
                    for i = 1:length(val)
                        obj.mapsBuff.(fld){k}{i}=double(val{i}); % k and i switched
                    end
                else
                    obj.mapsBuff.(fld){k}=double(val); % k and i switched
                end
            end
        end
    end
    function out=check_patch_exist(obj)
        if isfield(obj.srcInfo.hashes,'dsp')  && ~isempty(obj.srcInfo.hashes.dsp) && bDSP

            hash=obj.srcInfo.hashes.dsp;
        else
            hash=obj.srcInfo.hashes.tbl;
        end
        out=ptch.check_patch_exist_p(obj.database,hash,obj.I,obj.k,obj.B,obj.S);

    end
    function fname=get_fname(obj)
        s=obj.srcInfo;
        if ~obj.bDSP
            fname=ptch.get_fname_p(s.database, s.hashes.tbl, s.I, s.K, s.B, s.S);
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
        if isempty(obj.dire)
            dire=ptch.get_directory_p(obj.srcInfo.database,obj.srcInfo.hashes.tbl);
        else
            dire=obj.dire;
        end
        fname=[dire '_genOpts_.mat'];
        if Fil.exist(fname)
            load(fname);
            obj.srcInfo.genOpts=genOpts;
        elseif Fil.exist(fnameGen)
            obj.srcInfo.genOpts=ImapGen.load_genOpts(obj.srcInfo.database, obj.srcInfo.hashes.gen);
        end
    end
%% db
    function obj=load_db(obj)
        obj.srcInfo.db=dbInfo(obj.srcInfo.database);
    end
end
methods(Static=true)
    function obj=load(thing, dbInf, genOpts)
        if isstruct(thing)
            S=thing;
        elseif ischar(thing)
            S=load(thing);
            S=S.ptch;
            S.dire=Fil.parts(thing);
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
            else %if isprop(obj,fld)
                obj.(fld)=S.(fld);
            end
        end
        %% LEGACY
        if ~ismember_cell('mapsBuff',flds) && ismember_cell('mapsbuff',flds)
            obj.mapsBuff=S.mapsbuff;
        end
        obj.to_double_fun();
        if nargin < 2 && isempty(dbInf)
            obj.load_db();
        else
            obj.srcInfo.db=dbInf;
        end
        if nargin < 3 && isempty(genOpts)
            obj.load_genOpts();
        else
            obj.srcInfo.genOpts=genOpts;
        end

        obj.get_default_masks();
        obj.apply_map('pht',[]); %init map % SLOW 1

        %obj.database=obj.srcInfo.database;
        obj.num=obj.srcInfo.P;
        obj.name=obj.srcInfo.fname;
        obj.PszXY=fliplr(obj.PszRC);
        obj.bStereo= iscell(obj.CPsBuff) && numel(obj.CPsBuff)==2 && all(~cellfun(@isempty,obj.CPsBuff));
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

        name=[LR numfun(I)  '_'  numfun(B) '_' numfun4_p(P) ];
        function str=numfun(num)
            str=num2str(num,'%03i');
        end
        function str=numfun4_p(num)
            str=num2str(num,'%04i');
        end
    end
    function dire=get_directory_p(database,hash,bLocal)
        if nargin < 3 || isempty(bLocal)
            bLocal=false;
        end
        if bLocal
            dire=[Dir.parse(Env.var('Patch.pch_local')) hash filesep];
        else
            dire=[Dir.parse(Env.var('Patch.pch')) hash filesep];
        end
        %rootDBdir=ImapCommon.get_ptchDBdir(database);
        %dire=[rootDBdir 'pch' filesep  hash filesep];
    end
    function dire=get_directory_dsp_p(database,hash)
        dire=[Dir.parse(Env.var('Patch.dsp')) hash filesep];
        %rootDBdir=ImapCommon.get_ptchDBdir(database);
        %dire=[rootDBdir 'dsp' filesep '_' hash filesep];
    end
%% DSP ind
    function dire=get_directories_dsp_ind_p(database,indHash)
        ptch.get_directory_dsp_p(database,indHash,database);
    end
    function dire=get_directory_dsp_ind_p(database,indHash)
        dire=Dir.parse(Env.var('Patch.dsp'));
        dire=[direindHash filesep];
    end
    function ind=load_dsp_ind(database,hash)
        fname=get_dsp_ind_fname(database,hash);
        load(fname);
    end
    function fname=get_dsp_ind_fname(database,hash)
        dire=ptch.get_directory_dsp_p(database,indHash);
        fname=[dire '_ind'];
    end
%% NAME INDEX
    function idx=load_name_index_f(database,hash)
        fnames=ptch.get_name_index_fname(database,hash);
        load(fnames);
    end
    function fname=get_name_index_fname(database,hash)
        dire=ptch.get_directory_p(database,hash);
        name=ptch.get_name_index_name_p();
        fname=[dire name];
    end
    function name=get_name_index_name_p()
        name='_ind_';
    end
    function nums=names2nums(database,hash,names)
        nameIndex=ptch.load_name_index_f(database, hash);
        [~,nums]=ismember(names,nameIndex);
    end
end
end
