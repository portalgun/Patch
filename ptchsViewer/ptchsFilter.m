classdef ptchsFilter < handle
properties
    ptchs

    selName
    selIdx
    selVal

    flags

    filPos=1
    filIdx
    nfil

    pidx
    msg
    bUpdate
    exitflag

    fname
    info
    filterInfo
    sortInfo

    clim
    clims
end
methods
    function obj=ptchsFilter(fnameORptchs)
        if ischar(fnameORptchs)
            load(fnameORptchs);
            obj.ptchs=ptchs;
        elseif isa(fnameORptchs,'ptchs')
            obj.ptchs=fnameORptchs;
        end
        %obj.ptchs.fnames
        obj.nfil=numel(obj.ptchs.fnames);
        obj.filIdx=1:obj.nfil;
        obj.rm_filter();
        obj.get_ptch(1);
        obj.get_cur_info();
        obj.get_clims();
    end
    function obj=get_clims(obj)
        obj.clims=struct();
        flds=fieldnames(obj.ptchs.idx);
        for i = 1:length(flds)
            fld=flds{i};
            f=obj.ptchs.idx.(fld);
            if iscell(f) && all(cellfun(@isnumeric,f))
                f=cell2mat(f);
            end
            if ~isnumeric(f)
                return
            else
                obj.clims.(fld)=minMax(f);
            end
        end

    end
    function clim=get_clim(obj,fld)
        clim=[];
        if ~isfield(obj.ptchs.idx,fld)
            obj.msg={['Error: Not valid field - ' fld]};
            return
        end
        clim=obj.clims.(fld);
    end
%% FILTER
    function obj=sort(obj,fld,bRev)
        if ~exist('bRev','var') || isempty(bRev)
            bRev=0;
        end
        if bRev
            direct='descend';
        else
            direct='ascend';
        end

        pidx=obj.filIdx(obj.filPos);
        if ~isfield(obj.ptchs.idx,fld)
            obj.msg={['Error: Not valid field - ' fld]};
            return
        end

        f=obj.ptchs.idx.(fld);
        if iscell(f) && all(cellfun(@isnumeric,f))
            f=cell2mat(f);
        end

        [~,idx]=sort(f(obj.filIdx), direct);
        obj.filIdx=obj.filIdx(idx);

        % update cur pos
        obj.filPos=find(obj.filIdx==pidx);

        obj.go_to(obj.filPos,1);
        obj.sortInfo={fld,bRev};
    end
    function obj=filter(obj,fld,val,val2)
        pidx=obj.filIdx(obj.filPos);
        switch fld
           case {'bin','b','Bin','BIN',}
               fld='B';
        end
        if ~isfield(obj.ptchs.idx,fld)
            obj.msg={'Error: Not valid field'};
            return
        end
        if isempty(val2)
            val2='';
        end

        infoN={fld,val,val2};
        bEmpty=0;
        if ~isempty(obj.filterInfo)
            infoS=joinSane(obj.filterInfo);
        else
            bEmpty=1;
            infoS='';
        end
        if ~isempty(infoN)
            infoNS=joinSane(infoN);
        else
            bEmpty=1;
            infoNS='';
        end
        if ~bEmpty && contains(infoS,infoNS)
            return
        end

        if exist('val2','var') || isempty(val2)
            filIdx=obj.filter_single(fld,val);
        else
            filIdx=obj.filter_minmax(fld,valval2);
        end

        if isempty(filIdx)
            obj.msg={'Error: filter returned no results'};
            obj.exitflag=1;
            return
        else
            obj.filIdx=filIdx;
        end

        obj.nfil=numel(obj.filIdx);

        % update cur pos
        obj.filPos=find(obj.filIdx==pidx);
        if isempty(obj.filPos)
            obj.filPos=1;
        end


        obj.go_to(obj.filPos,1);
        obj.filterInfo=[obj.filterInfo; infoN];
        obj.sortInfo=[];
    end

    function filIdx=filter_single(obj,fld,val)
        pidx=obj.filIdx(obj.filPos);
        f=obj.ptchs.idx.(fld);


        if iscell(f) && all(cellfun(@isnumeric,f))
            f=cell2mat(f);
        end
        if isnumeric(f) && isnum(val)
            val=str2double(val);
        end

        % GET NEAREST
        if ~ismember(val,f)
            k=f-val;
            val=sign(k)*min(f-val);
        end

        % GET ALL INDECES
        if numel(val) == 1
            filIdx=find(f==val);
        else
            filIdx=find(ismember(f,val));
        end

    end
    function filIdx=filter_minmax(obj,fld,val,val2)
        f=obj.ptchs.idx.(fld);

        filIdx=find(fld >= val & fld <= val2);

    end
    function obj=reset_msg(obj)
        obj.msg=[];
    end
    function obj=rm_filter(obj)
        pidx=obj.filIdx(obj.filPos);
        obj.nfil=numel(obj.ptchs.fnames);
        obj.filIdx=1:obj.nfil;
        obj.filPos=find(obj.filIdx==pidx);
        obj.go_to(obj.filPos);
        obj.filterInfo={};
        obj.sortInfo={};
    end
%% UPDATE
    function obj=go_to(obj,ind,bForce)
        if ~exist('bForce','var') || isempty(bForce)
            bForce=0;
        end

        obj.bUpdate=0;
        if ~bForce & (ind > obj.nfil || ind < 1 || isequal(obj.filPos,ind))
            return
        else
            obj.filPos=ind;
            obj.bUpdate=1;
        end

        pidx=obj.filIdx(obj.filPos);
        obj.get_ptch(pidx);
        obj.get_cur_info();
        assignin('base','info',obj.info);
    end
    function obj=get_cur_info(obj)
        pidx=obj.filIdx(obj.filPos);
        obj.info=structIndSelect(obj.ptchs.idx,size(obj.ptchs.fnames,1),pidx);
        obj.fname=obj.ptchs.fnames{pidx};

        % GET OTHER EDGE
        [vals]=unique(obj.ptchs.idx.binVal);
        inds=find(vals==obj.info.binVal)+1;
        if any(inds > size(vals,1))
            return
        end
        val2=vals(inds);
        obj.info.binVal(2)=val2;
    end
    function obj=get_ptch(obj,pidx)
        obj.pidx=pidx;
        obj.ptchs.ptch=obj.ptchs.get_patch(pidx);
    end
%%
    function obj=next(obj)
        obj.go_to(obj.filPos+1);
    end
    function obj=prev(obj)
        obj.go_to(obj.filPos-1);
    end
    function obj=first(obj)
        obj.go_to(1);
    end
    function obj=last(obj)
        obj.go_to(0);
    end
%% PLOT
end
end
