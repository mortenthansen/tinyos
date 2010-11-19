function stats_graph(data, id, runs)

names = fields(data);
names = sortrows(names);

% events, energy, and propabilities
events = zeros(runs,9);
energy = zeros(runs, 3);
propabilities = zeros(runs, 2);

%% Get events, energy and propability info from node

for n=1:length(names)
    nodes = data.(char(names(n)));
    node = get_node(nodes, id);
    
    [s e ext mat tok nam] = regexp(char(names(n)),'threshold(?<threshold>[0-9]*|VAR)_run(?<run>[0-9])*');
    threshold = nam.threshold;
    run = str2double(nam.run);
    
    if ~strcmp(threshold,'VAR')
        continue
    end
    
    [events(run, 1) tmp] = size(node.MoteStats__IDLE);
    [events(run, 2) tmp] = size(node.MoteStats__RECEIVE);
    [events(run, 3) tmp] = size(node.MoteStats__TRANSMIT);
    if isfield(node, 'MoteStats__PENDING_ADD')
        [events(run, 4) tmp] = size(node.MoteStats__PENDING_ADD);
    end
    if isfield(node, 'MoteStats__PENDING_CONCAT')
        [events(run, 5) tmp] = size(node.MoteStats__PENDING_CONCAT);
    end
    if isfield(node, 'MoteStats__TRANSMIT_TRANSFER')
        [events(run, 6) tmp] = size(node.MoteStats__TRANSMIT_TRANSFER);
    end
    if isfield(node, 'MoteStats__TRANSMIT_OVERLAP_NOFREE')
        [events(run, 7) tmp] = size(node.MoteStats__TRANSMIT_OVERLAP_NOFREE);
    end
    if isfield(node, 'MoteStats__TRANSMIT_OVERLAP_FREE')
        [events(run, 8) tmp] = size(node.MoteStats__TRANSMIT_OVERLAP_FREE);
    end
    if isfield(node, 'MoteStats__CANCEL')
        [events(run, 9) tmp] = size(node.MoteStats__CANCEL);
    end
    
%     mean(node.MoteStats__TRANSMIT(:,3))
%     mean(node.MoteStats__TRANSMIT_OVERLAP_NOFREE(:,3))
%     
%     dsa
    
    energy(run, :) = [mean(node.Selective__MOTESTATS(:,4)) mean(node.Selective__MOTESTATS(:,5)) mean(node.Selective__MOTESTATS(:,6))];
    propabilities(run, :) = [mean(node.Selective__MOTESTATS(:,2)) mean(node.Selective__MOTESTATS(:,3))];
    
end

%% Create figures

figure('Name','Events')
bar(mean(events))
ylabel('Events [#]')
% Events are: IDLE, RECEIVE, TRANSMIT, ADD PENDING TRANSMIT, CONCAT TWO
% PENDING TRANSMIT, TRANSFER A TRANSMIT, TRANSMIT OVERLAP WITHOUT FREE
% RECEPTIONS, TRANSMIT OVERLAP WITH FREE RECEPTIONS.
set(gca, 'XTickLabel', {'IDLE', 'RX', 'TX', 'PN_A', 'PN_C', 'TX_TR', 'OL_NO', 'OL_FR', 'CNL'})

figure('Name','Estimates')

subplot(2,1,1)
bar(mean(energy))
ylabel('Energy [mC]')
set(gca, 'XTickLabel', {'E_I', 'E_T', 'E_R'})
title('Energy')

subplot(2,1,2)
bar(mean(propabilities))
ylabel('Propability [%]')
set(gca, 'XTickLabel', {'P_I', 'P_R'})
title('Propabilitites')

function node = get_node(nodes, id)
for n=1:length(nodes)
    if nodes(n).id==id
        node = nodes(n);
        break
    end
end