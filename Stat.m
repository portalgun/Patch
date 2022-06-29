classdef Stat < handle
properties
    Array

    fncNames
    xNames
    yNames
    xUnits
    yUnits


    N=1
    nVarg=1
    nVers
    nStat
    statSz

    mods=cell(0,1)
    vNames=cell(0,1)
end
properties(Access=private)
    parent
    vIter=0
    nIter=0
end
methods
    function obj=Stat(fncTable,nVarg,N)

        % fncTable
        %     Name,fncName,xName,xUnits,yName,yUnits
        %     obj=nan([obj.nVarg,n,m,sz]);
        %

        obj.fncNames=fncTable(:,1);
        obj.xNames=fncTable(:,2);
        obj.xUnits=fncTable(:,3);
        obj.yNames=fncTable(:,4);
        obj.yUnits=fncTable(:,5);

        obj.nStat=size(fncTable,1);
        obj.statSz=cell(obj.nStat,1);

        if exist('nVarg','var') && ~isempty(nVarg)
            obj.nVarg=nVarg;
        end
        if exist('N','var') && ~isempty(N)
            obj.N=N;
        end

        %iterTable
        %
        %
        %
        % obj=nan([obj.nVarg,n,m,sz]);
        %end

        % m = stat num
        % n = version

    end

    function obj=appendV(obj,mod,k,vname,varargin)
        obj.vIter=obj.vIter+1;
        if ~exist('mod','var')
            mod='';
        end
        if ~exist('k','var') || isempty(k)
            k=1;
        end

        if obj.nIter == 1
            obj.nVers=size(obj.Array,2)+1;
            obj.mods{end+1,1}=mod;
            if exist('vname','var') && ~isempty(vname)
                obj.vNames{end+1,1}=vname;
            end
        end
        % TODO Checks

        for m = 1:obj.nStat
            stat=obj.eval_stat(m,k,varargin{:});
            obj.append_v(stat,m,k);
        end
    end
    function obj=next(obj,parent)
        obj.parent=parent;
        obj.nIter=obj.nIter+1;
        obj.vIter=0;
    end

    function stat=eval_stat(obj,m,varargin)
        str=[ 'obj.parent.' obj.fncNames{m} obj.mods{end} '(varargin{:});'];
        try
            stat=[eval(str)];
        catch ME
            disp(str);
            rethrow(ME);
        end
    end
    function append_v(obj,stat,m,k)
        sz=size(stat);
        if sum(sz)==0
            return
        end
        if isempty(obj.statSz{m})
            obj.statSz{m}=sz;
            obj.Array{m}=nan([1 obj.statSz{m}, obj.nVarg, obj.nVers]);
        end
        obj.Array{m}(obj.nIter,:,k,obj.vIter)=stat;
    end

    function plotDiag(obj,ind,titl)
        expectInd=1;

        if ~exist('titl','var')
            titl='';
        end
        if ~exist('ind','var')
            ind=1:numel(obj.Array);
        end

        N=numel(ind);
        sz=[N, size(obj.Array{ind})];
        V=sz(5);

        sz(expectInd)=sz(expectInd)-1;



        RC=[sz(1), sz(4)]; % fld version

        Vinds=1:V;
        Vinds(Vinds==expectInd)=[];


        xtitl=[obj.yNames{1} ' (' obj.yUnits{1} ')'];
        ytitl=[obj.yNames{1} ' (' obj.yUnits{1} ')'];
        rtitl=obj.fncNames{1};
        if isempty(obj.vNames)
            ctitl=obj.mods;
        else
            ctitl=obj.vNames;
        end

        Opts=struct();
        Opts.xlimRCBN='N';
        Opts.ylimRCBN='N';

        sp=SubPlots([N,V-1],xtitl,ytitl,titl,rtitl,ctitl,Opts);


        % 1 Orig
        % 2 center x
        % 3 scale x
        % 4 sheer
        % 5 correct
        % 6 shrink
        for i = 1:N

            statExpect=[obj.Array{i}(:,:,:,expectInd)];
            statExpect=statExpect(:);

            for j = 1:numel(Vinds)
                J=Vinds(j);
                statIter=[obj.Array{i}(:,:,:,J)];
                statIter=statIter(:);

                sp.select(i,j);
                plot(statIter,statExpect,'.k');


            end
            %Fig.format('Src (arcmin)','Buff Dsp (arcmin)','Dispairty Contrast');
        end
        sp.c();
    end

end
end
