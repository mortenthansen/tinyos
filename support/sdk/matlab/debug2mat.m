%
% Copyright (c) 2010 Aarhus University
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% - Redistributions of source code must retain the above copyright
%   notice, this list of conditions and the following disclaimer.
% - Redistributions in binary form must reproduce the above copyright
%   notice, this list of conditions and the following disclaimer in the
%   documentation and/or other materials provided with the
%   distribution.
% - Neither the name of Aarhus University nor the names of
%   its contributors may be used to endorse or promote products derived
%   from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
% FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL AARHUS
% UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
% STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
% OF THE POSSIBILITY OF SUCH DAMAGE.
%

function debug2mat(path)

if isdir(path)
    files = ls(sprintf('%s/*.log',path));
    [temp s_files] = size(strfind(files,'.log'));

    for i=1:s_files
        [logfile files] = strtok(files); 
        log2mat(logfile)
    end
else
    log2mat(path)
end

function log2mat(filename)

    verbose = 0;

    tic

    disp(sprintf('Loading file %s...', filename))

    [fid, message]=fopen(filename,'r');
    file = textscan(fid, '%s', 'delimiter',',');
    file = file{1};
    fclose(fid);

    disp('Extracting ids...')
    
    idpos = find(cellfun(@isempty, regexp(file, '^([\-.0-9E]+|0x[0-9a-f]+)$')')==1);
    ids = file(idpos);

    disp('Converting numbers...')
    
    numbers = zeros(size(file));
    
    hexpos = find(cellfun(@isempty, regexp(file, '^0x[0-9a-f]+$')')==0);
    for p=hexpos
        numbers(p) = sscanf(file{p}, '%lu', 1);
    end
    
    %doublepos = find(cellfun(@isempty, regexp(file, '^[\-0-9]+\.[0-9]+$')')==0);
    doublepos = find(cellfun(@isempty, regexp(file, '^[\-\.0-9E]+$')')==0);
    for p=doublepos
        numbers(p) = sscanf(file{p}, '%f', 1);
    end
    
%     uintpos = find(cellfun(@isempty, regexp(file, '^[0-9]+$')')==0);
%     for p=uintpos
%         temp = textscan(file{p}, '%u64', 1);
%         numbers(p) = temp{1};
%     end
    
    disp('Setting up nodes...')
    
    timestamps = numbers(idpos-3);
    H5ML.sizeof(timestamps(1));

    sources = numbers(idpos-2);
	seqnos = numbers(idpos-1);

    % same argslength is used for all log messages
    argslength = max([diff(idpos)-4 (length(file)-idpos(end))]);
    
    nodeids = unique(sources);
    uids = unique(ids);
    max_index = length(nodeids);
    index_to_nodeid = zeros(max(nodeids)+1,1);
    
    nodes(max_index).id = nodeids(end);
    for u=1:length(uids)
        nodes(max_index).(uids{u}) = [];
    end
    for n=1:max_index
        nodes(n).id = nodeids(n);
        nodeid_to_index(nodeids(n)+1) = n;
    end

    disp('Adding logs...')
  
    len = length(idpos);
    for i=1:len
        if verbose && mod(i,round(len/10))==0
            disp(sprintf('%d%%',round(100*i/len)))
        end
        
        if i==len
            args = numbers(idpos(i)+1:end);
        else
            args = numbers(idpos(i)+1:idpos(i+1)-4);
        end
    
        rec = [timestamps(i) args' zeros(1,argslength-length(args))];
        
        index = nodeid_to_index(sources(i)+1);
        nodes(index).(ids{i}) = [nodes(index).(ids{i}); rec];
    end

    name = filename(1:findstr(filename,'.')-1);   
		disp(sprintf('Saving "nodes" to file %s...', strcat(name,'.mat')))

    save(strcat(name,'.mat'), 'nodes')

    toc
