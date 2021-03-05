classdef ptchsViewer < handle
% TODO binVal -> edges
% TODO binVal -> edges
% TODO refresh on resize
properties
    F
    KEY
    exitflag=0
    lastMode='n'
    strDest


    bUpdate
    strL
    posL
    disp
    msg
    txt

    info
    filterInfo
    sortInfo
    optsInfo
    mapInfo


    lastDispLength=0
    lastMsgLength=0

    clim
    rmsFix
    dcFix

    sp=[];
    pos
    f
end
properties(Constant=true, Access=private)
    div=[newline '-----------------------------' newline];
end
properties(Hidden)
    Disp
    tmp=0

    STR
    OUT
end
methods
    function obj=ptchsViewer(fnameORptchs,keyDefName,Opts)
        warning('off','MATLAB:hg:AutoSoftwareOpenGL');
        close all % XXX
        obj.f=nFn;
        obj.F=ptchsFilter(fnameORptchs);

        keyOpts=struct();
        keyOpts.bPtb=0;
        if ~exist('keyDefName','var') || isempty(keyDefName)
            keyOpts.keyDefName='ptchsViewer';
        end

        obj.KEY=Key(keyOpts);

        if ~exist('Opts','var') || isempty(Opts)
            Opts=struct();
        end
        obj=obj.parseOpts(Opts);


        obj.disp='';
        obj.msg='';

        obj.bUpdate=struct();

        obj.bUpdate.cmd=1;
        obj.bUpdate.plot=1;

        obj.bUpdate.disp=1;
        obj.bUpdate.go=1;

        obj.posL=0;
        obj.strL.ex='';
        obj.strL.msg='';
        obj.strL.go='';
        obj.strL.STR='';

        ListenChar(-1);
        obj.apply_Opts();
        try
            obj.main();
        catch ME
            ListenChar(1);
            warning('on','MATLAB:hg:AutoSoftwareOpenGL');
            close all  % XXX
            rethrow(ME);
        end

    end
    function obj=parseOpts(obj,Opts)
        p=ptchsViewer.get_parseOpts();
        obj=parse(obj,Opts,p);
    end
    function obj=apply_Opts(obj)
        obj.F.ptchs.ptchOpts.rmsFix=obj.rmsFix;
        obj.F.ptchs.ptchOpts.dcFix =obj.dcFix;
    end
    function obj=main(obj)
        clc
        while true
            if obj.bUpdate.cmd
                obj.get_strs();
                obj.draw();
                obj.bUpdate.cmd=0;
            end

            obj.KEY.read();
            obj.STR=obj.KEY.STR.OUT;
            obj.OUT=obj.KEY.OUT;

            % MODE
            if ~strcmp(obj.KEY.mode, obj.lastMode)
                obj.lastMode=obj.KEY.mode();
                obj.handle_mode_change();
                obj.bUpdate.cmd=1;
            end

            % COMMANDS
            obj.msg=[obj.KEY.mode];
            if ~isempty(obj.OUT)
                %display(obj.KEY.OUT)
                obj.parse_cmd(obj.OUT);
                obj.OUT=[];
            end
            if  ~isempty(obj.STR) && ~strcmp(obj.STR, obj.strL.STR)
                obj.strL.STR=obj.STR;
                obj.bUpdate.cmd=1;
                obj.STR=[];
            end

            if obj.exitflag
                ListenChar(1);
                warning('on','MATLAB:hg:AutoSoftwareOpenGL');
                break
            end
        end
    end
%% STRS
    function obj=get_strs(obj)
        obj.bUpdate.disp=0;
        if obj.KEY.mode=='c'
            obj.get_ex_str();
            obj.strL.go='';
        elseif obj.KEY.mode=='k'
            obj.get_go_str();
            obj.strL.ex='';
        elseif ~isempty(obj.disp)
            obj.disp='';
            obj.bUpdate.disp=1;
        end
        obj.get_msg_str(); % errors ect
        obj.get_info();    % table stuff
        obj.get_sort_info();
        obj.get_filter_info();
        obj.get_opts_info();
        obj.get_map_info();

        %if ~isempty(obj.filterInfo)
        %    obj.F.filterInfo
        %    obj.filterInfo
        %    dk
        %end
    end
    function obj=get_map_info(obj);
        rms=obj.F.ptch.im.RMS;
        dc=obj.F.ptch.im.DC;

        obj.mapInfo=['RMS       '  num2strSane(rms,3,1,1) newline ...
                     'DC        '  num2strSane(dc,3,1,1)  newline ];
    end

    function obj=get_ex_str(obj)
        str=obj.KEY.STR.str;
        pos=obj.KEY.STR.pos;
        if strcmp(str,obj.strL.ex) && isequal(pos,obj.posL)
            return
        end
        obj.strL.ex=str;
        obj.posL=pos;
        b=str(1:pos-1);
        e=str(pos:end);
        str=[b '|' e];
        obj.disp=[':' str];
        obj.bUpdate.disp=1;
    end
    function obj=get_go_str(obj)
        str=obj.KEY.STR.str;
        if strcmp(str,obj.strL.go)
            return
        end
        obj.strL.go=str;
        obj.disp=[' ' str '-'];
        obj.bUpdate.disp=1;
    end
    function obj=get_msg_str(obj)
        ms=obj.F.msg;
        if iscell(ms)
            ms=ms{1};
        end
        obj.msg=[obj.KEY.mode newline ms newline];
        obj.F.msg='';
    end
    function obj=get_info(obj)
        inf=obj.F.info;
        flds=fieldnames(inf);
        vals=cell(size(flds));
        for i = 1:length(flds)
            val=inf.(flds{i});
            if iscell(val) && all(cellfun(@isnumeric,val))
                val=cell2mat(val);
            end
            vals{i}=num2strSane(val,4,1,1);
        end
        flds=['name'; flds];
        vals=[obj.F.fname; vals];

        colW=max(cellfun(@(x) size(x,2),flds))+3;
        for i = 1:length(flds)
            space=repmat(' ',1,colW-size(flds{i},2));
            flds{i}=[flds{i} space];
        end
        l=join(join([flds vals]),newline);
        obj.info=l{1};
    end
    function obj=get_filter_info(obj)
        if isempty(obj.F.filterInfo)
            obj.filterInfo='';
            return
        end

        obj.filterInfo=['Filter:' newline indent(cell2strtable(obj.F.filterInfo,2),10)];
    end
    function obj=get_sort_info(obj)
        if isempty(obj.F.sortInfo)
            obj.sortInfo='';
            return
        end
        if obj.F.sortInfo{1,2}==0
            str='Sort:';
        else
            str='SortRev:';
        end
        obj.sortInfo=[str '     ' cell2strtable(obj.F.sortInfo(:,1),2)];
    end
    function obj=get_opts_info(obj)

        fixedStr='';
        if obj.F.ptch.im.bContrastFixed
            fixedStr=[fixedStr 'RMS fixed ' newline ];
        end
        if obj.F.ptch.im.bLuminanceFixed
            fixedStr=[fixedStr 'DC fixed  ' newline ];
        end
        if ~isempty(obj.clim)
            fixedStr=[fixedStr 'Clim:     '  num2strSane(obj.clim,3,1,1)];
        end
        obj.optsInfo=fixedStr;


    end
%% DRAW
    function obj=draw(obj)
        obj.draw_txt();
        if obj.bUpdate.plot
            obj.plot();
            obj.bUpdate.plot=0;
            obj.F.bUpdate=0;
        end
    end
    function obj=draw_txt(obj)
        % BACKSTR
        l=obj.lastDispLength;
        if l <= 1
            backstr='';
        else
            backstr=repmat('\b',1,l);
        end

        %DISP & MSG
        str=obj.msg;
        if iscell(str)
            str=join(str);
            str=str{1};
        end
        str=[str obj.disp];


        str=[ ...
                 str ...
               obj.div ...
                 obj.optsInfo newline ...
                 obj.sortInfo newline...
                 obj.filterInfo newline ...
                 obj.div ...
                 obj.info newline ...
                 obj.mapInfo newline ...
            ];
        if ~isempty(obj.txt)
            str=[str newline obj.txt];
        end

        % HERE NOTE
        STR=str;
        STR=[backstr str];

        fprintf(STR);
        obj.lastDispLength=length(str);
        obj.bUpdate.disp=0;
    end
%%
    function obj=parse_cmd(obj,CMD)
        if ~iscell(CMD{1})
            CMD={CMD};
        end
        for i = 1:length(CMD)

            cmd=CMD{i};
            if strcmp(cmd{1},'run')
                obj.parse_run(cmd(2:end));
            elseif strcmp(cmd{1},'set')
                obj.parse_set(cmd(2:end));
            elseif strcmp(cmd{1},'go')
                obj.parse_go(cmd(2:end));
            end
        end
        obj.bUpdate.plot=obj.bUpdate.plot | obj.F.bUpdate;
    end
    function obj=parse_run(obj,cmd)
        obj.bUpdate.cmd=1;
        switch cmd{1}
            case ':'
                obj.parse_ex(obj.KEY.STR.OUT);
                obj.KEY.STR.OUT=[];
            case 'clear_filter'
                obj.F.rm_filter();
            case 'str'
                obj.parse_run_str(cmd(2:end));
            case 'zoom_in'
                obj.pos=obj.sp.position;
                obj.pos(3:4)=obj.pos(3:4)*1.05;
                obj.bUpdate.plot=1;
             case 'zoom_out'
                obj.pos=obj.sp.position;
                obj.pos(3:4)=obj.pos(3:4)*0.95;
                obj.bUpdate.plot=1;
            case 'r'
                obj.bUpdate.plot=1;
            otherwise
                obj.bUpdate.cmd=0;
                return
        end
    end
    function obj=parse_set(obj,cmd)
        obj.bUpdate.cmd=1;
        switch cmd{1}
            case ':'
                obj.parse_ex(obj.KEY.STR.OUT);
                obj.KEY.STR.OUT=[];
            case 'str'
                return
            otherwise
                obj.bUpdate.cmd=0;
        end
    end
    function obj=parse_go(obj,cmd)
        obj.bUpdate.cmd=1;
        switch cmd{1}
            case 'next'
                obj.F.next();
            case 'prev'
                obj.F.prev();
            case 'first'
                obj.F.first();
            case 'last'
                obj.F.last();
            case 'go'
                obj.F.go_to(str2double(obj.KEY.STR.OUT));
                obj.KEY.STR.OUT=[];
            otherwise
                obj.bUpdate.cmd=0;
        end
    end
    function obj=parse_sort(obj,fld,bRev)
        obj.F.sort(obj,fld,bRev);
    end
    function obj=parse_ex(obj,STR)
        obj.bUpdate.cmd=0;
        strs=strsplit(STR);
        i=0;
        while true
            i = i + 1;
            if i > length(strs)
                return
            end
            str=strs{i};
            l=length(strs(i:end));
            switch str
                case 'filter'
                    if l < 3; return; end

                    fld=strs{i+1};

                    val1=strs{i+2};
                    val2=[];
                    if l > 3
                        val2=strs{i+3};
                    end

                    obj.F.filter(fld,val1,val2);
                    %if ~isempty(obj.F.msg); return; end
                    if l > 3
                        i=i+3;
                    else
                        i=i+2;
                    end
                    obj.bUpdate.cmd=1;
                case 'sort'
                    if l < 2; return; end

                    fld=strs{i+1};
                    obj.F.sort(fld,0);
                    if ~isempty(obj.F.msg); return; end
                    i=i+1;
                    obj.bUpdate.cmd=1;
                case 'sortrev'
                    if l < 2; return; end
                    fld=strs{i+1};
                    obj.F.sort(fld,1);
                    if ~isempty(obj.F.msg); return; end
                    i=i+1;
                    obj.bUpdate.cmd=1;
                case 'clim'
                    if l < 2;
                        return
                    elseif isalpha(strs{i+1})
                        fld=strs{i+1};
                        obj.clim=obj.F.get_clim(fld);
                        if ~isempty(obj.F.msg); return; end
                        i=i+1;
                    elseif l > 2 & isnum(strs{i+1}) && isnum(strs{i+2})
                        obj.clim=[str2double(strs{i+1}) str2double(strs{i+2})];
                    else
                        return
                    end
                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case 'disparity'
                    if l < 2; return; end
                    if ~isnum(strs{i+1}); return; end
                    fld=str2double(strs{i+1});


                    if l > 2 & strs{i+1} == '1'
                        obj.fix_disparity(fld);
                    else
                        obj.fix_disparity(fld);
                    end

                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case 'clear_disparity'
                    if l < 2; return; end

                    if l > 1 & strs{i+1} == '1'
                        obj.unfix_disparity_all();
                    else
                        obj.unfix_disparity();
                    end
                case 'rms'
                    if l < 2; return; end
                    if ~isnum(strs{i+1}); return; end
                    obj.rmsFix=str2double(strs{i+1});

                    if l > 2 & strs{i+1} == '1'
                        obj.fix_contrast_all();
                    else
                        obj.fix_contrast();
                    end

                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case 'dc'
                    if l < 2; return; end
                    if ~isnum(strs{i+1}); return; end
                    obj.dcFix=str2double(strs{i+1});

                    if l > 2 & strs{i+1} == '1'
                        obj.fix_contrast_all();
                    else
                        obj.fix_contrast();
                    end

                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case {'clear_rms','rms_clear'}
                    if l < 1; return; end

                    obj.rmsFix=[];
                    if l > 2 & strs{i+1} == '1'
                        obj.unfix_contrast_all();
                    else
                        obj.unfix_contrast();
                    end

                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case {'clear_dc','dc_clear'}
                    if l < 1; return; end
                    obj.dcFix=[];


                    if l > 2 & strs{i+1} == '1'
                        obj.unfix_dc_all();
                    else
                        obj.unfix_dc();
                    end

                    obj.bUpdate.cmd=1;
                    obj.bUpdate.plot=1;
                case 'q'
                    obj.exitflag=1;
                    obj.bUpdate.cmd=1;
                case 'wq'
                    obj.exitflag=1;
                    obj.bUpdate.cmd=1;
            end
        end
    end
%% RMS/DC
    function obj=fix_contrast(obj)
        obj.F.ptch.im.fix_contrast_bi(obj.rmsFix,obj.dcFix);
    end
    function obj=unfix_contrast(obj)
        obj.F.ptch.im.unfix_contrast();
    end
    function obj=unfix_dc(obj)
        obj.F.ptch.im.unfix_dc();
    end
    %% ALL
    function obj=fix_contrast_all(obj)
        obj.ptchOpts.rmsFix=obj.rmsFix;
        obj.ptchOpts.dcFix=obj.dcFix;
        obj.fix_contrast();
    end
    function obj=unfix_contrst_all(obj)
        obj.rmsFix=[];
        obj.ptchOpts.rmsFix=obj.rmsFix;
        obj.unfix_contrast();
    end
    function obj=unfix_dc_all(obj)
        obj.ptchOpts.dcFix=obj.dcFix;
        obj.unfix_dc();
    end
%% DSP
    function obj=unfix_disparity_all(obj)
        obj.F.ptchs.DSP=0;
    end
    function obj=unfix_disparity(obj)
        obj.F.ptch.DSP=0;
    end
    function obj=fix_disparity_all(obj,disparity)
        if isempty(obj.Disp)
            obj.Disp=obj.get_display();
        end
        if ~obj.F.ptchs.bDSP
            trgtInfo=obj.get_trgtInfo(disparity);
            focInfo=obj.get_focInfo();
            winInfo=obj.get_winInfo();
            obj.F.ptchs.init_disp(trgtInfo,focInfo,obj.Disp,winInfo);
        else

            obj.F.ptchs.apply_disparity(disparity);

        end

        %% APPLY TO CURRENT
        obj.fix_disparity(disparity);
    end
    function obj=fix_disparity(obj,disparity)
        if isempty(obj.Disp)
            obj.Disp=obj.get_display();
        end

        if ~obj.F.ptch.bDSP
            trgtInfo=obj.get_trgtInfo(disparity);
            focInfo=obj.get_focInfo();
            winInfo=obj.get_winInfo();
            obj.F.ptch.init_disp(trgtInfo,focInfo,obj.Disp,winInfo);
        else
            obj.F.ptch.apply_disparity(disparity);
        end
    end
%% GET
    function trgtInfo=get_trgtInfo(obj,disparity)
        trgtInfo=struct();
        trgtInfo.posXYZm=[0 0 0]; % XXX
        trgtInfo.dispORwin='win';

        if ~exist('disparity','var') || isempty(disparity)
            disparity=0;
        end
        trgtInfo.trgtDsp=disparity/60;
    end
    function focInfo=get_focInfo(obj)
        focInfo=struct();
        focInfo.posXYZm=[0 0 0]; % XXX
        focInfo.dispORwin='win';
    end
    function winInfo=get_winInfo(obj)
        winInfo=struct();
        set(gca,'Units','pixels');
        pos=get(gca,'Position');
        winInfo.WHpix=pos(3:4);
        winInfo.WHpix
        winInfo.posXYZm=[0 0 obj.Disp.scrnZmm/1000];
    end
    function Disp=get_display(obj)
        Disp=DISPLAY.get_display_from_hostname();
    end
%% PLOT
    function obj=plot(obj)
        figure(obj.f)
        [obj.sp]=obj.F.ptch.plot(obj.sp, obj.clim, obj.pos);
        obj.pos=[];
        drawnow
    end
    function obj=get_titles(obj)
        % fPos
        % pidx
        % values
    end
%% OTHER
    function obj=handle_mode_change(obj)
    end
end
methods(Static)
    function p=get_parseOpts()
        p={...
           'rmsFix',[],'isallnum1' ...
          ;'dcFix' ,[],'isallnum1' ...
          ;'clim', [],'isallnum2' ...
          };
    end
end
end
