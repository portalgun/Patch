classdef cosWndw
properties
    W
    Psz
    rmpDm
    dskDm
end
methods
    function W=cosWndw(PszRCT,rmpDm,dskDm,symInd)
    %function W=cos(PszRCT,rmpDm,dskDm,symInd)
    % W=cosWndw([16 16],[16 16],[0 4]);
    % W=cosWndw([16 16 16], [16 16 8], [0 0 8], 1);
    % W=cosWndw([16 16 16], [16 16 8], [0 0 8], 0);
    %
        obj.Psz=PszRCT;
        obj.rmpDm=rmpDm;
        obj.dskDm=dskDm;


        rmpR=rmpDm/2;
        dskR=dskDm/2;

        if ~exist('symInd','var') || isempty(symInd)
            symInd=0;
        end

        n=numel(PszRCT);
        if numel(symInd) & n > 1
            symInd=repmat(symInd,n,1);
        end

        G=rowVec(unique(symInd));
        WW=cell(numel(G),1);
        i=0;
        for g = G
            i=i+1;
            bInd=symInd==g;
            WW{i}=main(PszRCT(bInd),rmpR(bInd),dskR(bInd),g);
        end
        W=combine_fun(WW);
        function W=main(PszRCT,rmpR,dskR,bSym)
            n=numel(PszRCT);
            bEven=transpose(num2cell(double(mod(PszRCT,2)==0)));
            freq = 1./(2*rmpR); % cycles per pixel

            R=smpPos(1,PszRCT);
            R=cellfun(@(x,y) x+y*.5 ,R,bEven,'UniformOutput',false);
            if bSym
                GRID=cell(1,n);
                [GRID{:}]= ndgrid(R{:});
                grid = cat(n+1,GRID{:});

                % distance sphere
                R =  sqrt(sum(grid.^2,n+1));
                W=win_fun(R,min(dskR),min(rmpR),min(freq));
            else
                rmp=transpose(num2cell(rmpR));
                dsk=transpose(num2cell(dskR));
                freq=transpose(num2cell(freq));
                WW=cellfun(@win_fun,R,dsk,rmp,freq,'UniformOutput',false);
                W=combine_fun(WW);
            end
        end
        function W=combine_fun(WW)
            W=WW{1};
            for i=2:numel(WW)
                W=transpose(W*WW{i});
            end
        end
        function W=win_fun(R,dskR,rmpR,freq)
            if isvec(R)
                R=colVec(R);
            end
            W = ones(size(R));

            ind=abs(R)>dskR;
            X=freq.*( abs(R(ind)) - dskR);
            W(ind) = 0.5.*(1 + cos(2.*pi.*X));
            W(R>(dskR(1)+rmpR(1))) = 0;
        end
    end
end
end
