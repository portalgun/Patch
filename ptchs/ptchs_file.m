classdef ptchs_file < handle & ptch_link
methods
%% 1
    function obj=save(obj)
        obj.Blk=[];
        P=Obj.copy(obj);

        P.clear_ptchOpts();
        P.clear_loaded();
        P.clear_block_all();
        P.ptch=[];

        fname=P.get_fname();

        save(fname,'P');
    end
    function clear_loaded(obj)
        % XXX EXISTS ELSEWEHRE UNDER DIF NAME?
    end
    function obj=clear_ptchOpts(obj)
        obj.ptchOpts=struct();
    end
%% 2
    function fname=get_fname(obj)
        dire=obj.get_dir;
        fname=[dire '_P_'];
    end
    function dire=get_dir(obj,bLocal)
        if nargin < 2 || isempty(bLocal)
            bLocal=obj.bLocal;
        end
        if isempty(bLocal)
            bLocal=false;
        end
        dire=ptch.get_directory_p(obj.hashes.database, obj.hashes.tbl, bLocal);
    end
    function obj=load_edges(obj)

        if ~isempty(obj.hashes.bin)
            try
                obj.edges.bin=ImapCommon.get_edges_bin(obj.hashes);
            end
        end
        if ~isempty(obj.hashes.smp)
            try
                obj.edges.smp=ImapCommon.get_edges_smp(obj.hashes);
            end
        end
        % TODO CHECK IF LOG
    end
    function obj=load_counts(obj)
        if ~isempty(obj.hashes.bin)
            try
                obj.counts.bin=ImapBin.loadCounts(obj.hashes.database,obj.hashes.bin);
            end
        end
        if ~isempty(obj.hashes.smp)
            try
                obj.counts.smp=ImapSmp.loadCounts(obj.hashes.database,obj.hashes.smp);
            end
        end
    end
    function get_genOpts(obj)
        try
            obj.genOpts=ImapGen.load_genOpts(obj.hashes.database, obj.hashes.gen);
        catch
            obj.genOpts=struct();
        end
    end
end
methods(Static=true)
    function P=loadBlk(ptchAlias,blkORblkAlias,vDisp,moude,lvlInd,blocks)
        % TODO ptchAlias can be filename
        % TODO blkaslias can be file
        % TODO vDisp can be a vdisp
        if ~exist('moude','var') || isempty(moude)
            moude=1;
        end
        if ~exist('lvlInd','var') || isempty(lvlInd)
            lvlInd=1;
        end
        if ~exist('blocks','var') || isempty(blocks)
            blocks=1;
        end

        if isa(blkORblkAlias,'Blk')
            B=blkORblkAlias;
        else
            B=Blk.load(blkORblkAlias);
        end
        if ischar(lvlInd) && strcmp(lvlInd,'all')
            lvlInd=B.unique('lvlInd');
        end
        if ischar(blocks) && strcmp(blocks,'all')
            blocks=B.unique('blk');
        end
        P=ptchs.load(ptchAlias);
        if ~isempty(vDisp)
            P.apply_display(vDisp);
        end
        P.exp_init(B,moude,lvlInd,blocks);
        P.get_genOpts();
    end
    function fname=get_fname_p(database,name)
        dire=ptchs.getDir(database,name);
        fname=[dire '_P_'];
    end
    function dire=getDir(database,hash)
        if nargin == 1
            hashes=ImapCommon.alias2hashes(database);
            hash=hashes.tbl;
            database=hashes.database;
        end
        dire=ptch.get_directory_p(database,hash);
    end
    function P=load(alias,hash)
        if nargin < 3
            bJustLoad=false;
        end
        if (~exist('hash','var') || isempty(hash)) && ImapCommon.isalias(alias)
            hashes=ImapCommon.alias2hashes(alias);
            hash=hashes.tbl;
            database=hashes.database;
        else
            database=alias;
        end
        fname=ptchs.get_fname_p(database,hash);
        load([fname '.mat']);
        P.INDS=cell(size(P.fnames));

        if ~isempty(P.hashes.database)
            P.dbInfo=dbInfo(P.hashes.database);
        end
        P.dire=P.get_dir();

        P.init_parts();
        P.getFlags();
        P.get_genOpts();

        P.load_edges();
        P.load_counts();
        if ~isempty(P.addAlias)
            P.addHashes=ImapCommon.alias2hashes(P.addAlias);
        end
    end
end
end
