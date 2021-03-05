classdef srcInfo < handle
properties
    database

    hashes
    fname

    I % image
    K % LorR
    B % bin
    S % subbin
    P % patch index
    LorR
    PctrRC % cell 2

    binVal
    Val

    db
    genOpts

end
methods
    function obj=srcInfo(database,hashes,I,K,PctrRC,B,S,P,binVal,Val,db,genOpts,fname)
        if isstruct(database)
            obj.construct_from_struct(database);
            return
        end
        obj.database=database;
        obj.hashes=hashes;
        obj.I=I;
        obj.K=K;
        if exist('B','var') && ~isempty(B)
            obj.B=B;
        end
        if exist('S','var') && ~isempty(S)
            obj.S=S;    
        end
        if exist('P','var') && ~isempty(P)
            obj.P=P;
        end
        if ~iscell(PctrRC)
            obj.PctrRC=cell(1,2);
            obj.PctrRC{K}=PctrRC;
        else
            obj.PctrRC=PctrRC;
        end
        obj.get_LorR;
        if any(isempty(obj.PctrRC))
            obj.get_CP();
        end

        if exist('binVal','var') && ~isempty(binVal)
            obj.binVal=binVal;
        end
        if exist('Val','var') && ~isempty(Val)
            obj.Val=Val;
        end
        if exist('genOpts','var') && ~isempty(db)
            obj.genOpts=genOpts;
        end
        if exist('db','var') && ~isempty(db)
            obj.db=db;
        end
        if exist('fname','var') && ~isempty(fname)
            obj.fname=fname;
        end
    end
    function obj=construct_from_struct(obj,S)
        flds=fieldnames(S);
        for i = 1:length(flds)
            fld=flds{i};
            if isprop(obj,fld)
                obj.(fld)=S.(fld);
            end
        end
    end
    function obj=get_LorR(obj)
        if obj.K==1
            obj.LorR='L';
        elseif obj.K==2
            obj.LorR='R';
        end
    end
    function obj=getCP()
        for k = 1:2
            if k==1; nk=2; elseif k==2 nk=1; end
            if ~isempty(obj.PctrRC{k})
                continue
            end
            xyz=database(obj.database,obj.I,obj.db);
            xyz.get_CPs(nk, obj.PctrRC{nk});
            obj.PctrRC{k}=xyz.BitpRC;
        end
    end
    function obj=get_db(obj)
        db=dbInfo(obj.database);
    end
    function obj=clear_db(obj);
        obj.db=[];
    end
    function obj=get_fname(obj)
        obj.fname=imapCommon.get_ptch_name_f(obj.database, obj.name, obj.k, obj.I, obj.P);
    end
    function S=srcInfo_to_struct(obj)
        S=obj2structPublic(obj);
    end

    function obj=get_genOpts(obj)
        % TODO FIX
        out=obj.get_opts('gen');
        obj.genOpts=out.genOpts;
    end
    function out=get_opts(obj,type)
        % TODO FIX
        hash=obj.hashes.(type);
        fname=get_def_info_fname_f(obj.database,type,hash);
        load(fname);
        out=imap;

    end
end
end
