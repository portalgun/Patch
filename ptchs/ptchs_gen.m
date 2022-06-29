classdef ptchs_gen < handle
properties(Access=private)
    lastMsg=0;
    bads
    bExist
end
methods
    %PszRC % DEF
    %PszRCbuff % DEF
    %mapNames % DEF
    %mskNames % DEF
    %texNames % DEF
    %bStereo % DEF
    %srcInfo
    function get_idx_from_src_table(obj)
        table=ImapPch_Tsrc.get_src_table;
        %table
        %key

        Iind = ismember(key,'I');
        Kind = ismember(key,'K');
        Bind = ismember(key,'B');
        Sind = ismember(key,'S');
        Pind = ismember(key,'P');
        Cind = ismember(key,'PctrRC');
        BVind= ismember(key,'binVal');
        VInd = ismember(key,'val');
        Find = ismember(key,'fname');

        obj.idx.I     =table{Iind,:};
        obj.idx.K     =table{Kind,:};
        obj.idx.B     =table{Bind,:};
        obj.idx.S     =table{Sind,:};
        obj.idx.P     =table{Pind,:};
        obj.idx.PctrRC=table{Cind,:};
        obj.idx.binVal=table{BVind,:};
        obj.idx.val   =table{VInd,:};
        obj.fnames    =table{Find,:};
    end
    function opts=parse_gen(obj,varargin)
        opts=struct(varargin{:});
        P={...
           'blkAlias',[],'ischar';
           'ptchAlias',[],'ischar';
           'imNums',[],'Num.is';
           'bRedo',false,'isbinary';
           'bCheckAll',false,'isbinary';
           'limits',{},'iscell';
           'bSkipBadList',false,'isbinary';
        };
        opts=Args.parse([],P,opts);
        if isempty(opts.blkAlias)
            alias=ImapCommon.hash2alias(obj.hashes.tbl);
            if numel(alias)==1
                opts.blkAlias=alias{1};
            else
                error('Must provide blkAlias');
            end
        end
        if isempty(opts.ptchAlias)
            opts.ptchAlias=opts.blkAlias;
        end
    end
%% MAIN
    function gen_ptch_all_blk(obj,varargin)
        opts=obj.parse_gen(varargin{:});
        if ~obj.bBlk
            obj.apply_block_all(opts.blkAlias);
        end

        inds=unique(obj.Blk.blk('P').ret());
        [inds,order]=obj.sort_ptch_inds(inds,opts);
        N=length(inds);
        p=obj.gen_ptch_blk_prog(inds,opts,N);
        obj.gen_ptch_all_main(inds,order,opts,p);
    end
    function gen_ptch_all(obj,inds,varargin)
        opts=obj.parse_gen(varargin{:});
        if nargin < 2 || isempty(inds)
            inds=1:length(P.fnames);
        end

        [inds,order]=obj.sort_ptch_inds(inds,opts);
        N=length(inds);
        p=obj.gen_ptch_prog(opts,N);
        obj.gen_ptch_all_main(inds,order,opts,p);
    end
%%
    function p=gen_ptch_prog(obj,opts,N)
        p=Pr(N,1,['Creating Patches: ' newline ...
                  '    ' opts.ptchAlias newline ...
                  '    ' obj.hashes.tbl  newline]);
    end
    function p=gen_ptch_blk_prog(obj,inds,opts,N)
        p=Pr(N,1,['Creating Patches: ' newline ...
                  '    ' opts.ptchAlias newline ...
                  '    ' obj.hashes.tbl  newline ...
                  '    ' 'Blk ' num2str(logical(obj.bBlk))]);
        out=cellfun(@isempty,obj.fnamesB);
        out=cellfun(@isempty,obj.fnames);

        disp(sprintf('    fnames in fnamesB; %d%%',sum(ismember(obj.fnames(inds),obj.fnamesB))/numel(obj.fnames(inds))*100)); %
        disp(sprintf('    fnamesB in fnames; %d%%',sum(ismember(obj.fnamesB,obj.fnames(inds)))/numel(obj.fnamesB)*100)); %
    end
    function [inds,order]=sort_ptch_inds(obj,inds,opts)
        [order,ind]=sortrows([obj.idx.I(inds),obj.idx.K(inds)],'ascend');
        inds=inds(ind);

        if  ~isempty(opts.imNums);
            imInds=ismember(order(:,1),opts.imNums);
            order=order(imInds,:);
            inds=inds(imInds);
        end
    end
    function gen_ptch_all_main(obj,inds,order,opts,p)
        Opts=ptch.get_src_opts(opts.ptchAlias);
        Opts.hashes=obj.hashes;

        names={'pht'};
        names=union(names, Opts.mapNames);
        names=union(names, Opts.mskNames);
        if ~isempty(Opts.texNames);
            names=union(names, Opts.texNames(~Tx.isgen(Opts.texNames)));
        end

        database=obj.hashes.database;
        db=dbInfo(database);


        last=0;
        N=length(inds);

        AitpRC0=CPs.getAitpRC0(Opts.PszRCbuff);

        if isempty(obj.bExist) || opts.bCheckAll
            obj.check_files(inds,opts.bCheckAll);
        end

        obj.lastMsg=0;
        for ii = 1:N
            p.u();
            i=inds(ii);
            if ~opts.bRedo && obj.bExist(i)
                continue
            end

            %% GET CPS
            if ~isequal(last,order(ii,1))
                src=ptch.getSrc(database,names,order(ii,1),db,AitpRC0);
            end

            [bSuccess,ME]=obj.gen_ptch(i,Opts,src,db,AitpRC0);
            if ~bSuccess
                obj.mark_bad(p,i,ME);
                continue
            end

            %% CHECK FNAMES
            [~,pf]=Fil.parts(obj.ptch.get_fname);
            if ~strcmp(pf,obj.fnames{i})
                error('filenames do not match: \n    %s\n    %s',pf,obj.fnames{i}); %
            end

            %% SAVE
            [bSuccess,ME]=obj.ptch.save();
            if ~bSuccess
                disp(ME.message);
                error('File %s not saved.',obj.fnames{i});
                %obj.mark_bad(p,i,bads);
                %continue
            end
            last=order(ii,1);
            obj.bExist(i)=true;
        end
        p.c();
        obj.save_bExist;
        % TODO ALSO CHECK TO SEE IF NEW BAD WERE CREATED DURING THIS SESSION
        if ~opts.bSkipBadList
            disp('Generating and saving badlist...');
            obj.save_badGen();
        end

    end
    function out=exist_badGen(obj)
        dire=obj.get_dir();
        fname=[dire '_bad_gen_.mat'];
        out=Fil.exist(fname);
    end
    function bBad=load_badGen(obj)
        dire=obj.get_dir();
        fname=[dire '_bad_gen_.mat'];
        load(fname);
    end
    function save_badGen(obj)
        bBad=cellfun(@Fil.exist, obj.bads);
        dire=obj.get_dir();
        fname=[dire '_bad_gen_.mat'];
        save(fname,'bBad');
    end
    function save_bExist(obj)
        bExist=obj.bExist;
        dire=obj.get_dir();
        fname=[dire '_exist_.mat'];
        save(fname,'bExist');
    end
    function check_files(obj,inds,bCheckAll)
        if nargin < 2 || isempty(inds)
            inds=1:length(obj.fnames);
        end
        if nargin < 3 || isempty(bCheckAll)
            bCheckAll=false;
        end

        dire=obj.get_dir();
        fnames=strcat(dire, obj.fnames(inds), '.mat');
        obj.bads=strcat(dire, obj.fnames, '.bad');
        badsT=obj.bads(inds);

        fname=[dire '_exist_.mat'];
        if ~bCheckAll && Fil.exist(fname)
            load(fname);
            obj.bExist=bExist;
            bExistC=num2cell(bExist(inds));
        else
            obj.bExist=false(size(obj.fnames(inds)));
            bExistC=num2cell(obj.bExist);
        end
        ('Checking Files...');
        bExistT=cellfun(@(x,y,z) x || Fil.exist(y) || Fil.exist(z),bExistC,fnames,badsT);
        obj.bExist(inds)=bExistT;
        obj.save_bExist();

    end
    function mark_bad(obj,p,i,ME)
        Fil.touch(obj.bads{i});
        err1='MATLAB:badsubscript';
        switch ME.identifier
            case err1
                if strcmp(ME.stack(1).name,'CPs.lookupLR')
                    errNo=2;
                else
                    rethrow(ME);
                end
            otherwise
                if contains(ME.message,'Not enough space to crop')
                    errNo=1;
                else
                    rethrow(ME);
                end
        end
        obj.bExist(i)=true;
        if obj.lastMsg~=errNo
            msg=sprintf('warning %d: patches not generated:\n  #%4d %s ',errNo,i,obj.fnames{i});
            obj.lastMsg=errNo;
        else
            msg=sprintf('  #%4d %s ',i,obj.fnames{i});
        end
        p.append_msg(msg);
    end
    function [bSuccess,ME]=gen_ptch(obj,ind,Opts,src,db,AitpRC0)
        if nargin < 4 || isempty(src)
            src=ptch.getSrc(database,names,order(i,1),db,AitpRC0);
        end
        if nargin < 5
            db=[];
        end
        Opts.srcInfo=obj.select_ptch_srcInfo(ind,src,db);
        Opts.src=src;
        if isfield(Opts,'PszXY')
            Opts.PszRC=fliplr(Opts.PszXY);
        end
        ME=[];
        try
            obj.ptch=ptch(Opts);
            bSuccess=true;
        catch ME
            bSuccess=false;
        end
    end
    function srcInfo=select_ptch_srcInfo(obj,ind,src,db)

        k=obj.idx.K(ind);
        if k==1; nk=2; else; nk=1; end;
        ctr=obj.idx.PctrRC(ind,:);

        srcInfo.I=obj.idx.I(ind);
        srcInfo.K=k;
        srcInfo.B=obj.idx.B(ind);
        srcInfo.S=obj.idx.S(ind);
        srcInfo.P=obj.idx.P(ind);
        srcInfo.PctrRC=cell(1,2);
        srcInfo.PctrRC{k}=ctr;


        %ctr
        [~,srcInfo.PctrRC{nk}]=CPs.lookupAB(ctr,k,src.CPs,db.IszRC,false);
        %srcInfo.PctrRC{2}

        %srcInfo.PctrRC{nk}
        % Num.minMax(src.CPs{k}{nk}(:,1))
        % Num.minMax(src.CPs{k}{nk}(:,2))
        %% dk

        %% Num.minMax(src.CPs{k}{k}(:,1))
        %% Num.minMax(src.CPs{k}{k}(:,2))
        %% Num.minMax(src.CPs{nk}{k}(:,1))
        %% Num.minMax(src.CPs{nk}{k}(:,2))
        %% Num.minMax(src.CPs{nk}{nk}(:,1))
        %% Num.minMax(src.CPs{nk}{nk}(:,2))

        srcInfo.fname=obj.fnames(ind);
        if srcInfo.K==1
            srcInfo.LorR='L';
        else
            srcInfo.LorR='R';
        end
        srcInfo.binVal=obj.idx.binVal(ind);
        srcInfo.val=obj.idx.val(ind);
        srcInfo.hashes=obj.hashes;
        srcInfo.database=obj.hashes.database;
        srcInfo.db=db;
    end
end
end
