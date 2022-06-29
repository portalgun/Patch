function ptchSync(direct,remote);
    % NOTE ONLY PUSH
    % PATCHES
    % BLK
    % ALIAS FILE

    % XXX RUN BLK & EXP GEN CODE FIRST

    if ~strcmp(direct,'push')
        error('Only push is allowed')
    end

    pAaliaslias=getenv('PATCH_ALIAS');
    bAlias=getenv('BLK_ALIAS');
    %iAlias=getenv('IMAP_ALIAS');
    %
    pDir=ptchs.getDir(pAlias);
    bDir=Blk.getDir(bAlias);
    iFil=ImapDbDb.get_alias_fname();

    if strcmp(direct,'push')
        data=Env.var('DATA');
        eDir=[Data '_EXP/'];
    end

    if strcmp(direct,'push')
        upCmd=sprintf('rsync -aPu #SRC %s:#RL',remote);
        syncCmd=sprintf('rsync -aP #SRC %s:#RL',remote);
        delSyncCmd=sprintf('rsync -aP --delete #SRC %s:#RL',remote);
    elseif strcmp(direct,'pull')
        upCmd=sprintf('rsync -aPu %s:#RL #SRC',remote);
        delSyncCmd=sprintf('rsync -a) --delete %s:RL #SRC',remote);
        syncCmd=sprintf('rsync -aP %s:RL #SRC',remote);
    end

    list={'#!/bin/bash'};
    if Dir.exist(pDir)
        rtmp=delSyncCmd;
        rtmp=strrep(rtmp,'#RL',pDir);
        rtmp=strrep(rtmp,'#SRC',pDir);
        list{end+1,1}=rtmp;
    end
    if Dir.exist(bDir)
        rtmp=delSyncCmd;
        rtmp=strrep(rtmp,'#RL',bDir);
        rtmp=strrep(rtmp,'#SRC',bDir);
        list{end+1,1}=rtmp;
    end
    if Fil.exist(iFil)
        rtmp=upCmd;
        rtmp=strrep(rtmp,'#RL',iFil);
        rtmp=strrep(rtmp,'#SRC',iFil);
        list{end+1,1}=rtmp;
    end
    if Dir.exist(eDir) && strcmp(direct,'push')
        rtmp=syncCmd;
        rtmp=strrep(rtmp,'#RL',eDir);
        rtmp=strrep(rtmp,'#SRC',eDir);
        list{end+1,1}=rtmp;
    end

    [name,cl]=Fil.mktmp('.sh',list);
    unix(['chmod +x ' name]);
    Sys.term(name);

end

